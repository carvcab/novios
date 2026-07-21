import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'local_storage.dart';
import '../models/message_model.dart';
import '../views/messages/messages_tab.dart';

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _msgSubscription;
  StreamSubscription? _gameSubscription;
  StreamSubscription? _activitySubscription;
  StreamSubscription? _partnerNotifSub;
  Timer? _partnerNotifRetryTimer;
  StreamSubscription? _healthSub;
  Timer? _retryTimer;
  bool _initialized = false;
  
  final Set<String> _notifiedMessageIds = {};
  
  final Set<String> _notifiedGameIds = {};
  bool _isInitialGameSnapshot = true;

  final Set<String> _notifiedActivityIds = {};
  bool _isInitialActivitySnapshot = true;

  final Set<String> _notifiedPartnerNotifIds = {};
  int _lastPartnerNotifTime = 0;

  static bool isTesting = false;

  Future<void> init() async {
    if (_initialized || isTesting) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'chat_messages_channel',
        'Mensajes de Pareja',
        description: 'Notificaciones de mensajes recibidos de tu pareja',
        importance: Importance.max,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'everus_general_channel',
        'Actividad de la App',
        description: 'Notificaciones de actividad en EverUs',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'partner_notif_channel',
        'Notificaciones de tu Pareja',
        description: 'Alertas cuando tu pareja recibe notificaciones en su telefono',
        importance: Importance.high,
      ),
    );

    _initialized = true;
    _startListening();

    _healthSub = FirebaseService.healthStream.listen((available) {
      if (available) {
        debugPrint("[ChatNotif] Firebase restored — restarting listeners");
        _startListening();
        _startPartnerNotifListener();
      }
    });

    _retryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (FirebaseService().coupleId.isNotEmpty &&
          FirebaseService().coupleId != 'default_couple_id') {
        _retryTimer?.cancel();
        _startListening();
        _startPartnerNotifListener();
      }
    });
  }

  void restartListening() {
    _startListening();
  }

  bool _isListening = false;

  void _startListening() {
    if (!FirebaseService().isFirebaseAvailable) {
      debugPrint("[ChatNotif] Cannot start listeners: Firebase unavailable");
      return;
    }
    if (_isListening) {
      debugPrint("[ChatNotif] Already listening, skipping");
      return;
    }
    _retryTimer?.cancel();
    debugPrint("[ChatNotif] Starting all listeners");

    // 1. Message listener
    _msgSubscription?.cancel();
    _msgSubscription = FirebaseFirestore.instance
        .collection('parejas')
        .doc('pareja_001')
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      final doc = snapshot.docs.first;
      if (_notifiedMessageIds.contains(doc.id)) return;
      final data = doc.data();

      final msg = MessageModel.fromMap(data);
      _notifiedMessageIds.add(msg.id);
      if (_notifiedMessageIds.length > 100) _notifiedMessageIds.clear();

      if (msg.senderId == LocalStorage().getUserId()) return;
      if (MessagesTab.isChatOpen) return;

      _showMessageNotification(msg);
    }, onError: (err) {
      debugPrint("[ChatNotif] Messages listener error: $err");
      _isListening = false;
      _startListening();
    });

    _isListening = true;

    // 2. Games listener
    _gameSubscription?.cancel();
    _isInitialGameSnapshot = true;
    _gameSubscription = FirebaseFirestore.instance
        .collection('parejas')
        .doc('pareja_001')
        .collection('juegos')
        .snapshots()
        .listen((snapshot) {
      final userId = LocalStorage().getUserId() ?? 'local_user_id';

      if (_isInitialGameSnapshot) {
        for (final doc in snapshot.docs) {
          _notifiedGameIds.add(doc.id);
        }
        _isInitialGameSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        if (data['senderId'] == userId) continue;
        if (_notifiedGameIds.contains(change.doc.id)) continue;
        _notifiedGameIds.add(change.doc.id);

        final senderName = data['senderName'] as String? ?? data['sender'] as String? ?? 'Tu pareja';

        if (change.type == DocumentChangeType.added) {
          final type = data['type'] as String? ?? '';
          final gameType = data['gameType'] as String? ?? '';
          final status = data['status'] as String? ?? 'pending';
          if (status != 'pending') continue;

          String title = '';
          const body = 'Toca para abrir';

          if (gameType.isNotEmpty) {
            title = '🎮 $senderName te invitó a jugar';
          } else if (type.isNotEmpty) {
            final label = type == 'verdad' ? 'una verdad' : type == 'foto' ? 'un foto reto' : 'un reto';
            final icon = type == 'verdad' ? '🤔' : type == 'foto' ? '📸' : '🔥';
            title = '$icon $senderName te envió $label';
          } else {
            title = '🎲 $senderName te envió un juego';
          }

          _showSimpleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: body,
            payload: 'game_${change.doc.id}',
          );
        } else if (change.type == DocumentChangeType.modified) {
          final status = data['status'] as String? ?? '';
          if (status != 'responded') continue;
          if (data['response'] == null && (data['responsePhotoUrl'] == null || data['responsePhotoUrl'].isEmpty)) continue;

          _showSimpleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '💬 $senderName respondió a tu desafío',
            body: 'Toque para ver su respuesta',
            payload: 'game_${change.doc.id}',
          );
        }
      }
    }, onError: (err) {
      debugPrint("[ChatNotif] Games listener error: $err");
      FirebaseService.recordError(err);
    });

    // 3. App Activities listener
    _activitySubscription?.cancel();
    _isInitialActivitySnapshot = true;
    _activitySubscription = FirebaseFirestore.instance
        .collection('parejas')
        .doc('pareja_001')
        .collection('notificaciones')
        .snapshots()
        .listen((snapshot) {
      final userName = LocalStorage().getUserName() ?? 'Yo';
      
      if (_isInitialActivitySnapshot) {
        for (final doc in snapshot.docs) {
          _notifiedActivityIds.add(doc.id);
        }
        _isInitialActivitySnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          if (_notifiedActivityIds.contains(change.doc.id)) continue;
          _notifiedActivityIds.add(change.doc.id);

          final title = data['title'] as String? ?? 'Tu pareja';
          if (title == userName) continue;

          final text = data['text'] as String? ?? '';
          
          _showSimpleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: text,
            payload: 'activity_${change.doc.id}',
          );
        }
      }
    }, onError: (err) {
      debugPrint("[ChatNotif] Activities listener error: $err");
    });

    // 4. Partner notifications listener (WhatsApp, Instagram, etc.)
    _startPartnerNotifListener();
  }

  Future<void> _startPartnerNotifListener() async {
    _partnerNotifSub?.cancel();
    debugPrint("[ChatNotif] Starting partner notification listener...");

    final userId = LocalStorage().getUserId();
    if (userId == null) {
      debugPrint("[ChatNotif] Partner notif: no userId");
      return;
    }

    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userSnap.exists) {
        debugPrint("[ChatNotif] Partner notif: user doc not found");
        return;
      }
      final data = userSnap.data();
      if (data == null) return;

      String? partnerUid = data['partnerUid'] as String?;
      if (partnerUid == null || partnerUid.isEmpty || partnerUid == userId) {
        debugPrint("[ChatNotif] Partner notif: partnerUid invalido o soy yo mismo ($partnerUid == $userId)");
        final coupleId = data['coupleId'] as String? ?? FirebaseService().coupleId;
        if (coupleId.isNotEmpty && coupleId != 'default_couple_id') {
          final users = await FirebaseFirestore.instance
              .collection('users').where('coupleId', isEqualTo: coupleId).get();
          for (final u in users.docs) {
            if (u.id != userId) {
              partnerUid = u.id;
              break;
            }
          }
        }
        if (partnerUid == null || partnerUid.isEmpty || partnerUid == userId) {
          debugPrint("[ChatNotif] Partner notif: no se pudo encontrar partnerUid, reintento en 10s");
          _partnerNotifRetryTimer?.cancel();
          _partnerNotifRetryTimer = Timer(const Duration(seconds: 10), () {
            _startPartnerNotifListener();
          });
          return;
        }
      }

      _partnerNotifRetryTimer?.cancel();
      debugPrint("[ChatNotif] Partner notif: listening to partner $partnerUid (my uid: $userId)");

      if (partnerUid == userId) {
        debugPrint("[ChatNotif] ERROR: partnerUid == userId! No me escucho a mi mismo.");
        _partnerNotifRetryTimer?.cancel();
        _partnerNotifRetryTimer = Timer(const Duration(seconds: 10), () {
          _startPartnerNotifListener();
        });
        return;
      }

      _partnerNotifSub = FirebaseFirestore.instance
          .collection('usuarios').doc(partnerUid)
          .snapshots()
          .listen((snap) {
        if (!snap.exists) return;
        if (snap.id == userId) {
          debugPrint("[ChatNotif] SKIP: escuchando mi propio documento!");
          return;
        }
        final pData = snap.data();
        if (pData == null) return;

        final lastNotif = pData['lastNotification'] as Map<String, dynamic>?;
        final lastNotifTime = pData['lastNotificationTime'] as Timestamp?;

        if (lastNotif == null || lastNotifTime == null) return;

        final notifTimeMs = lastNotifTime.millisecondsSinceEpoch;
        if (_lastPartnerNotifTime == 0) {
          _lastPartnerNotifTime = notifTimeMs;
          return;
        }
        if (notifTimeMs <= _lastPartnerNotifTime) return;
        _lastPartnerNotifTime = notifTimeMs;

        final app = lastNotif['app'] as String? ?? 'App';
        final title = lastNotif['title'] as String? ?? '';
        final text = lastNotif['text'] as String? ?? '';

        final notifId = '${notifTimeMs}_${app}_${title}_$text';
        if (_notifiedPartnerNotifIds.contains(notifId)) return;
        _notifiedPartnerNotifIds.add(notifId);

        if (_notifiedPartnerNotifIds.length > 200) {
          _notifiedPartnerNotifIds.clear();
        }

        debugPrint("[ChatNotif] New partner notification: $app - $title");
        _showPartnerNotifNotification(app, title, text);
      }, onError: (err) {
        debugPrint("[ChatNotif] Partner notif listener error: $err");
      });
    } catch (e) {
      debugPrint("[ChatNotif] Partner notif setup error: $e");
    }
  }

  Future<void> _showPartnerNotifNotification(String app, String title, String text) async {
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';

    String appLabel = app;
    final a = app.toLowerCase();
    if (a.contains('whatsapp')) { appLabel = 'WhatsApp'; }
    else if (a.contains('instagram')) { appLabel = 'Instagram'; }
    else if (a.contains('tiktok')) { appLabel = 'TikTok'; }
    else if (a.contains('facebook')) { appLabel = 'Facebook'; }
    else if (a.contains('messenger')) { appLabel = 'Messenger'; }
    else if (a.contains('telegram')) { appLabel = 'Telegram'; }
    else if (a.contains('snapchat')) { appLabel = 'Snapchat'; }
    else if (a.contains('twitter') || a.contains('x.com')) { appLabel = 'Twitter'; }
    else if (a.contains('gmail') || a.contains('mail')) { appLabel = 'Correo'; }
    else if (a.contains('youtube')) { appLabel = 'YouTube'; }

    String body = title;
    if (text.isNotEmpty && text != title) {
      body = '$title - $text';
    }
    if (body.length > 120) {
      body = '${body.substring(0, 117)}...';
    }

    debugPrint("[ChatNotif] Showing notification: $partnerName - $appLabel: $body");

    final androidDetails = AndroidNotificationDetails(
      'partner_notif_channel',
      'Notificaciones de tu Pareja',
      channelDescription: 'Alertas cuando tu pareja recibe notificaciones en su telefono',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📱 $partnerName - $appLabel',
      body: body,
      notificationDetails: details,
      payload: 'partner_notif',
    );
  }

  Future<void> _showMessageNotification(MessageModel msg) async {
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';
    String previewText = msg.text;
    if (msg.type == 'voice') {
      previewText = '🎤 Nota de voz';
    } else if (msg.type == 'media') {
      previewText = '🖼️ Foto o Sticker';
    }

    final androidDetails = AndroidNotificationDetails(
      'chat_messages_channel',
      'Mensajes de Pareja',
      channelDescription: 'Notificaciones de mensajes recibidos de tu pareja',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'reply_text',
          'Responder 💬',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Escribe tu respuesta...',
            ),
          ],
          showsUserInterface: false,
        ),
        const AndroidNotificationAction('reply_love', '¡Te amo! ❤️', showsUserInterface: false),
        const AndroidNotificationAction('reply_hug', 'Abrazo 🤗', showsUserInterface: false),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      id: msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      title: '💞 $partnerName',
      body: previewText,
      notificationDetails: details,
      payload: msg.id,
    );
  }

  Future<void> _showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'everus_general_channel',
      'Actividad de la App',
      channelDescription: 'Notificaciones de actividad en EverUs',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@drawable/ic_notification',
    );
    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: id,
      title: title.startsWith('💞') ? title : '💞 $title',
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final input = response.input;

    if (actionId == 'reply_text' && input != null && input.trim().isNotEmpty) {
      final userId = LocalStorage().getUserId() ?? 'local_user_id';
      final msg = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: userId,
        text: input.trim(),
        timestamp: DateTime.now(),
        type: 'chat',
      );
      await FirebaseService().sendMessage(msg);
      return;
    }

    if (actionId != null) {
      String text = '';
      if (actionId == 'reply_love') {
        text = '¡Te amo! ❤️';
      } else if (actionId == 'reply_hug') {
        text = 'Un abrazo 🤗';
      }

      if (text.isNotEmpty) {
        final userId = LocalStorage().getUserId() ?? 'local_user_id';
        final msg = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: userId,
          text: text,
          timestamp: DateTime.now(),
          type: 'chat',
        );
        await FirebaseService().sendMessage(msg);
      }
    }
  }

  void dispose() {
    _msgSubscription?.cancel();
    _gameSubscription?.cancel();
    _activitySubscription?.cancel();
    _partnerNotifSub?.cancel();
    _partnerNotifRetryTimer?.cancel();
    _healthSub?.cancel();
    _retryTimer?.cancel();
  }
}
