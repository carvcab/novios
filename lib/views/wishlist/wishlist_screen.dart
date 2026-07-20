import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _items = [];
  StreamSubscription? _updateSub;

  final Map<String, Map<String, dynamic>> _categories = {
    'adventure': {'name': 'Aventura 🧗', 'color': const Color(0xFFAB47BC)},
    'food': {'name': 'Cena/Comida 🍕', 'color': const Color(0xFFFFB74D)},
    'movie': {'name': 'Cine/Serie 🎬', 'color': const Color(0xFF4FC3F7)},
    'trip': {'name': 'Viajar ✈️', 'color': const Color(0xFF7C83FF)},
    'home': {'name': 'En Casa 🏠', 'color': const Color(0xFF66BB6A)},
    'other': {'name': 'Otro 🌟', 'color': Colors.blueGrey},
  };

  @override
  void initState() {
    super.initState();
    _items = LocalStorage().getLocalList('wishlist');
    _updateSub = FirebaseService.listUpdateStream.listen((key) {
      if (key == 'wishlist' && mounted) {
        setState(() {
          _items = LocalStorage().getLocalList('wishlist');
        });
      }
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    super.dispose();
  }

  void _save() => FirebaseService().saveListData('wishlist', _items);

  void _addItem() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCat = 'other';
    String proposedBy = 'both'; // 'me', 'partner', 'both'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.star_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Nuevo Deseo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '¿Qué quieren hacer?'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Detalles / Notas (opcional)'),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Categoría:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value['name'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCat = v);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Propuesto por:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'both', label: Text('Ambos', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'me', label: Text('Yo', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'partner', label: Text('Pareja', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {proposedBy},
                    onSelectionChanged: (set) {
                      setDialogState(() => proposedBy = set.first);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final now = DateTime.now();
                  final titleText = titleCtrl.text.trim();
                  setState(() {
                    _items.add({
                      'id': now.millisecondsSinceEpoch.toString(),
                      'title': titleText,
                      'desc': descCtrl.text.trim(),
                      'done': false,
                      'category': selectedCat,
                      'proposedBy': proposedBy,
                      'date': '${now.day}/${now.month}/${now.year}',
                    });
                  });
                  _save();
                  FirebaseService().sendActivityNotification('Añadió a la lista de deseos: $titleText 🌟', 'wishlist', icon: 'star');
                  Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggle(int index) {
    setState(() {
      _items[index]['done'] = !(_items[index]['done'] as bool);
    });
    _save();
    final isDone = _items[index]['done'] as bool;
    final title = _items[index]['title'] ?? '';
    if (isDone) {
      FirebaseService().sendActivityNotification('Cumplió el deseo: $title 🎉', 'wishlist', icon: 'done');
      // Confetti feedback effect
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Felicidades! Deseo cumplido: "$title" 🎉',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _delete(int index) {
    setState(() => _items.removeAt(index));
    _save();
  }

  void _editOrDeleteItem(int index) {
    final item = _items[index];
    final titleCtrl = TextEditingController(text: item['title']);
    final descCtrl = TextEditingController(text: item['desc']);
    String selectedCat = item['category'] as String? ?? 'other';
    String proposedBy = item['proposedBy'] as String? ?? 'both';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Editar Deseo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '¿Qué quieren hacer?'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Detalles / Notas'),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Categoría:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value['name'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCat = v);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Propuesto por:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'both', label: Text('Ambos', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'me', label: Text('Yo', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'partner', label: Text('Pareja', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {proposedBy},
                    onSelectionChanged: (set) {
                      setDialogState(() => proposedBy = set.first);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _delete(index);
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _items[index] = {
                      'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleCtrl.text.trim(),
                      'desc': descCtrl.text.trim(),
                      'done': item['done'] ?? false,
                      'category': selectedCat,
                      'proposedBy': proposedBy,
                      'date': item['date'] ?? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    };
                  });
                  _save();
                  FirebaseService().sendActivityNotification('Actualizó la lista de deseos: "${titleCtrl.text.trim()}" 🌟', 'wishlist', icon: 'star');
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = _items.where((e) => e['done'] != true).toList();
    final completed = _items.where((e) => e['done'] == true).toList();

    double progress = 0.0;
    if (_items.isNotEmpty) {
      progress = completed.length / _items.length;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0B15) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text('Lista de Deseos', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface)),
      ),
      body: Column(
        children: [
          // Header Progress Indicator
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: cs.primary.withValues(alpha: 0.1),
                            color: isDark ? const Color(0xFFFF4081) : cs.primary,
                          ),
                        ),
                        Icon(Icons.favorite_rounded, color: isDark ? const Color(0xFFFF4081) : cs.primary, size: 24),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progreso de Deseos',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¡Llevan ${completed.length} de ${_items.length} deseos cumplidos juntos! 🎉',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 64, color: cs.primary.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text(
                          'Lista vacía',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Qué quieren hacer juntos?',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    children: [
                      if (pending.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 18, color: const Color(0xFFD4AF37)),
                            const SizedBox(width: 6),
                            Text(
                              'Pendientes (${pending.length})',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...pending.map((item) {
                          final idx = _items.indexOf(item);
                          return _WishItem(
                            item: item,
                            cs: cs,
                            categories: _categories,
                            onToggle: () => _toggle(idx),
                            onDelete: () => _delete(idx),
                            onLongPress: () => _editOrDeleteItem(idx),
                          );
                        }),
                      ],
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'Cumplidos (${completed.length})',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...completed.map((item) {
                          final idx = _items.indexOf(item);
                          return _WishItem(
                            item: item,
                            cs: cs,
                            categories: _categories,
                            onToggle: () => _toggle(idx),
                            onDelete: () => _delete(idx),
                            onLongPress: () => _editOrDeleteItem(idx),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: isDark ? const Color(0xFFFF4081) : cs.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _WishItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme cs;
  final Map<String, Map<String, dynamic>> categories;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const _WishItem({
    required this.item,
    required this.cs,
    required this.categories,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final done = item['done'] == true;
    final title = item['title'] as String? ?? '';
    final desc = item['desc'] as String? ?? '';
    final date = item['date'] as String? ?? '';
    final catKey = item['category'] as String? ?? 'other';
    final proposedBy = item['proposedBy'] as String? ?? 'both';

    final category = categories[catKey] ?? categories['other']!;
    final catColor = category['color'] as Color;
    final catName = category['name'] as String;

    String proposerText = 'Ambos 💑';
    if (proposedBy == 'me') {
      proposerText = 'Propuesto por Mí 🙋';
    } else if (proposedBy == 'partner') {
      proposerText = 'Propuesto por Pareja 👩‍❤️‍👨';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(item['id'] as String? ?? title),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.delete_rounded, color: Colors.red.shade400),
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onLongPress: onLongPress,
            leading: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.green.withValues(alpha: 0.15) : cs.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: done ? Colors.green : cs.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: done ? Icon(Icons.check_rounded, color: Colors.green, size: 20) : null,
              ),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: done ? cs.onSurface.withValues(alpha: 0.38) : cs.onSurface,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: done ? cs.onSurface.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(
                        catName,
                        style: TextStyle(fontSize: 9, color: catColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        proposerText,
                        style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.54)),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.24)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
