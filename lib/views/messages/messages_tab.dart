import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/storage_service.dart';
import '../../widgets/firestore_image.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  static bool isChatOpen = false;

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _disappearingMode = false;
  final List<_FloatingHeart> _hearts = [];
  final Set<String> _markedAsReadIds = {};
  final Map<String, GlobalKey> _messageKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  List<MessageModel> _cachedMessages = [];

  late Stream<List<MessageModel>> _messagesStream;
  MessageModel? _replyToMsg;

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, alignment: 0.3, duration: const Duration(milliseconds: 300));
      return;
    }

    final index = _cachedMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients || _cachedMessages.isEmpty) return;
      final itemCount = _cachedMessages.length;
      if (itemCount <= 1) return;
      final fraction = index / (itemCount - 1);
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      final minScroll = _scrollCtrl.position.minScrollExtent;
      final target = minScroll + (maxScroll - minScroll) * fraction;
      _scrollCtrl.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
        if (!mounted) return;
        final retryKey = _messageKeys[messageId];
        if (retryKey?.currentContext != null) {
          Scrollable.ensureVisible(retryKey!.currentContext!, alignment: 0.3, duration: const Duration(milliseconds: 200));
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _messagesStream = FirebaseService().streamMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String get _userId {
    final uid = LocalStorage().getUserId();
    if (uid != null && uid.isNotEmpty) return uid;
    final authUid = AuthService().userId;
    if (authUid.isNotEmpty) return authUid;
    return CoupleService().currentUid;
  }
  String? get _partnerId => LocalStorage().getString('partner_uid');

  bool _isMyMessage(String senderId) {
    if (senderId == _partnerId) return false;
    return senderId == _userId;
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final userId = _userId;
    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      text: text,
      timestamp: DateTime.now(),
      type: 'chat',
      isDisappearing: _disappearingMode,
      disappearDurationSeconds: _disappearingMode ? 15 : 0,
      replyToId: _replyToMsg?.id,
      replyToText: _replyToMsg?.text,
      replyToSenderId: _replyToMsg?.senderId,
    );
    final lowerText = text.toLowerCase();
    final isSpecial = lowerText.contains('te amo') ||
        lowerText.contains('te quiero') ||
        lowerText.contains('love') ||
        lowerText.contains('beso') ||
        lowerText.contains('lindo') ||
        lowerText.contains('linda') ||
        lowerText.contains('coraz') ||
        lowerText.contains('❤️') ||
        lowerText.contains('💖') ||
        lowerText.contains('😘');

    _msgCtrl.clear();
    setState(() => _replyToMsg = null);
    FirebaseService().sendMessage(msg);

    _spawnHearts(count: isSpecial ? 30 : 6);
  }

  void _setReply(MessageModel msg) {
    setState(() => _replyToMsg = msg);
  }

  void _cancelReply() {
    setState(() => _replyToMsg = null);
  }

  void _toggleReaction(String msgId, String emoji) {
    FirebaseService().reactToMessage(msgId, emoji);
  }

  void _spawnHearts({int count = 6}) {
    final r = Random();
    setState(() {
      for (int i = 0; i < count; i++) {
        _hearts.add(_FloatingHeart(
          id: DateTime.now().microsecondsSinceEpoch + i + r.nextInt(1000),
          x: r.nextDouble() * 280 - 140,
          size: r.nextDouble() * 16 + 10,
          opacity: r.nextDouble() * 0.4 + 0.5,
        ));
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _hearts.clear();
        });
      }
    });
  }

  bool _stoppingRecording = false;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      if (_stoppingRecording) return;
      _stoppingRecording = true;
      try {
        final stopPath = await _audioRecorder.stop().timeout(const Duration(seconds: 5));
        if (mounted) setState(() => _isRecording = false);
        _stoppingRecording = false;
        if (stopPath != null && stopPath.isNotEmpty) {
          final userId = _userId;
          final uploaded = await StorageService().uploadAudio(stopPath);
          if (!mounted) return;
          if (uploaded == null) {
            final lastErr = LocalStorage().getString('last_upload_error') ?? 'Error desconocido';
            debugPrint("[AudioRecord] upload failed: $lastErr");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $lastErr')),
              );
            }
            return;
          }
          final msg = MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: userId,
            text: 'Nota de voz',
            timestamp: DateTime.now(),
            type: 'voice',
            mediaUrl: uploaded,
            isDisappearing: _disappearingMode,
            disappearDurationSeconds: _disappearingMode ? 15 : 0,
          );
          await FirebaseService().sendMessage(msg);
        }
      } on TimeoutException {
        debugPrint("[AudioRecord] stop timed out, forcing reset");
        _stoppingRecording = false;
        if (mounted) setState(() => _isRecording = false);
      } catch (e) {
        debugPrint("[AudioRecord] Error stopping/uploading recording: $e");
        _stoppingRecording = false;
        if (mounted) setState(() => _isRecording = false);
      }
    } else {
      try {
        if (!await _audioRecorder.hasPermission()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de micrófono no concedido.')),
            );
          }
          return;
        }
        final tempDir = await getTemporaryDirectory();
        final audioPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 22050,
            bitRate: 24000,
            numChannels: 1,
          ),
          path: audioPath,
        );
        if (!mounted) return;
        setState(() => _isRecording = true);
      } catch (e) {
        debugPrint("[AudioRecord] Error starting recording: $e");
      }
    }
  }

  void _showAttachmentMenu() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: cs.primary),
              title: const Text('Enviar Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMedia('photo');
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library_rounded, color: cs.primary),
              title: const Text('Enviar Video'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMedia('video');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMedia(String mediaType) async {
    final FilePickerResult? result;
    if (mediaType == 'photo') {
      result = await FilePicker.pickFiles(type: FileType.image);
    } else {
      result = await FilePicker.pickFiles(type: FileType.video);
    }
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null || filePath.isEmpty) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Subiendo archivo...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      String? mediaUrl;
      if (mediaType == 'photo') {
        mediaUrl = await StorageService().uploadPhoto(filePath);
      } else {
        mediaUrl = await StorageService().uploadVideo(filePath);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mediaUrl != null) {
        final userId = _userId;
        final msg = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: userId,
          text: mediaType == 'photo' ? 'Foto' : 'Video',
          timestamp: DateTime.now(),
          type: mediaType,
          mediaUrl: mediaUrl,
          isDisappearing: _disappearingMode,
          disappearDurationSeconds: _disappearingMode ? 15 : 0,
        );
        await FirebaseService().sendMessage(msg);
      } else {
        final lastErr = LocalStorage().getString('last_upload_error') ?? 'El archivo es demasiado grande o no hay conexión';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $lastErr')),
        );
      }
    } catch (e) {
      debugPrint("Error sending media: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar archivo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = _userId;
    final fbAvailable = FirebaseService().isFirebaseAvailable;
    debugPrint("[MessagesTab] Firebase available: $fbAvailable | userId: $userId");

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messagesStream,
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint("[MessagesTab] Stream error: ${snap.error}");
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: cs.error.withValues(alpha: 0.6)),
                      const SizedBox(height: 8),
                      Text('Error de conexión',
                        style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
                      Text('Los mensajes se guardan localmente',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                );
              }

              final list = snap.data ?? [];
              _cachedMessages = list;

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (list.isEmpty && !snap.hasData) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text('No hay mensajes aun',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                      Text('Envia tu primer mensaje de amor',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                );
              }

              if (MessagesTab.isChatOpen && list.isNotEmpty) {
                final unread = list.where((m) => 
                  !_isMyMessage(m.senderId) && 
                  m.readTimestamp == null && 
                  !_markedAsReadIds.contains(m.id)
                ).toList();
                if (unread.isNotEmpty) {
                  for (final m in unread) {
                    _markedAsReadIds.add(m.id);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (final m in unread) {
                      FirebaseService().markMessageRead(m.id);
                    }
                  });
                }
              }

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text('No hay mensajes aun',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                      Text('Envia tu primer mensaje de amor',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final msg = list[index];
                      final isMe = _isMyMessage(msg.senderId);
                      _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                      return _ChatBubble(
                        key: _messageKeys[msg.id],
                        msg: msg,
                        isMe: isMe,
                        cs: cs,
                        onReply: () => _setReply(msg),
                        onReact: (emoji) => _toggleReaction(msg.id, emoji),
                        onTapReply: msg.replyToId != null ? () => _scrollToMessage(msg.replyToId!) : null,
                      );
                    },
                  ),
                  ..._hearts.map((h) => _HeartParticle(
                    key: ValueKey(h.id),
                    heart: h,
                    cs: cs,
                  )),
                ],
              );
            },
          ),
        ),

        if (_replyToMsg != null)
          _ReplyBar(
            msg: _replyToMsg!,
            userId: _userId,
            onCancel: _cancelReply,
            cs: cs,
          ),

        if (_disappearingMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.pink.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 14, color: Colors.pink),
                const SizedBox(width: 6),
                Text(
                  'Modo Secreto Activo: los mensajes desaparecerán en 15s al ser leídos',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.pink.shade700),
                ),
              ],
            ),
          ),

        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.04))),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['❤️', '😘', '🥺', '💖', '💑', '🔥', '🌹', '✨', '💍'].map((emoji) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () async {
                    final msg = MessageModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      senderId: userId,
                      text: emoji,
                      timestamp: DateTime.now(),
                      type: 'chat',
                      isDisappearing: _disappearingMode,
                      disappearDurationSeconds: _disappearingMode ? 15 : 0,
                    );
                    await FirebaseService().sendMessage(msg);
                    _spawnHearts(count: 25);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_disappearingMode ? Icons.timer_rounded : Icons.timer_outlined,
                  color: _disappearingMode ? Colors.pink : cs.onSurface.withValues(alpha: 0.5)),
                onPressed: () => setState(() => _disappearingMode = !_disappearingMode),
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: _isRecording ? Colors.red : cs.onSurface.withValues(alpha: 0.5)),
                onPressed: _toggleRecording,
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
                onPressed: _showAttachmentMenu,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF2EDF0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: _replyToMsg != null ? 'Escribe tu respuesta...' : 'Escribe un mensaje...',
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send_rounded, color: cs.onPrimary, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final MessageModel msg;
  final String? userId;
  final VoidCallback onCancel;
  final ColorScheme cs;

  const _ReplyBar({
    required this.msg,
    required this.userId,
    required this.onCancel,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isReplyingToMe = msg.senderId == userId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
          bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 32, color: cs.primary, margin: const EdgeInsets.only(right: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isReplyingToMe ? 'Respondiendo a ti mismo' : 'Respondiendo',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                ),
                Text(
                  msg.text.length > 60 ? '${msg.text.substring(0, 60)}...' : msg.text,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final ColorScheme cs;
  final VoidCallback onReply;
  final ValueChanged<String> onReact;
  final VoidCallback? onTapReply;

  const _ChatBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.cs,
    required this.onReply,
    required this.onReact,
    this.onTapReply,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Reacciones', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['❤️', '😘', '😂', '😮', '😢', '🔥', '💖', '👍', '👎'].map((e) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onReact(e);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.reply_rounded, color: cs.primary),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.replyToId != null && msg.replyToText != null)
                _ReplyPreview(
                  text: msg.replyToText!,
                  isFromMe: msg.replyToSenderId == LocalStorage().getUserId(),
                  cs: cs,
                  onTap: onTapReply,
                ),
              if (msg.type == 'voice' && msg.mediaUrl != null)
                _VoicePlayer(mediaUrl: msg.mediaUrl!, isMe: isMe, cs: cs)
              else if (msg.type == 'voice')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.audiotrack_rounded, size: 18, color: isMe ? cs.onPrimaryContainer : cs.onSurface),
                    const SizedBox(width: 6),
                    Text('Nota de voz', style: TextStyle(
                      color: isMe ? cs.onPrimaryContainer.withValues(alpha: 0.9) : cs.onSurface.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    )),
                  ],
                )
              else if ((msg.type == 'photo' || msg.type == 'image') && msg.mediaUrl != null)
                FirestoreImage(key: ValueKey(msg.mediaUrl!), path: msg.mediaUrl!, width: 220, height: 200, borderRadius: 12)
              else if (msg.type == 'video' && msg.mediaUrl != null)
                _VideoBubblePlayer(mediaUrl: msg.mediaUrl!, isMe: isMe, cs: cs)
              else
                Text(msg.text, style: TextStyle(
                  color: isMe ? cs.onPrimaryContainer : cs.onSurface,
                  fontSize: 15,
                  height: 1.3,
                )),
              if (msg.reactions != null && msg.reactions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: msg.reactions!.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Text(e.value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? cs.onPrimaryContainer.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    Icon(
                      msg.readTimestamp != null ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: msg.readTimestamp != null ? Colors.pinkAccent : cs.onPrimaryContainer.withValues(alpha: 0.4),
                      size: 11,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final String text;
  final bool isFromMe;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _ReplyPreview({
    required this.text,
    required this.isFromMe,
    required this.cs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          border: Border(
            left: BorderSide(color: cs.primary, width: 3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(isFromMe ? Icons.person_rounded : Icons.favorite_rounded,
                  size: 11, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  isFromMe ? 'Tú' : 'Tu pareja',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary),
                ),
                const Spacer(),
                Icon(Icons.reply_rounded, size: 11, color: cs.primary.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingHeart {
  final int id;
  final double x, size, opacity;
  _FloatingHeart({required this.id, required this.x, required this.size, required this.opacity});
}

class _HeartParticle extends StatefulWidget {
  final _FloatingHeart heart;
  final ColorScheme cs;
  const _HeartParticle({required this.heart, required this.cs, super.key});

  @override
  State<_HeartParticle> createState() => _HeartParticleState();
}

class _HeartParticleState extends State<_HeartParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim, _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _yAnim = Tween<double>(begin: 0, end: -120).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: widget.heart.opacity, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        right: 40 + widget.heart.x,
        bottom: 60 + _yAnim.value,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: Icon(Icons.favorite_rounded, color: widget.cs.primary, size: widget.heart.size),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String localPath;
  const VideoPlayerScreen({required this.localPath, super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.localPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: Colors.white70,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _VideoBubblePlayer extends StatefulWidget {
  final String mediaUrl;
  final bool isMe;
  final ColorScheme cs;

  const _VideoBubblePlayer({required this.mediaUrl, required this.isMe, required this.cs});

  @override
  State<_VideoBubblePlayer> createState() => _VideoBubblePlayerState();
}

class _VideoBubblePlayerState extends State<_VideoBubblePlayer> {
  bool _isLoading = false;
  String? _localPath;

  Future<void> _loadAndPlay(BuildContext context) async {
    if (_isLoading) return;
    if (_localPath != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(localPath: _localPath!)));
      return;
    }
    setState(() => _isLoading = true);
    final path = await StorageService().getLocalFilePath(widget.mediaUrl, 'mp4');
    setState(() => _isLoading = false);
    if (path != null) {
      _localPath = path;
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(localPath: path)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? widget.cs.onPrimaryContainer : widget.cs.onSurface;
    return GestureDetector(
      onTap: () => _loadAndPlay(context),
      child: Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: fgColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: fgColor)
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.video_library_rounded, size: 48, color: fgColor.withValues(alpha: 0.5)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  final String mediaUrl;
  final bool isMe;
  final ColorScheme cs;

  const _VoicePlayer({required this.mediaUrl, required this.isMe, required this.cs});

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Uint8List? _audioBytes;
  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;
    
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_audioBytes == null) {
        if (widget.mediaUrl.startsWith('firestore://')) {
          setState(() => _isLoading = true);
          final bytes = await StorageService().loadAudioBytes(widget.mediaUrl);
          setState(() => _isLoading = false);
          if (bytes != null) {
            _audioBytes = bytes;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al cargar audio')),
              );
            }
            return;
          }
        } else {
          final file = File(widget.mediaUrl);
          if (await file.exists()) {
            _audioBytes = await file.readAsBytes();
          } else {
            return;
          }
        }
      }
      await _player.play(BytesSource(_audioBytes!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? widget.cs.onPrimaryContainer : widget.cs.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fgColor))
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                    color: fgColor,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nota de voz',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
            Text(
              _isPlaying
                  ? '${_position.inSeconds}s / ${_duration.inSeconds}s'
                  : 'Toque para reproducir',
              style: TextStyle(
                fontSize: 10,
                color: fgColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
