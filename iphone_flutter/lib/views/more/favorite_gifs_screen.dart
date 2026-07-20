import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class FavoriteGifsScreen extends StatefulWidget {
  const FavoriteGifsScreen({super.key});

  @override
  State<FavoriteGifsScreen> createState() => _FavoriteGifsScreenState();
}

class _FavoriteGifsScreenState extends State<FavoriteGifsScreen> {
  final List<Map<String, String>> _gifs = [];
  final _urlCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  void _loadGifs() async {
    try {
      final list = await FirebaseService().loadListData('favorite_gifs');
      if (mounted) {
        setState(() {
          _gifs.addAll(list.map((e) => Map<String, String>.from(e)));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addGif() async {
    final url = _urlCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (url.isEmpty) return;

    final gifName = name.isEmpty ? 'GIF ${_gifs.length + 1}' : name;

    setState(() {
      _gifs.add({'url': url, 'name': gifName});
    });

    await FirebaseService().saveListData(
      'favorite_gifs',
      _gifs.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    _urlCtrl.clear();
    _nameCtrl.clear();
    if (mounted) Navigator.pop(context);
  }

  void _openAddDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Agregar GIF Favorito'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre o Título (Opcional)',
                hintText: 'Ej. Besitos tiernos',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Enlace/URL del GIF',
                hintText: 'https://media.giphy.com/...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: _addGif,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _deleteGif(int index) async {
    setState(() {
      _gifs.removeAt(index);
    });
    await FirebaseService().saveListData(
      'favorite_gifs',
      _gifs.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  void _zoomGif(Map<String, String> gif) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              gif['url'] ?? '',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.white,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      gif['name'] ?? 'GIF',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('GIFs Favoritos', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Agregar GIF',
            onPressed: _openAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: cs.primaryContainer.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(Icons.gif_box_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pega enlaces de GIPHY o Tenor para coleccionar tus GIFs favoritos de pareja y verlos en cualquier momento.',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _gifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gif_box_rounded, size: 64, color: cs.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay GIFs guardados',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Agregar el primer GIF'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _gifs.length,
                    itemBuilder: (ctx, i) {
                      final gif = _gifs[i];

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              onTap: () => _zoomGif(gif),
                              child: Image.network(
                                gif['url'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                      const SizedBox(height: 4),
                                      Text('Error al cargar', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black87],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        gif['name'] ?? 'GIF',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _deleteGif(i),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
