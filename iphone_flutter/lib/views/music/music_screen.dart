import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import 'music_history_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _spotifyUrlCtrl = TextEditingController();

  final _playTitleCtrl = TextEditingController();
  final _playArtistCtrl = TextEditingController();
  final _playSpotifyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _spinCtrl.repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _spotifyUrlCtrl.dispose();
    _playTitleCtrl.dispose();
    _playArtistCtrl.dispose();
    _playSpotifyCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchSpotify(String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este tema no tiene enlace de Spotify.')),
      );
      return;
    }
    final Uri url = Uri.parse(urlString.trim());
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de Spotify.')),
      );
    }
  }

  void _showChangeFeaturedDialog(Map<String, dynamic>? current) {
    if (current != null) {
      _titleCtrl.text = current['title'] as String? ?? '';
      _artistCtrl.text = current['artist'] as String? ?? '';
      _spotifyUrlCtrl.text = current['spotifyUrl'] as String? ?? '';
    } else {
      _titleCtrl.clear();
      _artistCtrl.clear();
      _spotifyUrlCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Nuestra Canción'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título de la canción'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _artistCtrl,
                decoration: const InputDecoration(labelText: 'Artista / Banda'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _spotifyUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Spotify',
                  hintText: 'https://open.spotify.com/...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) return;
              final myName = LocalStorage().getUserName() ?? 'Yo';
              final title = _titleCtrl.text.trim();
              final artist = _artistCtrl.text.trim();
              final url = _spotifyUrlCtrl.text.trim();

              final db = FirebaseFirestore.instance;
              final coupleId = FirebaseService().coupleId;

              await db.collection('couples').doc(coupleId).collection('music').doc('featured').set({
                'title': title,
                'artist': artist,
                'spotifyUrl': url,
                'addedBy': myName,
                'timestamp': FieldValue.serverTimestamp(),
              });

              final historyId = DateTime.now().millisecondsSinceEpoch.toString();
              await db.collection('couples').doc(coupleId).collection('music_history').doc(historyId).set({
                'id': historyId,
                'title': title,
                'artist': artist,
                'spotifyUrl': url,
                'addedBy': myName,
                'timestamp': FieldValue.serverTimestamp(),
              });

              FirebaseService().sendActivityNotification(
                'actualizó Nuestra Canción: "$title" de $artist 🎵', 
                'music', 
                icon: 'music',
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddPlaylistDialog() {
    _playTitleCtrl.clear();
    _playArtistCtrl.clear();
    _playSpotifyCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.playlist_add_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Agregar a Playlist'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _playTitleCtrl,
                decoration: const InputDecoration(labelText: 'Título de la canción'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _playArtistCtrl,
                decoration: const InputDecoration(labelText: 'Artista / Banda'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _playSpotifyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Spotify',
                  hintText: 'https://open.spotify.com/...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_playTitleCtrl.text.trim().isEmpty) return;
              final myName = LocalStorage().getUserName() ?? 'Yo';
              final title = _playTitleCtrl.text.trim();
              final artist = _playArtistCtrl.text.trim();
              final url = _playSpotifyCtrl.text.trim();

              final db = FirebaseFirestore.instance;
              final coupleId = FirebaseService().coupleId;
              final docId = DateTime.now().millisecondsSinceEpoch.toString();

              await db.collection('couples').doc(coupleId).collection('playlist').doc(docId).set({
                'id': docId,
                'title': title,
                'artist': artist,
                'spotifyUrl': url,
                'addedBy': myName,
                'timestamp': FieldValue.serverTimestamp(),
              });

              FirebaseService().sendActivityNotification(
                'agregó "$title" a la playlist de la pareja 🎵', 
                'music', 
                icon: 'music',
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coupleId = FirebaseService().coupleId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestra Música'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historial de Canciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusicHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Featured Song Card (Nuestra Canción) ──
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .collection('music')
                  .doc('featured')
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final title = data?['title'] as String? ?? 'Nuestra Canción';
                final artist = data?['artist'] as String? ?? 'Aún no asignado';
                final spotifyUrl = data?['spotifyUrl'] as String? ?? '';
                final addedBy = data?['addedBy'] as String? ?? '';

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [cs.primary.withValues(alpha: 0.15), cs.secondary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Center(
                        child: RotationTransition(
                          turns: _spinCtrl,
                          child: Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.music_note_rounded, color: Colors.white, size: 44),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (addedBy.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Puesta con amor por $addedBy ❤️',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: cs.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _launchSpotify(spotifyUrl),
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.green),
                            label: const Text('Escuchar en Spotify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade50.withValues(alpha: 0.9),
                              foregroundColor: Colors.green.shade900,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _showChangeFeaturedDialog(data),
                            style: IconButton.styleFrom(
                              backgroundColor: cs.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Shared Playlist Title ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.playlist_play_rounded, size: 22, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Playlist Compartida',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddPlaylistDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Shared Playlist Stream ──
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .collection('playlist')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.library_music_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
                          const SizedBox(height: 8),
                          Text(
                            'La playlist está vacía.',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final id = data['id'] as String? ?? '';
                    final title = data['title'] as String? ?? '';
                    final artist = data['artist'] as String? ?? '';
                    final url = data['spotifyUrl'] as String? ?? '';
                    final addedBy = data['addedBy'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.music_note_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          artist.isNotEmpty ? '$artist • De $addedBy' : 'De $addedBy',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.green),
                              onPressed: () => _launchSpotify(url),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (confirmCtx) => AlertDialog(
                                    title: const Text('¿Quitar de la Playlist?'),
                                    content: Text('¿Deseas quitar la canción "$title" de la playlist?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final db = FirebaseFirestore.instance;
                                          await db.collection('couples').doc(coupleId).collection('playlist').doc(id).delete();
                                          FirebaseService().sendActivityNotification(
                                            'quitó "$title" de la playlist 🗑️', 
                                            'music', 
                                            icon: 'music',
                                          );
                                          if (confirmCtx.mounted) Navigator.pop(confirmCtx);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        child: const Text('Quitar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
