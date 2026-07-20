import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../models/user_model.dart';
import '../../widgets/confetti_overlay.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  int _lovePoints = 100;
  int _claimedToday = 0;
  final int _maxDailyClaim = 50;

  final _msgCtrl = TextEditingController();

  final List<Map<String, dynamic>> _gifts = [
    {
      'id': 'roses',
      'name': 'Rosas Rojas',
      'cost': 10,
      'emoji': '🌹',
      'desc': 'Un ramo de rosas frescas para alegrarle el día.',
      'gradient': const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)]),
    },
    {
      'id': 'chocolates',
      'name': 'Chocolates Belgas',
      'cost': 15,
      'emoji': '🍫',
      'desc': 'Una caja de chocolates selectos para endulzar su tarde.',
      'gradient': const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFFD54F)]),
    },
    {
      'id': 'teddy',
      'name': 'Peluche Amoroso',
      'cost': 20,
      'emoji': '🧸',
      'desc': 'Un oso de peluche gigante, suave y abrazable.',
      'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
    },
    {
      'id': 'tulips',
      'name': 'Ramo de Tulipanes',
      'cost': 25,
      'emoji': '🌷',
      'desc': 'Tulipanes hermosos y coloridos de primavera.',
      'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
    },
    {
      'id': 'ring',
      'name': 'Anillo de Promesa',
      'cost': 50,
      'emoji': '💍',
      'desc': 'Un símbolo eterno de tu amor y lealtad.',
      'gradient': const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
    },
    {
      'id': 'letter',
      'name': 'Carta de Amor',
      'cost': 5,
      'emoji': '✉️',
      'desc': 'Un mensaje digital y romántico escrito con el corazón.',
      'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
    },
    {
      'id': 'trip',
      'name': 'Viaje Virtual',
      'cost': 75,
      'emoji': '✈️',
      'desc': 'Un pase de abordar a un destino de ensueño juntos.',
      'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
    },
    {
      'id': 'dinner',
      'name': 'Cena Romántica',
      'cost': 40,
      'emoji': '🕯️',
      'desc': 'Una velada mágica de cena con velas y música suave.',
      'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
    },
    {
      'id': 'balloon',
      'name': 'Globo Corazón',
      'cost': 8,
      'emoji': '🎈',
      'desc': 'Un tierno globo metálico flotando con mucho amor.',
      'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _heartScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _heartController.reverse();
        }
      });

    _loadPointsAndClaims();
  }

  void _loadPointsAndClaims() {
    setState(() {
      _lovePoints = LocalStorage().getInt('love_points', defaultValue: 100);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastClaimDate = LocalStorage().getString('last_heart_claim_date') ?? '';
      if (lastClaimDate == todayStr) {
        _claimedToday = LocalStorage().getInt('heart_claimed_today', defaultValue: 0);
      } else {
        _claimedToday = 0;
        LocalStorage().setString('last_heart_claim_date', todayStr);
        LocalStorage().setInt('heart_claimed_today', 0);
      }
    });
  }

  void _syncPointsToFirebase(int points) async {
    final uid = LocalStorage().getUserId();
    if (uid != null) {
      try {
        await FirebaseService().updateUser(UserModel(
          id: uid,
          name: LocalStorage().getUserName() ?? '',
          mood: 'Feliz',
          moodReason: '',
          emotionalWeather: 'Soleado',
          themeName: LocalStorage().getString('theme') ?? 'pink',
          customPrimaryColor: '#FF69B4',
          customSecondaryColor: '#FFC0CB',
          lovePoints: points,
        ));
      } catch (_) {}
    }
  }

  void _onHeartTap() {
    if (_claimedToday >= _maxDailyClaim) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❤️ ¡Límite diario alcanzado! Regresa mañana para ganar más puntos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _heartController.forward(from: 0.0);

    setState(() {
      _lovePoints += 5;
      _claimedToday += 5;
    });

    LocalStorage().setInt('love_points', _lovePoints);
    LocalStorage().setInt('heart_claimed_today', _claimedToday);
    _syncPointsToFirebase(_lovePoints);
  }

  void _openSendGiftDialog(Map<String, dynamic> gift) {
    _msgCtrl.clear();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: gift['gradient'] as LinearGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        gift['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enviar ${gift['name']}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Costo: ${gift['cost']} puntos',
                          style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                gift['desc'] as String,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _msgCtrl,
                decoration: InputDecoration(
                  labelText: 'Escribe una dedicatoria (opcional)',
                  hintText: 'Ej. ¡Para endulzar tu tarde! Te amo...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.favorite_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _sendGift(gift),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirmar y Enviar 🎁', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendGift(Map<String, dynamic> gift) async {
    final cost = gift['cost'] as int;
    if (_lovePoints < cost) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No tienes suficientes puntos de amor para este regalo.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final message = _msgCtrl.text.trim();
    final coupleId = FirebaseService().coupleId;
    final myUid = LocalStorage().getUserId() ?? 'anon';
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    Navigator.pop(context);

    // Save to Firestore subcollection 'gifts'
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('gifts')
        .doc(docId)
        .set({
      'id': docId,
      'senderId': myUid,
      'senderName': myName,
      'receiverName': partnerName,
      'giftType': gift['id'],
      'giftName': gift['name'],
      'emoji': gift['emoji'],
      'cost': cost,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'unread',
    });

    setState(() {
      _lovePoints -= cost;
    });

    LocalStorage().setInt('love_points', _lovePoints);
    _syncPointsToFirebase(_lovePoints);

    await FirebaseService().sendActivityNotification(
      'te envió un regalo virtual: ${gift['emoji']} ${gift['name']} 🎁',
      'gift',
      icon: 'gift',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${gift['name']} enviado con amor a $partnerName! ❤️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openReceivedGift(Map<String, dynamic> giftDoc) {
    final docId = giftDoc['id'] as String? ?? '';
    final emoji = giftDoc['emoji'] as String? ?? '🎁';
    final name = giftDoc['giftName'] as String? ?? 'Regalo';
    final message = giftDoc['message'] as String? ?? '';
    final sender = giftDoc['senderName'] as String? ?? 'Pareja';
    final status = giftDoc['status'] as String? ?? 'unread';

    final isUnread = status == 'unread';

    showDialog(
      context: context,
      barrierDismissible: !isUnread, // No cerrar si aún no lo abren, para forzar el click
      builder: (dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;
        bool isOpened = !isUnread;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isOpened) ...[
                      Text(
                        '¡Tienes un regalo de $sender!',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Animated wrapped box icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.15),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              size: 100,
                              color: Colors.redAccent,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.heavyImpact();
                          ConfettiOverlay.of(context)?.burst();

                          // Update Firestore
                          final coupleId = FirebaseService().coupleId;
                          await FirebaseFirestore.instance
                              .collection('couples')
                              .doc(coupleId)
                              .collection('gifts')
                              .doc(docId)
                              .update({'status': 'opened'});

                          setDialogState(() {
                            isOpened = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Abrir Regalo 🎁', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      Text(
                        '¡Abriste tu regalo!',
                        style: GoogleFonts.outfit(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      if (message.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '"$message"',
                            style: GoogleFonts.caveat(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else
                        Text(
                          'Te envió un lindo detalle.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(dynamic timestamp) {
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    }
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  LinearGradient _getGradientById(String id) {
    for (final gift in _gifts) {
      if (gift['id'] == id) return gift['gradient'] as LinearGradient;
    }
    return const LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myUid = LocalStorage().getUserId() ?? 'anon';
    final coupleId = FirebaseService().coupleId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Regalos Virtuales', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Tienda', icon: Icon(Icons.storefront_rounded)),
            Tab(text: 'Ganar Puntos', icon: Icon(Icons.favorite_border_rounded)),
            Tab(text: 'Buzón', icon: Icon(Icons.mail_outline_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─────── PESTAÑA 1: TIENDA ───────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puntos de Amor Glass Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary.withValues(alpha: 0.15), cs.secondary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.1),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(Icons.favorite_rounded, color: cs.primary, size: 36),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PUNTOS DE AMOR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_lovePoints Puntos',
                              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          _tabController.animateTo(1);
                        },
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Ganar más puntos',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Elige un regalo para enviar',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _gifts.length,
                  itemBuilder: (context, index) {
                    final gift = _gifts[index];
                    final grad = gift['gradient'] as LinearGradient;
                    final cost = gift['cost'] as int;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openSendGiftDialog(gift),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.surface, cs.surfaceContainerLowest],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: grad,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    gift['emoji'] as String,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                gift['name'] as String,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                gift['desc'] as String,
                                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5), height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.favorite_rounded, size: 10, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$cost pts',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ─────── PESTAÑA 2: GANAR PUNTOS ───────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡Toca el Corazón para Ganar Puntos!',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ganas +5 puntos por cada toque.\nLímite diario: $_claimedToday / $_maxDailyClaim puntos.',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), height: 1.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Beating heart minigame
                GestureDetector(
                  onTap: _onHeartTap,
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        Icon(
                          Icons.favorite_rounded,
                          size: 100,
                          color: _claimedToday >= _maxDailyClaim ? Colors.grey : cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  '$_lovePoints puntos totales',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ],
            ),
          ),

          // ─────── PESTAÑA 3: BUZÓN ───────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('couples')
                .doc(coupleId)
                .collection('gifts')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 64, color: cs.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Tu buzón está vacío',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Comienza a enviarle detalles a tu pareja!',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              // Organizar y filtrar regalos
              final giftList = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
              giftList.sort((a, b) {
                final ta = a['timestamp'];
                final tb = b['timestamp'];
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });

              final receivedGifts = giftList.where((g) => g['senderId'] != myUid).toList();
              final sentGifts = giftList.where((g) => g['senderId'] == myUid).toList();

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
                      indicatorColor: cs.primary,
                      tabs: [
                        Tab(text: 'Recibidos (${receivedGifts.length})'),
                        Tab(text: 'Enviados (${sentGifts.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // SUBTAB: RECIBIDOS
                          receivedGifts.isEmpty
                              ? _buildEmptyBox('No has recibido regalos aún ⌛', cs)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: receivedGifts.length,
                                  itemBuilder: (context, idx) {
                                    final gift = receivedGifts[idx];
                                    final name = gift['giftName'] as String? ?? 'Regalo';
                                    final emoji = gift['emoji'] as String? ?? '🎁';
                                    final status = gift['status'] as String? ?? 'unread';
                                    final sender = gift['senderName'] as String? ?? 'Pareja';
                                    final message = gift['message'] as String? ?? '';
                                    final timestamp = gift['timestamp'];

                                    final isUnread = status == 'unread';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      color: isUnread ? cs.primaryContainer.withValues(alpha: 0.25) : null,
                                      elevation: isUnread ? 2 : 0.5,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: isUnread
                                                ? const LinearGradient(colors: [Color(0xFFFF8AAB), Color(0xFFFFB74D)])
                                                : _getGradientById(gift['giftType'] as String? ?? ''),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: isUnread
                                                ? const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22)
                                                : Text(emoji, style: const TextStyle(fontSize: 22)),
                                          ),
                                        ),
                                        title: Text(
                                          isUnread ? '¡Tienes un regalo cerrado!' : name,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isUnread ? 'Enviado por $sender • Toca para abrir' : 'De $sender • $message',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: isUnread ? 0.8 : 0.6)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDateTime(timestamp),
                                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                                            ),
                                          ],
                                        ),
                                        trailing: isUnread
                                            ? Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                                              )
                                            : const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                        onTap: () => _openReceivedGift(gift),
                                      ),
                                    );
                                  },
                                ),

                          // SUBTAB: ENVIADOS
                          sentGifts.isEmpty
                              ? _buildEmptyBox('No has enviado regalos aún ⌛', cs)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: sentGifts.length,
                                  itemBuilder: (context, idx) {
                                    final gift = sentGifts[idx];
                                    final name = gift['giftName'] as String? ?? 'Regalo';
                                    final emoji = gift['emoji'] as String? ?? '🎁';
                                    final status = gift['status'] as String? ?? 'unread';
                                    final receiver = gift['receiverName'] as String? ?? 'Pareja';
                                    final message = gift['message'] as String? ?? '';
                                    final timestamp = gift['timestamp'];

                                    final isUnread = status == 'unread';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: _getGradientById(gift['giftType'] as String? ?? ''),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Para $receiver • $message',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDateTime(timestamp),
                                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                                            ),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(
                                              isUnread ? Icons.card_giftcard_rounded : Icons.drafts_rounded,
                                              color: isUnread ? Colors.redAccent : Colors.grey,
                                              size: 16,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isUnread ? 'Entregado' : 'Abierto',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isUnread ? Colors.redAccent : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String text, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: cs.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
