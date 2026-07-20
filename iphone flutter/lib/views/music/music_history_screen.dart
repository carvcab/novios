import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';

class MusicHistoryScreen extends StatefulWidget {
  const MusicHistoryScreen({super.key});

  @override
  State<MusicHistoryScreen> createState() => _MusicHistoryScreenState();
}

class _MusicHistoryScreenState extends State<MusicHistoryScreen> {
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
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  void _restoreSong(Map<String, dynamic> song) async {
    final title = song['title'] as String? ?? '';
    final artist = song['artist'] as String? ?? '';
    final url = song['spotifyUrl'] as String? ?? '';
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final coupleId = FirebaseService().coupleId;

    final db = FirebaseFirestore.instance;
    await db.collection('couples').doc(coupleId).collection('music').doc('featured').set({
      'title': title,
      'artist': artist,
      'spotifyUrl': url,
      'addedBy': myName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // También creamos un nuevo registro en el historial con el timestamp actual de la restauración
    final historyId = DateTime.now().millisecondsSinceEpoch.toString();
    await db.collection('couples').doc(coupleId).collection('music_history').doc(historyId).set({
      'id': historyId,
      'title': title,
      'artist': artist,
      'spotifyUrl': url,
      'addedBy': myName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseService().sendActivityNotification(
      'restauró Nuestra Canción: "$title" de $artist 🎵', 
      'music', 
      icon: 'music',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡"$title" restaurada como Nuestra Canción! ❤️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar del historial?'),
        content: Text('¿Deseas quitar la canción "$title" de tu historial de canciones destacadas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final coupleId = FirebaseService().coupleId;
              final db = FirebaseFirestore.instance;
              await db.collection('couples').doc(coupleId).collection('music_history').doc(id).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
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
        title: Text('Historial de Canciones', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .collection('music_history')
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
                  Icon(Icons.library_music_rounded, size: 64, color: cs.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Historial vacío',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí verán todas las canciones que pongan destacadas.',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // Ordenar en el cliente (por si la query no usa orderby y para evitar index requirements)
          final sortedDocs = docs.toList();
          sortedDocs.sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['timestamp'];
            final tb = (b.data() as Map<String, dynamic>)['timestamp'];
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return (b.id).compareTo(a.id);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final id = doc.id;
              final title = data['title'] as String? ?? 'Canción';
              final artist = data['artist'] as String? ?? 'Artista';
              final spotifyUrl = data['spotifyUrl'] as String? ?? '';
              final addedBy = data['addedBy'] as String? ?? '';
              final timestamp = data['timestamp'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary.withValues(alpha: 0.2), cs.secondary.withValues(alpha: 0.2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.music_note_rounded, color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist,
                              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.person_rounded, size: 10, color: cs.primary.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  '$addedBy • ',
                                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic),
                                ),
                                Text(
                                  _formatDateTime(timestamp),
                                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (spotifyUrl.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                              tooltip: 'Escuchar en Spotify',
                              onPressed: () => _launchSpotify(spotifyUrl),
                            ),
                          IconButton(
                            icon: Icon(Icons.restore_rounded, color: cs.primary),
                            tooltip: 'Restaurar canción',
                            onPressed: () => _restoreSong(data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            tooltip: 'Eliminar del historial',
                            onPressed: () => _confirmDelete(id, title),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
