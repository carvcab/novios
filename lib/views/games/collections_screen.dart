import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/game_service.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _gs = GameService();

  static const _defaultCollections = [
    'Romantico', 'Divertido', 'Picante', 'Viajes', 'Personal', 'Universidad',
  ];

  static const _collectionIcons = {
    'Romantico': Icons.favorite_rounded,
    'Divertido': Icons.celebration_rounded,
    'Picante': Icons.whatshot_rounded,
    'Viajes': Icons.flight_rounded,
    'Personal': Icons.person_rounded,
    'Universidad': Icons.school_rounded,
  };

  static const _collectionColors = {
    'Romantico': Color(0xFFE91E63),
    'Divertido': Color(0xFFFF9800),
    'Picante': Color(0xFFEF4444),
    'Viajes': Color(0xFF2196F3),
    'Personal': Color(0xFF9C27B0),
    'Universidad': Color(0xFF4CAF50),
  };

  void _createCollection({String? editId, String? editName}) {
    final nameCtrl = TextEditingController(text: editName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(editId != null ? 'Editar coleccion' : 'Nueva coleccion', style: GoogleFonts.outfit()),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.outfit(),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (editId != null) {
                await _gs.saveCollection({'name': nameCtrl.text.trim()}, id: editId);
              } else {
                await _gs.saveCollection({'name': nameCtrl.text.trim()});
              }
              Navigator.pop(ctx);
            },
            child: Text('Guardar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _deleteCollection(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar coleccion', style: GoogleFonts.outfit()),
        content: Text('Seguro? Los items no se eliminaran.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _gs.deleteCollection(id); },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Colecciones', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _gs.streamCollections(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final customNames = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['name'] as String? ?? '';
          }).toSet();
          final allNames = {..._defaultCollections, ...customNames};
          final list = allNames.toList()..sort();

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final name = list[i];
              final isDefault = _defaultCollections.contains(name);
              final doc = docs.where((d) => (d.data() as Map<String, dynamic>)['name'] == name).firstOrNull;
              final icon = _collectionIcons[name] ?? Icons.folder_rounded;
              final color = _collectionColors[name] ?? cs.primary;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showCollectionItems(context, name, color, icon),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 40),
                      const SizedBox(height: 8),
                      Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (!isDefault && doc != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 16, color: cs.primary),
                              onPressed: () => _createCollection(editId: doc.id, editName: name),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 16, color: Colors.red),
                              onPressed: () => _deleteCollection(doc.id),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCollection(),
        backgroundColor: cs.primary,
        child: Icon(Icons.add, color: cs.onSurface),
      ),
    );
  }

  void _showCollectionItems(BuildContext context, String collectionName, Color color, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(collectionName, style: GoogleFonts.outfit(color: cs.onSurface)),
          backgroundColor: color,
        ),
        body: _CollectionItemsView(collectionName: collectionName, color: color, icon: icon),
      ),
    ));
  }
}

class _CollectionItemsView extends StatelessWidget {
  final String collectionName;
  final Color color;
  final IconData icon;
  const _CollectionItemsView({required this.collectionName, required this.color, required this.icon});

  static const _gameTypes = [
    ('verdad_reto', 'Verdad o Reto', Icons.favorite_rounded),
    ('yo_nunca', 'Yo Nunca Nunca', Icons.wine_bar_rounded),
    ('que_prefieres', 'Que Prefieres', Icons.help_outline_rounded),
    ('ahorcados', 'Ahorcado', Icons.person_search_rounded),
    ('amor', 'Love Game', Icons.favorite_border_rounded),
    ('quizzes', 'Quizzes', Icons.quiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _gameTypes.map((gt) {
        final (gameType, gameName, gameIcon) = gt;
        return StreamBuilder<QuerySnapshot>(
          stream: GameService().streamAll(gameType),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final items = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['collection'] == collectionName;
            }).toList();

            if (items.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(gameIcon, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(gameName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('(${items.length})', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                ...items.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final text = d['text'] ?? d['content'] ?? d['optionA'] ?? d['word'] ?? d['title'] ?? '(sin texto)';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      leading: Icon(icon, color: color, size: 20),
                      title: Text('$text', style: GoogleFonts.outfit(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      }).toList(),
    );
  }
}
