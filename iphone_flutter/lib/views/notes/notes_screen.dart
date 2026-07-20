import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Color> _noteColors = const [
    Color(0xFFFFEA7F), // Classic Yellow
    Color(0xFFFF8F7F), // Soft Red
    Color(0xFF7C83FF), // Soft Blue
    Color(0xFF81C784), // Soft Green
    Color(0xFFFFB74D), // Soft Orange
    Color(0xFFE1BEE7), // Soft Purple
  ];

  void _addNote() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    int selectedColorIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.note_add_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Nueva Nota Adhesiva', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    decoration: const InputDecoration(labelText: 'Mensaje de la nota'),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color de la nota:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_noteColors.length, (i) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColorIdx = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _noteColors[i],
                            shape: BoxShape.circle,
                            border: selectedColorIdx == i
                                ? Border.all(color: Colors.white, width: 3)
                                : Border.all(color: Colors.white10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final now = DateTime.now();
                  final titleText = titleCtrl.text.trim();
                  
                  final note = {
                    'id': now.millisecondsSinceEpoch.toString(),
                    'title': titleText,
                    'content': contentCtrl.text.trim(),
                    'color': _noteColors[selectedColorIdx].toARGB32().toRadixString(16),
                    'date': '${now.day}/${now.month}/${now.year}',
                    'from': LocalStorage().getUserName() ?? 'Yo',
                  };

                  FirebaseService().addSharedNote(note);
                  FirebaseService().sendActivityNotification('Dejó una nota: $titleText 📌', 'note', icon: 'notes');
                  Navigator.pop(ctx);
                },
                child: const Text('Colgar Nota'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return const Color(0xFFFFEA7F);
    }
  }

  double _getRotationAngle(String id) {
    // Generar un ángulo determinista basado en el ID de la nota para que no baile al redibujar
    final num = int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final double degrees = (num % 8) - 4.0; // Inclinación entre -4 y 4 grados
    return degrees * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1610) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text('Muro de Notas 📌', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface)),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E140A) : const Color(0xFFFAF6F0),
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1596263576925-d90d63691097?q=80&w=300&auto=format&fit=crop'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService().streamSharedNotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final notes = snapshot.data ?? [];

            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sticky_note_2_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.24)),
                    const SizedBox(height: 16),
                    Text(
                      'Tablero Vacío',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deja un post-it virtual para tu pareja 💖',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.95,
              ),
              itemCount: notes.length,
              itemBuilder: (ctx, i) {
                final note = notes[i];
                final noteId = note['id'] as String? ?? '$i';
                final color = _parseColor(note['color'] as String? ?? 'FFFFEA7F');
                final angle = _getRotationAngle(noteId);

                return Dismissible(
                  key: Key(noteId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    FirebaseService().deleteSharedNote(noteId);
                  },
                  background: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 36),
                  ),
                  child: Transform.rotate(
                    angle: angle,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Post-it Card
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(2, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note['title'] as String? ?? '',
                                        style: GoogleFonts.caveat(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        note['from'] as String? ?? '',
                                        style: const TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.black12, height: 10),
                                Expanded(
                                  child: Text(
                                    note['content'] as String? ?? '',
                                    style: GoogleFonts.caveat(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    note['date'] as String? ?? '',
                                    style: const TextStyle(fontSize: 8, color: Colors.black38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Push Pin (Chincheta)
                        Positioned(
                          top: -8,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade900,
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(1, 3),
                                ),
                              ],
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: isDark ? const Color(0xFFD4AF37) : cs.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.pin_drop_rounded),
      ),
    );
  }
}
