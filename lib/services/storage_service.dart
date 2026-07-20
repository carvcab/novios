import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'local_storage.dart';
import 'firebase_service.dart';
import 'package:image/image.dart' as img;

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _storageId {
    final cid = FirebaseService().coupleId;
    debugPrint("[Storage] coupleId = $cid");
    if (cid == 'default_couple_id' || cid.isEmpty) {
      return null;
    }
    return cid;
  }

  Future<String?> uploadPhoto(String localPath, {String? memoryId}) async {
    final sid = _storageId;
    if (sid == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final bytes = await _compressImage(file);
      final b64 = base64Encode(bytes);
      final id = memoryId ?? DateTime.now().microsecondsSinceEpoch.toString();
      await _db.collection('pairs').doc(sid).collection('photos').doc(id).set({
        'data': b64,
        'mimeType': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'firestore://pairs/$sid/photos/$id';
    } catch (e) {
      debugPrint("Error uploading photo: $e");
      return null;
    }
  }

  Future<String?> uploadAudio(String localPath, {String? messageId}) async {
    final sid = _storageId;
    if (sid == null) {
      final err = 'No storage ID (couple not set up)';
      debugPrint("[Storage] uploadAudio: $err");
      LocalStorage().setString('last_upload_error', err);
      return null;
    }
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        final err = 'File not found: $localPath';
        debugPrint("[Storage] uploadAudio: $err");
        LocalStorage().setString('last_upload_error', err);
        return null;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        final err = 'Audio file is empty';
        debugPrint("[Storage] uploadAudio: $err");
        LocalStorage().setString('last_upload_error', err);
        return null;
      }

      if (bytes.length > 750 * 1024) {
        final sizeMB = (bytes.length / 1024).toStringAsFixed(1);
        final err = 'Audio demasiado grande (${sizeMB}KB). Max: 750KB. Graba mas corto.';
        debugPrint("[Storage] uploadAudio: $err");
        LocalStorage().setString('last_upload_error', err);
        return null;
      }
      final b64 = base64Encode(bytes);
      final id = messageId ?? DateTime.now().microsecondsSinceEpoch.toString();
      await _db.collection('pairs').doc(sid).collection('audio').doc(id).set({
        'data': b64,
        'mimeType': 'audio/m4a',
        'createdAt': FieldValue.serverTimestamp(),
      });
      LocalStorage().setString('last_upload_error', '');
      return 'firestore://pairs/$sid/audio/$id';
    } catch (e) {
      final err = e.toString();
      debugPrint("[Storage] Error uploading audio: $err");
      LocalStorage().setString('last_upload_error', err);
      return null;
    }
  }

  Future<String?> uploadVideo(String localPath, {String? memoryId}) async {
    final sid = _storageId;
    if (sid == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.length > 700 * 1024) {
        debugPrint("[Storage] Video too large (${bytes.length}b), skipping");
        return null;
      }
      final b64 = base64Encode(bytes);
      final id = memoryId ?? DateTime.now().microsecondsSinceEpoch.toString();
      await _db.collection('pairs').doc(sid).collection('videos').doc(id).set({
        'data': b64,
        'mimeType': 'video/mp4',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'firestore://pairs/$sid/videos/$id';
    } catch (e) {
      debugPrint("Error uploading video: $e");
      return null;
    }
  }

  Future<String?> getLocalFilePath(String url, String extension) async {
    try {
      // Ruta local
      if (!url.startsWith('firestore://')) {
        if (await File(url).exists()) return url;
        return null;
      }

      final cleanUrl = url.split('?').first;
      final parts = cleanUrl.replaceFirst('firestore://', '').split('/');
      if (parts.length < 4) return null;

      final docId = parts[3];
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_$docId.$extension');

      if (await file.exists()) return file.path;

      final doc = await _db.collection(parts[0]).doc(parts[1]).collection(parts[2]).doc(docId).get();
      if (!doc.exists) return null;
      final b64 = doc.get('data') as String?;
      if (b64 == null) return null;
      final bytes = base64Decode(b64);
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint("Error getting local file path: $e");
      return null;
    }
  }

  Future<Uint8List?> loadAudioBytes(String url) async {
    try {
      if (!url.startsWith('firestore://')) return null;
      final parts = url.replaceFirst('firestore://', '').split('/');
      if (parts.length < 4) return null;
      final doc = await _db.collection(parts[0]).doc(parts[1]).collection(parts[2]).doc(parts[3]).get();
      if (!doc.exists) return null;
      final b64 = doc.get('data') as String?;
      if (b64 == null) return null;
      return base64Decode(b64);
    } catch (e) {
      debugPrint("Error loading audio bytes: $e");
      return null;
    }
  }

  Future<Uint8List?> loadPhoto(String firestoreUrl) async {
    try {
      if (!firestoreUrl.startsWith('firestore://')) return null;
      final parts = firestoreUrl.replaceFirst('firestore://', '').split('/');
      if (parts.length < 4) return null;
      final doc = await _db.collection(parts[0]).doc(parts[1]).collection(parts[2]).doc(parts[3]).get();
      if (!doc.exists) return null;
      final b64 = doc.get('data') as String?;
      if (b64 == null) return null;
      return base64Decode(b64);
    } catch (e) {
      debugPrint("Error loading photo: $e");
      return null;
    }
  }

  Future<void> deleteFile(String firestoreUrl) async {
    try {
      if (!firestoreUrl.startsWith('firestore://')) return;
      final parts = firestoreUrl.replaceFirst('firestore://', '').split('/');
      if (parts.length < 4) return;
      await _db.collection(parts[0]).doc(parts[1]).collection(parts[2]).doc(parts[3]).delete();
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  Future<Uint8List> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 500 * 1024) return bytes;

      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      img.Image resized = image;
      if (image.width > 1024 || image.height > 1024) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1024 : null,
          height: image.height >= image.width ? 1024 : null,
        );
      }

      final compressed = img.encodeJpg(resized, quality: 60);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint("Error compressing image: $e");
      try {
        return await file.readAsBytes();
      } catch (_) {
        return Uint8List(0);
      }
    }
  }
}
