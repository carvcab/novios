import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/local_storage.dart';
import '../../services/theme_provider.dart';
import '../../services/audio_service.dart';
import '../../services/ai_service.dart';
import '../../services/local_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/geofence_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/entrance_animation.dart';
import '../auth/add_partner_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _securityEnabled = false;
  final _pinCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  final _deepseekKeyCtrl = TextEditingController();
  final _linkCodeCtrl = TextEditingController();
  AIMode _aiMode = AIMode.deepseek;
  bool _isDownloadingModel = false;
  bool _musicEnabled = false;
  double _musicVolume = 0.5;

  DateTime? _anniversaryDate;
  DateTime? _metDate;
  DateTime? _datingDate;
  DateTime? _weddingDate;

  final List<String> _fonts = ['Inter', 'Playfair Display', 'Outfit', 'Pacifico', 'Poppins'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinCtrl.dispose(); _questionCtrl.dispose(); _answerCtrl.dispose();
    _linkCodeCtrl.dispose(); _deepseekKeyCtrl.dispose();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _securityEnabled = LocalStorage().isSecurityEnabled();
      _pinCtrl.text = LocalStorage().getPin() ?? '';
      _questionCtrl.text = LocalStorage().getSecurityQuestion() ?? '';
      _answerCtrl.text = LocalStorage().getSecurityAnswer() ?? '';

      _deepseekKeyCtrl.text = LocalStorage().getString('deepseek_api_key') ?? '';
      _aiMode = AIService().currentMode;
      _musicEnabled = AudioService().isMusicPlaying;
      _musicVolume = AudioService().volume;

      final annStr = LocalStorage().getAnniversaryDate();
      if (annStr != null) _anniversaryDate = DateTime.tryParse(annStr);
      final metStr = LocalStorage().getString('met_date');
      if (metStr != null) _metDate = DateTime.tryParse(metStr);
      final datingStr = LocalStorage().getString('dating_date');
      if (datingStr != null) _datingDate = DateTime.tryParse(datingStr);
      final weddingStr = LocalStorage().getString('wedding_date');
      if (weddingStr != null) _weddingDate = DateTime.tryParse(weddingStr);
    });
  }

  Future<void> _saveSettings() async {
    await LocalStorage().setSecurity(enabled: _securityEnabled, pin: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null, question: _questionCtrl.text.isNotEmpty ? _questionCtrl.text : null, answer: _answerCtrl.text.isNotEmpty ? _answerCtrl.text : null);
    await AIService().setMode(_aiMode);
    await AIService().saveDeepseekKey(_deepseekKeyCtrl.text.trim());
    
    final uid = LocalStorage().getUserId();
    if (uid != null) {
      await FirebaseService().updateUser(UserModel(
        id: uid,
        name: LocalStorage().getUserName() ?? '',
        partnerName: LocalStorage().getPartnerName(),
        anniversaryDate: _anniversaryDate,
        metDate: _metDate,
        datingDate: _datingDate,
        weddingDate: _weddingDate,
        mood: LocalStorage().getString('mood') ?? 'Feliz',
        moodReason: LocalStorage().getString('mood_reason') ?? '',
        emotionalWeather: LocalStorage().getString('emotional_weather') ?? 'Soleado',
        themeName: LocalStorage().getString('theme') ?? 'pink',
        customPrimaryColor: '#FF69B4',
        customSecondaryColor: '#FFC0CB',
        lovePoints: LocalStorage().getInt('love_points', defaultValue: 100),
      ));
    }

    if (_musicEnabled) {
      await AudioService().playBackgroundMusic('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
    } else {
      await AudioService().stopBackgroundMusic();
    }
    await AudioService().setVolume(_musicVolume);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuraciones guardadas correctamente")));
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Permisos de ubicación'),
          ],
        ),
        content: const Text(
          'Para compartir tu ubicación en tiempo real con tu pareja, EverUs necesita acceso a la ubicación. '
          'Si ya denegaste el permiso, por favor actívalo en los ajustes de tu teléfono seleccionando "Permitir todo el tiempo".'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Configuracion")),
      body: FadeInSection(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntranceAnimation(
              delayMs: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Mi Pareja", icon: Icons.favorite_rounded),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: UserService().hasPartner
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: primary.withValues(alpha: 0.2),
                                    child: Icon(Icons.person_rounded, color: primary, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('@${UserService().partnerUsername ?? ""}',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: theme.colorScheme.onSurface)),
                                        Text(UserService().partnerName ?? 'Sin nombre',
                                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Desvincular pareja'),
                                      content: const Text('¿Seguro que quieres desvincular a tu pareja? Podrás vincular a otra persona después.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await UserService().removePartner();
                                    if (mounted) setState(() {});
                                  }
                                },
                                icon: Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 18),
                                label: const Text('Desvincular pareja', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_add_rounded, color: primary, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('Aún no has agregado a tu pareja',
                                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPartnerScreen()));
                                  },
                                  icon: const Icon(Icons.search_rounded, size: 18),
                                  label: const Text('Buscar y agregar pareja'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EntranceAnimation(
              delayMs: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Personalizacion", icon: Icons.palette_outlined),
                  GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Modo oscuro"),
                      value: themeProvider.isDark,
                      onChanged: (val) => themeProvider.setDark(val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: themeProvider.fontFamily,
                      decoration: const InputDecoration(labelText: "Fuente / Tipografia"),
                      items: _fonts.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) { if (val != null) themeProvider.setFont(val); },
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EntranceAnimation(
              delayMs: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Fechas Importantes", icon: Icons.calendar_month_rounded),
                  GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _DatePickerTile(
                      icon: Icons.favorite_rounded,
                      label: 'Aniversario de novios',
                      subtitle: 'Cuando se hicieron novios',
                      date: _anniversaryDate,
                      color: primary,
                      onPick: () => _pickDate('anniversary'),
                    ),
                    const Divider(height: 24),
                    _DatePickerTile(
                      icon: Icons.people_rounded,
                      label: 'Dia que nos conocimos',
                      subtitle: 'El dia que se conocieron',
                      date: _metDate,
                      color: const Color(0xFF7C83FF),
                      onPick: () => _pickDate('met'),
                    ),
                    const Divider(height: 24),
                    _DatePickerTile(
                      icon: Icons.coffee_rounded,
                      label: 'Primera cita',
                      subtitle: 'Su primera cita juntos',
                      date: _datingDate,
                      color: const Color(0xFFFFB74D),
                      onPick: () => _pickDate('dating'),
                    ),
                    const Divider(height: 24),
                    _DatePickerTile(
                      icon: Icons.wc_rounded,
                      label: 'Boda',
                      subtitle: 'Cuando se casaron',
                      date: _weddingDate,
                      color: const Color(0xFF66BB6A),
                      onPick: () => _pickDate('wedding'),
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EntranceAnimation(
              delayMs: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Ubicacion en Vivo", icon: Icons.location_on_rounded),
                  GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Compartir ubicacion en tiempo real"),
                      subtitle: const Text("Tu pareja podra ver donde estas como en Life360"),
                      value: GeofenceService().isMonitoring,
                      onChanged: (val) async {
                        if (val) {
                          final success = await GeofenceService().startMonitoring(userInitiated: true);
                          if (!success && mounted) {
                            _showLocationPermissionDialog();
                          }
                        } else {
                          GeofenceService().stopMonitoring();
                        }
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16,
                          color: GeofenceService().isMonitoring ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          GeofenceService().isMonitoring ? 'Compartiendo ubicacion' : 'Ubicacion no compartida',
                          style: TextStyle(
                            fontSize: 13,
                            color: GeofenceService().isMonitoring ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Alertas al entrar/salir de zonas', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.history_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text('Historial de ubicacion 24h', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    if (GeofenceService().isMonitoring) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => GeofenceService().sendHeadingHome(),
                            icon: const Icon(Icons.home_rounded, size: 16),
                            label: const Text("Voy a casa", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => GeofenceService().sendArrivalAlert(),
                            icon: const Icon(Icons.check_circle_rounded, size: 16),
                            label: const Text("Llegue bien", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EntranceAnimation(
              delayMs: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Seguridad", icon: Icons.lock_outline_rounded),
                  GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Bloquear con PIN al abrir"),
                      value: _securityEnabled,
                      onChanged: (val) => setState(() => _securityEnabled = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_securityEnabled) ...[
                      const SizedBox(height: 10),
                      TextField(controller: _pinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: "Codigo PIN (4 digitos)")),
                      const SizedBox(height: 10),
                      TextField(controller: _questionCtrl, decoration: const InputDecoration(labelText: "Pregunta Secreta de Recuperacion")),
                      const SizedBox(height: 10),
                      TextField(controller: _answerCtrl, decoration: const InputDecoration(labelText: "Respuesta Secreta")),
                    ],
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EntranceAnimation(
              delayMs: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: "Servicios de IA", icon: Icons.psychology_rounded),
                  GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<AIMode>(
                      value: _aiMode,
                      decoration: const InputDecoration(labelText: "Motor de IA"),
                      items: const [
                        DropdownMenuItem(value: AIMode.deepseek, child: Text('DeepSeek API (Online)')),
                        DropdownMenuItem(value: AIMode.local, child: Text('DeepSeek Local (Sin Internet)')),
                      ],
                      onChanged: (val) { if (val != null) setState(() => _aiMode = val); },
                    ),
                    if (_aiMode == AIMode.deepseek) ...[
                      const SizedBox(height: 12),
                      TextField(controller: _deepseekKeyCtrl, obscureText: true, decoration: const InputDecoration(labelText: "DeepSeek API Key", helperText: "Obtén una key en platform.deepseek.com/api_keys")),
                    ],
                    if (_aiMode == AIMode.local) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
                        child: Column(children: [
                          Row(children: [
                            Icon(Icons.phone_android_rounded, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(child: Text("El modelo DeepSeek R1 1.5B se descarga una vez (~1.1 GB) y corre 100% offline en tu celular.", style: TextStyle(fontSize: 12, color: Colors.green.shade800))),
                          ]),
                          const SizedBox(height: 12),
                          if (!LocalAIService().isInitialized) ...[
                            SizedBox(width: double.infinity, child: ElevatedButton.icon(
                              onPressed: _isDownloadingModel ? null : () => _downloadModel(),
                              icon: _isDownloadingModel ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_rounded),
                              label: Text(_isDownloadingModel ? 'Descargando...' : 'Descargar Modelo Local'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            )),
                            if (_isDownloadingModel) ...[
                              const SizedBox(height: 8),
                              Text(LocalAIService().status, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                              if (LocalAIService().downloadProgress > 0) ...[
                                const SizedBox(height: 6),
                                LinearProgressIndicator(value: LocalAIService().downloadProgress, backgroundColor: Colors.green.shade100),
                                const SizedBox(height: 4),
                                Text('${(LocalAIService().downloadProgress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.green.shade700), textAlign: TextAlign.center),
                              ],
                            ],
                          ] else ...[
                            Row(children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text("Modelo instalado y listo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ]),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: OutlinedButton.icon(
                              onPressed: () async { await LocalAIService().dispose(); setState(() {}); },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              label: const Text("Eliminar modelo"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            )),
                          ],
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            EntranceAnimation(
              delayMs: 350,
              child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Guardar Todas las Configuraciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ),
            const SizedBox(height: 16),
            EntranceAnimation(
              delayMs: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: "Cuenta", icon: Icons.person_rounded),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                            ),
                            title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Volver a la pantalla de inicio de sesión', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                            onTap: () async {
                              final nav = Navigator.of(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Cerrar sesion"),
                                  content: const Text("Estas seguro de que quieres cerrar sesion?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Cerrar sesion")),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              await ProfileService().logout();
                              if (mounted) {
                                nav.popUntil((route) => route.isFirst);
                              }
                            },
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.person_rounded, color: primary, size: 22),
                            ),
                            title: const Text('Mi usuario', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('@${UserService().username ?? 'sin usuario'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
    );
  }

  void _downloadModel() async {
    setState(() => _isDownloadingModel = true);
    await LocalAIService().initialize();
    setState(() => _isDownloadingModel = false);
  }

  Future<void> _pickDate(String type) async {
    final now = DateTime.now();
    DateTime? initialDate;
    if (type == 'anniversary') {
      initialDate = _anniversaryDate;
    } else if (type == 'met') {
      initialDate = _metDate;
    } else if (type == 'wedding') {
      initialDate = _weddingDate;
    } else {
      initialDate = _datingDate;
    }
    initialDate ??= now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (type == 'anniversary') {
          _anniversaryDate = picked;
        } else if (type == 'met') {
          _metDate = picked;
        } else if (type == 'wedding') {
          _weddingDate = picked;
        } else {
          _datingDate = picked;
        }
      });
      final uid = LocalStorage().getUserId();
      if (uid != null) {
        final user = UserModel(
          id: uid,
          name: LocalStorage().getUserName() ?? '',
          partnerName: LocalStorage().getPartnerName(),
          anniversaryDate: type == 'anniversary' ? picked : _anniversaryDate,
          metDate: type == 'met' ? picked : _metDate,
          datingDate: type == 'dating' ? picked : _datingDate,
          weddingDate: type == 'wedding' ? picked : _weddingDate,
          mood: LocalStorage().getString('mood') ?? 'Feliz',
          moodReason: LocalStorage().getString('mood_reason') ?? '',
          emotionalWeather: LocalStorage().getString('emotional_weather') ?? 'Soleado',
          themeName: LocalStorage().getString('theme') ?? 'pink',
          customPrimaryColor: '#FF69B4',
          customSecondaryColor: '#FFC0CB',
          lovePoints: LocalStorage().getInt('love_points', defaultValue: 100),
        );
        await FirebaseService().updateUser(user);
      } else {
        if (type == 'anniversary') {
          await LocalStorage().setString('anniversary_date', picked.toIso8601String());
        } else if (type == 'met') {
          await LocalStorage().setString('met_date', picked.toIso8601String());
        } else if (type == 'wedding') {
          await LocalStorage().setString('wedding_date', picked.toIso8601String());
        } else {
          await LocalStorage().setString('dating_date', picked.toIso8601String());
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final DateTime? date;
  final Color color;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.date,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        date != null
            ? '${date!.day}/${date!.month}/${date!.year}'
            : subtitle,
        style: TextStyle(
          fontSize: 12,
          color: date != null ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
          fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: OutlinedButton(
        onPressed: onPick,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
        ),
        child: Text(date != null ? 'Cambiar' : 'Elegir'),
      ),
    );
  }
}

