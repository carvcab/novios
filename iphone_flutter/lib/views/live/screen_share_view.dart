import 'package:flutter/material.dart';
import 'sender_page.dart';
import 'receiver_page.dart';
import '../../services/firebase_service.dart';

/// Vista Principal de Transmisión de Pantalla en Vivo mediante WebRTC y Firestore.
/// Ofrece las opciones "Compartir pantalla" y "Ver pantalla" con diseño moderno.
class ScreenShareView extends StatefulWidget {
  const ScreenShareView({super.key});

  @override
  State<ScreenShareView> createState() => _ScreenShareViewState();
}

class _ScreenShareViewState extends State<ScreenShareView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = FirebaseService().coupleId;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Pantalla en Vivo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5C8A),
          labelColor: const Color(0xFFFF5C8A),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.screen_share_rounded), text: 'Compartir Pantalla'),
            Tab(icon: Icon(Icons.tv_rounded), text: 'Ver Pantalla'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Emisor (Compartir Pantalla)
          SenderPage(customRoomId: coupleId.isNotEmpty ? coupleId : null),

          // Pestaña 2: Receptor (Ver Pantalla)
          ReceiverPage(initialRoomId: coupleId.isNotEmpty ? coupleId : null),
        ],
      ),
    );
  }
}
