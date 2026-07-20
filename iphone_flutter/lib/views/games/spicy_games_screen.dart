import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/couple_content.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/firestore_image.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/entrance_animation.dart';

class SpicyGamesScreen extends StatefulWidget {
  const SpicyGamesScreen({super.key});

  @override
  State<SpicyGamesScreen> createState() => _SpicyGamesScreenState();
}

class _SpicyGamesScreenState extends State<SpicyGamesScreen> {
  ContentLevel _level = ContentLevel.suave;
  final _ai = AIService();
  final _firebase = FirebaseService();
  int _tabIndex = 0;

  final _levels = [
    ContentLevel.suave,
    ContentLevel.picante,
    ContentLevel.extremo,
    ContentLevel.xxx,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userName = LocalStorage().getUserName() ?? 'Tú';
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PulseIcon(icon: Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 20),
            const SizedBox(width: 8),
            Text('Zona Picante', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tab selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  _tabBtn('Enviar', 0, cs),
                  _tabBtn('Recibidos', 1, cs),
                ],
              ),
            ),
          ),
          Expanded(child: _tabIndex == 0 ? _buildSendTab(cs, userName, partnerName) : _buildInboxTab(cs, partnerName)),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int idx, ColorScheme cs) {
    final sel = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? _levelInfo(_level).color : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(sel ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 14, color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ SEND TAB ═══════════════════

  Widget _buildSendTab(ColorScheme cs, String userName, String partnerName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, Colors.deepOrange],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 3)],
                  ),
                  child: const Center(child: Icon(Icons.favorite_rounded, color: Colors.white, size: 30)),
                ),
                const SizedBox(height: 10),
                Text('$userName  \u2022  $partnerName',
                    style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                Text('Envía un reto a tu pareja',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Difficulty selector ──
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _levels.map((l) {
                final sel = l == _level;
                final data = _levelInfo(l);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    selected: sel,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, size: 16, color: sel ? Colors.white : data.color),
                        const SizedBox(width: 6),
                        Text(data.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    selectedColor: data.color,
                    backgroundColor: data.color.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: sel ? Colors.white : data.color),
                    onSelected: (v) => setState(() => _level = l),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          EntranceAnimation(
            delayMs: 0,
            child: _buildGameCard(
              cs: cs, icon: Icons.face_rounded, title: 'Verdad',
              desc: 'Genera y envía una pregunta a tu pareja',
              color: _levelInfo(_level).color,
              onTap: () => _sendChallenge(context, cs, 'verdad'),
            ),
          ),
          const SizedBox(height: 12),
          EntranceAnimation(
            delayMs: 80,
            child: _buildGameCard(
              cs: cs, icon: Icons.whatshot_rounded, title: 'Reto',
              desc: 'Genera y envía un desafío a tu pareja',
              color: _levelInfo(_level).color,
              onTap: () => _sendChallenge(context, cs, 'reto'),
            ),
          ),
          const SizedBox(height: 12),
          EntranceAnimation(
            delayMs: 160,
            child: _buildGameCard(
              cs: cs, icon: Icons.camera_alt_rounded, title: 'Foto Reto',
              desc: 'Envía una foto reto a tu pareja',
              color: _levelInfo(_level).color,
              onTap: () => _sendPhotoChallenge(context, cs),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _levelInfo(_level).color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded, size: 14, color: _levelInfo(_level).color),
                  const SizedBox(width: 6),
                  Text('♾️ Envío online a su teléfono',
                      style: TextStyle(fontSize: 11, color: _levelInfo(_level).color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required ColorScheme cs, required IconData icon, required String title,
    required String desc, required Color color, required VoidCallback onTap,
  }) {
    return GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_levelInfo(_level).label.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ INBOX TAB ═══════════════════

  Widget _buildInboxTab(ColorScheme cs, String partnerName) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebase.streamGameChallenges(),
      builder: (ctx, snap) {
        final challenges = (snap.data ?? [])
            .where((c) => c.containsKey('type') && (c['type'] == 'verdad' || c['type'] == 'reto' || c['type'] == 'foto'))
            .toList();
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: cs.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
                Text('Sin desafíos aún',
                    style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 4),
                Text('Tu pareja te enviará desafíos aquí',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (ctx, i) {
            final c = challenges[i];
            final isMine = c['senderId'] == LocalStorage().getUserId();
            final isPending = c['status'] == 'pending';
            final challengeLevel = c['level'] ?? 'Suave';
            final levelColor = _levelColor(challengeLevel);

            return EntranceAnimation(
              delayMs: i * 60,
              child: GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          c['type'] == 'verdad' ? Icons.face_rounded :
                          c['type'] == 'foto' ? Icons.camera_alt_rounded : Icons.whatshot_rounded,
                          size: 18, color: levelColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMine ? 'Tú' : c['senderName'] ?? partnerName,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(challengeLevel.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: levelColor)),
                        ),
                        if (isPending)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8, height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.orangeAccent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(c['content'] ?? '',
                        style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.3)),
                    if (c['photoUrl'] != null && c['photoUrl'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FirestoreImage(path: c['photoUrl'], height: 140, width: double.infinity, borderRadius: 12),
                    ],

                    // Response
                    if (!isPending && (c['response']?.isNotEmpty == true || c['responsePhotoUrl']?.isNotEmpty == true)) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(Icons.reply_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('Respuesta:', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (c['response']?.isNotEmpty == true)
                        Text(c['response'], style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8))),
                      if (c['responsePhotoUrl']?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: FirestoreImage(path: c['responsePhotoUrl'], height: 120, width: double.infinity, borderRadius: 12),
                        ),
                    ],

                    // Respond button for incoming pending challenges
                    if (!isMine && isPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRespondDialog(context, cs, c),
                            icon: Icon(Icons.reply_rounded, size: 16, color: Colors.white),
                            label: const Text('Responder', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: levelColor,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════ SEND CHALLENGES ═══════════════════

  List<String> _getUsedChallenges() {
    final list = LocalStorage().getLocalList('used_challenges');
    return list.map((e) => (e['text'] ?? '').toString()).where((t) => t.isNotEmpty).toList();
  }

  void _markChallengeAsUsed(String text) {
    final list = _getUsedChallenges();
    if (!list.contains(text)) {
      list.add(text);
      if (list.length > 60) {
        list.removeAt(0); // Keep last 60
      }
      LocalStorage().saveLocalList('used_challenges', list.map((e) => {'text': e}).toList());
    }
  }

  Future<String> _generateWithAI(String type) async {
    final levelName = _levelInfo(_level).label;
    final used = _getUsedChallenges();
    final styles = [
      'Sé creativ@ y específic@. Máximo 2 oraciones.',
      'Hazlo divertido y sorprendente. Una oración poderosa.',
      'Sé direct@ y sin rodeos. Al grano.',
      'Ponle un toque romántico y provocativo a la vez.',
      'Sé original, que no parezca algo genérico.',
      'Hazlo intenso y memorable.',
    ];
    final style = styles[Random().nextInt(styles.length)];
    
    String prompt = type == 'verdad'
        ? 'Genera una pregunta de VERDAD para parejas nivel "$levelName" en español. $style'
        : 'Genera un RETO para parejas nivel "$levelName" en español. $style';

    if (used.isNotEmpty) {
      prompt += '\nEvita absolutamente repetir o hacer preguntas/retos parecidos a estos recientes:\n- ${used.take(20).join('\n- ')}';
    }

    final result = await _ai.ask(prompt, '');
    if (result.trim().isNotEmpty) return result.trim();
    
    final list = type == 'verdad'
        ? CoupleContent.truths[_level]!
        : CoupleContent.dares[_level]!;
    final available = list.where((item) => !used.contains(item)).toList();
    if (available.isNotEmpty) {
      return available[Random().nextInt(available.length)];
    }
    return list[Random().nextInt(list.length)];
  }

  void _sendChallenge(BuildContext context, ColorScheme cs, String type) {
    final color = _levelInfo(_level).color;
    final typeName = type == 'verdad' ? 'Verdad' : 'Reto';
    String content = 'Generando...';
    bool loading = true;
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          if (loading) {
            _generateWithAI(type).then((r) {
              if (ctx.mounted) setDState(() { content = r; loading = false; });
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(type == 'verdad' ? Icons.face_rounded : Icons.whatshot_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Text('$typeName - ${_levelInfo(_level).label}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ],
            ),
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: color),
                        const SizedBox(height: 12),
                        Text('Generando con IA...',
                            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 20, color: color),
                        const SizedBox(height: 8),
                        Text(content,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.4)),
                        if (sending) ...[
                          const SizedBox(height: 12),
                          SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                          const SizedBox(height: 4),
                          Text('Enviando...', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Cerrar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
              if (!loading && !sending) ...[
                TextButton(
                  onPressed: () { Navigator.pop(ctx); _sendChallenge(context, cs, type); },
                  child: const Text('Regenerar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    setDState(() => sending = true);
                    await _firebase.sendGameChallenge(
                      type: type, content: content, level: _levelInfo(_level).label,
                    );
                    _markChallengeAsUsed(content);
                    await _firebase.sendActivityNotification(
                      'Te envió un nuevo juego/reto: "$content" 🌶️', 'game', icon: 'game'
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$typeName enviado a tu pareja ♥'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: const Text('Enviar a pareja'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _sendPhotoChallenge(BuildContext context, ColorScheme cs) async {
    final challenges = CoupleContent.photoChallenges[_level]!;
    final used = _getUsedChallenges();
    final available = challenges.where((item) => !used.contains(item)).toList();
    final challenge = available.isNotEmpty
        ? available[Random().nextInt(available.length)]
        : challenges[Random().nextInt(challenges.length)];
    final color = _levelInfo(_level).color;
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';

    String? uploadedUrl;
    bool uploading = false;
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.camera_alt_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Foto Reto - ${_levelInfo(_level).label}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 32, color: color),
                        const SizedBox(height: 12),
                        Text(challenge, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (uploadedUrl != null && uploadedUrl!.isNotEmpty)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: NetworkImage(uploadedUrl!), fit: BoxFit.cover),
                      ),
                    )
                  else if (!uploading)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1024);
                        if (image != null && ctx.mounted) {
                          setDState(() { uploading = true; });
                          final url = await StorageService().uploadPhoto(image.path);
                          if (url != null) {
                            setDState(() { uploadedUrl = url; uploading = false; });
                          } else {
                            setDState(() { uploading = false; });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Error al subir la foto. Revisa tus reglas de Firebase Storage.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Tomar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  if (uploading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  if (sending)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Enviando a $partnerName...',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Cerrar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
              if (uploadedUrl != null && !sending)
                FilledButton.icon(
                  onPressed: () async {
                    setDState(() => sending = true);
                    await _firebase.sendGameChallenge(
                      type: 'foto', content: challenge, level: _levelInfo(_level).label, photoUrl: uploadedUrl,
                    );
                    _markChallengeAsUsed(challenge);
                    await _firebase.sendActivityNotification(
                      'Te envió un nuevo Foto Reto: "$challenge" 📸🌶️', 'game', icon: 'game'
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Foto reto enviado a $partnerName ♥'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: const Text('Enviar'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════ RESPOND ═══════════════════

  void _showRespondDialog(BuildContext context, ColorScheme cs, Map<String, dynamic> challenge) {
    final color = _levelColor(challenge['level'] ?? 'Suave');
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';
    final TextEditingController respCtrl = TextEditingController();

    String? photoUrl;
    bool uploading = false;
    bool responding = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.reply_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Text('Responder a ${challenge['senderName'] ?? partnerName}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(challenge['content'] ?? '',
                        style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.3)),
                  ),
                  if (challenge['photoUrl'] is String && (challenge['photoUrl'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    FirestoreImage(path: challenge['photoUrl'] as String, height: 100, width: double.infinity, borderRadius: 12),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: respCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tu respuesta...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  if (photoUrl != null)
                    FirestoreImage(path: photoUrl!, height: 120, width: double.infinity, borderRadius: 12)
                  else
                    OutlinedButton.icon(
                      onPressed: uploading ? null : () async {
                        final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1024);
                        if (image != null && ctx.mounted) {
                          setDState(() => uploading = true);
                          final url = await StorageService().uploadPhoto(image.path);
                          if (url != null) {
                            setDState(() { photoUrl = url; uploading = false; });
                          } else {
                            setDState(() => uploading = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Error al subir la foto. Revisa tus reglas de Firebase Storage.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: uploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_rounded),
                      label: Text(uploading ? 'Subiendo...' : 'Agregar foto'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
              FilledButton.icon(
                onPressed: (respCtrl.text.trim().isEmpty && photoUrl == null) || responding
                    ? null
                    : () async {
                        setDState(() => responding = true);
                        await _firebase.respondToChallenge(
                          challenge['id'],
                          response: respCtrl.text.trim().isNotEmpty ? respCtrl.text.trim() : null,
                          responsePhotoUrl: photoUrl,
                        );
                        final respText = respCtrl.text.trim().isNotEmpty
                            ? '"${respCtrl.text.trim()}"'
                            : 'una foto';
                        await _firebase.sendActivityNotification(
                          'Respondió al reto/verdad con: $respText 🌶️💌', 'game', icon: 'game'
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Respuesta enviada ♥'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text('Enviar respuesta'),
                style: FilledButton.styleFrom(backgroundColor: color),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────── HELPERS ─────────────

  Color _levelColor(String label) {
    for (final l in _levels) {
      if (_levelInfo(l).label == label) return _levelInfo(l).color;
    }
    return const Color(0xFF66BB6A);
  }

  _LevelInfo _levelInfo(ContentLevel l) {
    switch (l) {
      case ContentLevel.suave:
        return _LevelInfo(Icons.sentiment_satisfied_rounded, 'Suave', const Color(0xFF66BB6A));
      case ContentLevel.picante:
        return _LevelInfo(Icons.whatshot_rounded, 'Picante', const Color(0xFFFFB74D));
      case ContentLevel.extremo:
        return _LevelInfo(Icons.local_fire_department_rounded, 'Extremo', const Color(0xFFFF5C8A));
      case ContentLevel.xxx:
        return _LevelInfo(Icons.dangerous_rounded, 'XXX', const Color(0xFFD32F2F));
    }
  }
}

class _LevelInfo {
  final IconData icon;
  final String label;
  final Color color;
  const _LevelInfo(this.icon, this.label, this.color);
}
