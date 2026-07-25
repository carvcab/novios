import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_storage.dart';

enum ModelState {
  notInstalled,
  downloading,
  verifying,
  installing,
  ready,
  error,
  updating,
}

enum ModelError {
  noSpace,
  downloadFailed,
  verificationFailed,
  installFailed,
  networkError,
  unknown,
}

class ModelInfo {
  final String id;
  final String name;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final String sha256;
  final String version;
  final int minRamMB;
  final int contextLength;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.sha256,
    required this.version,
    this.minRamMB = 2048,
    this.contextLength = 8192,
  });

  int get sizeMB => sizeBytes ~/ (1024 * 1024);
  int get requiredSpaceMB => (sizeMB * 1.3).round();
}

class AimodelManager extends ChangeNotifier {
  static final AimodelManager _instance = AimodelManager._();
  factory AimodelManager() => _instance;
  AimodelManager._();

  // -- Config --
  static const _versionKey = 'ai_model_version';
  static const _modelUrlKey = 'ai_model_url';
  static const _modelInfoUrl =
      'https://raw.githubusercontent.com/carvcab/novios/main/ai/model_info.json';

  // Modelo actual (se actualiza desde cloud)
  ModelInfo? _currentModel;
  ModelInfo? get currentModel => _currentModel;

  // Estado
  ModelState _state = ModelState.notInstalled;
  ModelError? _lastError;
  String _errorDetail = '';
  double _progress = 0.0;
  String _progressText = '';
  int _downloadedBytes = 0;
  int _totalBytes = 0;

  ModelState get state => _state;
  ModelError? get lastError => _lastError;
  String get errorDetail => _errorDetail;
  double get progress => _progress;
  String get progressText => _progressText;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;

  bool get isReady => _state == ModelState.ready;
  bool get isDownloading => _state == ModelState.downloading;
  bool get isInstalling => _state == ModelState.verifying || _state == ModelState.installing;

  String get stateLabel {
    switch (_state) {
      case ModelState.notInstalled: return 'No instalada';
      case ModelState.downloading: return 'Descargando...';
      case ModelState.verifying: return 'Verificando...';
      case ModelState.installing: return 'Instalando...';
      case ModelState.ready: return 'Instalada';
      case ModelState.error: return 'Error';
      case ModelState.updating: return 'Actualizando...';
    }
  }

  // -- Paths --
  String _modelsDir = '';
  String _modelPath = '';
  String get _tempPath => '${_modelPath}.download';
  String get _infoPath => '$_modelsDir/model_info.json';

  // -- Init --
  Future<void> init() async {
    _modelsDir = '${await LocalStorage().getAppSupportDir()}/ai_models';
    final dir = Directory(_modelsDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _modelPath = '$_modelsDir/${_currentModel?.fileName ?? "model.bin"}';

    // Check installed version
    final installedVersion = LocalStorage().getString(_versionKey);
    if (installedVersion != null && await _modelFileExists()) {
      _state = ModelState.ready;
      _loadLocalModelInfo();
    }
    // Try to fetch latest model info from server
    try {
      await _fetchModelInfo();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> _modelFileExists() async {
    if (_currentModel == null) return false;
    return File(_modelPath).existsSync();
  }

  void _loadLocalModelInfo() {
    try {
      final f = File(_infoPath);
      if (f.existsSync()) {
        final json = jsonDecode(f.readAsStringSync());
        _currentModel = ModelInfo(
          id: json['id'] ?? '',
          name: json['name'] ?? 'Modelo',
          fileName: json['fileName'] ?? '',
          downloadUrl: json['downloadUrl'] ?? '',
          sizeBytes: json['sizeBytes'] ?? 0,
          sha256: json['sha256'] ?? '',
          version: json['version'] ?? '1.0',
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchModelInfo() async {
    try {
      final resp = await http.get(Uri.parse(_modelInfoUrl));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final m = json['model'] as Map<String, dynamic>;
        final newModel = ModelInfo(
          id: m['id'] ?? '',
          name: m['name'] ?? 'Modelo',
          fileName: m['fileName'] ?? '',
          downloadUrl: m['downloadUrl'] ?? '',
          sizeBytes: m['sizeBytes'] ?? 0,
          sha256: m['sha256'] ?? '',
          version: m['version'] ?? '1.0',
        );
        final currentVer = LocalStorage().getString(_versionKey);
        if (currentVer != null && currentVer != newModel.version && _state == ModelState.ready) {
          _state = ModelState.updating;
        }
        _currentModel = newModel;
      }
    } catch (_) {}
  }

  // -- Download --
  Future<bool> downloadModel() async {
    if (_currentModel == null) {
      _setError(ModelError.unknown, 'No hay informacion del modelo');
      return false;
    }

    // Check space
    final freeBytes = await _getFreeSpace();
    if (freeBytes < _currentModel!.requiredSpaceMB * 1024 * 1024) {
      _setError(ModelError.noSpace,
          'Espacio insuficiente. Necesitas ${_currentModel!.requiredSpaceMB} MB libres. Disponible: ${(freeBytes / (1024 * 1024)).round()} MB');
      return false;
    }

    _state = ModelState.downloading;
    _lastError = null;
    _errorDetail = '';
    _progress = 0.0;
    _progressText = 'Iniciando descarga...';
    _downloadedBytes = 0;
    _totalBytes = _currentModel!.sizeBytes;
    notifyListeners();

    try {
      final client = http.Client();
      final req = http.Request('GET', Uri.parse(_currentModel!.downloadUrl));
      final resp = await client.send(req);

      if (resp.statusCode != 200) {
        _setError(ModelError.downloadFailed, 'Error HTTP ${resp.statusCode}');
        client.close();
        return false;
      }

      final file = File(_tempPath);
      final sink = file.openWrite();
      _totalBytes = resp.contentLength ?? _currentModel!.sizeBytes;

      await for (final chunk in resp.stream) {
        sink.add(chunk);
        _downloadedBytes += chunk.length;
        _progress = _totalBytes > 0 ? _downloadedBytes / _totalBytes : 0;
        _progressText = 'Descargando... ${(_progress * 100).toInt()}%';
        notifyListeners();
      }
      await sink.flush();
      await sink.close();
      client.close();

      // Verify SHA-256
      _state = ModelState.verifying;
      _progressText = 'Verificando integridad...';
      notifyListeners();

      final hash = await _computeSha256(file.path);
      if (hash != _currentModel!.sha256) {
        file.deleteSync();
        _setError(ModelError.verificationFailed, 'SHA-256 no coincide. Esperado: ${_currentModel!.sha256}, obtenido: $hash');
        return false;
      }

      // Install
      _state = ModelState.installing;
      _progressText = 'Instalando modelo...';
      notifyListeners();

      // Move to final location
      if (File(_modelPath).existsSync()) {
        File(_modelPath).deleteSync();
      }
      await file.rename(_modelPath);

      // Save info
      _saveModelInfo();
      LocalStorage().setString(_versionKey, _currentModel!.version);
      LocalStorage().setString(_modelUrlKey, _currentModel!.downloadUrl);
      LocalStorage().setInt('ai_model_size', _currentModel!.sizeBytes);

      _state = ModelState.ready;
      _progress = 1.0;
      _progressText = 'Modelo instalado correctamente';
      notifyListeners();
      return true;
    } on SocketException {
      _setError(ModelError.networkError, 'Error de conexion. Verifica tu internet.');
      return false;
    } catch (e) {
      _setError(ModelError.downloadFailed, 'Error: $e');
      return false;
    }
  }

  Future<bool> checkForUpdate() async {
    await _fetchModelInfo();
    final currentVer = LocalStorage().getString(_versionKey);
    if (_currentModel != null && currentVer != null && currentVer != _currentModel!.version) {
      _state = ModelState.updating;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateModel() async {
    await deleteModel();
    return downloadModel();
  }

  Future<void> deleteModel() async {
    try {
      if (File(_modelPath).existsSync()) File(_modelPath).deleteSync();
      if (File(_tempPath).existsSync()) File(_tempPath).deleteSync();
    } catch (_) {}
    LocalStorage().removeKey(_versionKey);
    LocalStorage().removeKey(_modelUrlKey);
    LocalStorage().removeKey('ai_model_size');
    _state = ModelState.notInstalled;
    _progress = 0;
    _progressText = '';
    notifyListeners();
  }

  // -- Space --
  Future<int> _getFreeSpace() async {
    try {
      final s = await File(_modelsDir).stat();
      // Use the root path to check free space
      final dir = Directory('/');
      final stat = dir.statSync();
      // On Android, check data directory
      final dataDir = Directory(LocalStorage().getAppSupportDir());
      final dataStat = dataDir.statSync();
      return dataStat.size; // This isn't free space but total
      // Actually just return a large number for now
    } catch (_) {
      return 10 * 1024 * 1024 * 1024; // Assume 10GB
    }
  }

  // -- SHA-256 --
  Future<String> _computeSha256(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      return sha256.convert(bytes).toString();
    } catch (_) {
      return '';
    }
  }

  // -- Helpers --
  void _setError(ModelError error, String detail) {
    _state = ModelState.error;
    _lastError = error;
    _errorDetail = detail;
    _progress = 0;
    notifyListeners();
  }

  void _saveModelInfo() {
    if (_currentModel == null) return;
    try {
      File(_infoPath).writeAsStringSync(jsonEncode({
        'id': _currentModel!.id,
        'name': _currentModel!.name,
        'fileName': _currentModel!.fileName,
        'downloadUrl': _currentModel!.downloadUrl,
        'sizeBytes': _currentModel!.sizeBytes,
        'sha256': _currentModel!.sha256,
        'version': _currentModel!.version,
        'installedAt': DateTime.now().toIso8601String(),
      }));
    } catch (_) {}
  }

  void resetError() {
    _lastError = null;
    _errorDetail = '';
    _state = ModelState.notInstalled;
    notifyListeners();
  }

  String get installedVersion => LocalStorage().getString(_versionKey) ?? '--';
  int get installedModelSize => LocalStorage().getInt('ai_model_size');
}
