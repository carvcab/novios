import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';

class DreamsScreen extends StatefulWidget {
  const DreamsScreen({super.key});

  @override
  State<DreamsScreen> createState() => _DreamsScreenState();
}

class _DreamsScreenState extends State<DreamsScreen> {
  List<Map<String, dynamic>> _dreams = [];
  StreamSubscription? _updateSub;

  static const _dreamIcons = <String, IconData>{
    'home': Icons.home_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'pets': Icons.pets_rounded,
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'child': Icons.child_care_rounded,
    'car': Icons.directions_car_rounded,
    'ring': Icons.diamond_rounded,
    'star': Icons.star_rounded,
    'heart': Icons.favorite_rounded,
  };

  @override
  void initState() {
    super.initState();
    _dreams = LocalStorage().getLocalList('dreams_list');
    _updateSub = FirebaseService.listUpdateStream.listen((key) {
      if (key == 'dreams_list' && mounted) {
        setState(() {
          _dreams = LocalStorage().getLocalList('dreams_list');
        });
      }
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    super.dispose();
  }

  void _save() => FirebaseService().saveListData('dreams_list', _dreams);

  void _addDream() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedIcon = 'star';
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
                Icon(Icons.auto_awesome_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Nuevo Sueño', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '¿Cuál es el sueño?'),
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
                  const Text('Icono representativo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dreamIcons.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? cs.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(entry.value, color: isSelected ? cs.primary : Colors.white54, size: 20),
                        ),
                      );
                    }).toList(),
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
                  final titleText = titleCtrl.text.trim();
                  setState(() {
                    _dreams.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleText,
                      'desc': descCtrl.text.trim(),
                      'icon': selectedIcon,
                      'proposedBy': proposedBy,
                      'done': false,
                    });
                    _save();
                  });
                  FirebaseService().sendActivityNotification('Agregó un nuevo sueño: "$titleText" 🌠', 'dream', icon: 'star');
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
      _dreams[index]['done'] = !(_dreams[index]['done'] as bool);
    });
    _save();
    final isDone = _dreams[index]['done'] as bool;
    final title = _dreams[index]['title'] ?? '';
    if (isDone) {
      FirebaseService().sendActivityNotification('¡Cumplió el sueño: $title! 🌟💖', 'dream', icon: 'done');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Hermoso! Sueño cumplido: "$title" 💖',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFAB47BC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _delete(int index) {
    setState(() => _dreams.removeAt(index));
    _save();
  }

  void _editOrDeleteDream(int index) {
    final dream = _dreams[index];
    final titleCtrl = TextEditingController(text: dream['title']);
    final descCtrl = TextEditingController(text: dream['desc']);
    String selectedIcon = dream['icon'] as String? ?? 'star';
    String proposedBy = dream['proposedBy'] as String? ?? 'both';

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
                Text('Editar Sueño', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '¿Cuál es el sueño?'),
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
                  const Text('Icono representativo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dreamIcons.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? cs.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(entry.value, color: isSelected ? cs.primary : Colors.white54, size: 20),
                        ),
                      );
                    }).toList(),
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
                    _dreams[index] = {
                      'id': dream['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleCtrl.text.trim(),
                      'desc': descCtrl.text.trim(),
                      'icon': selectedIcon,
                      'proposedBy': proposedBy,
                      'done': dream['done'] ?? false,
                    };
                    _save();
                  });
                  FirebaseService().sendActivityNotification('Actualizó el sueño: "${titleCtrl.text.trim()}" 🌠', 'dream', icon: 'star');
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
    final completed = _dreams.where((e) => e['done'] == true).toList();

    double progress = 0.0;
    if (_dreams.isNotEmpty) {
      progress = completed.length / _dreams.length;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF040A12) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text('Nuestros Sueños', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface)),
      ),
      body: Column(
        children: [
          // Header Progress Indicator
          if (_dreams.isNotEmpty)
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
                            color: isDark ? const Color(0xFF00E5FF) : cs.primary,
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: isDark ? const Color(0xFF00E5FF) : cs.primary,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sueños en Común',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¡Llevan ${completed.length} de ${_dreams.length} metas soñadas cumplidas! 🌌',
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
            child: _dreams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 64, color: cs.primary.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text(
                          'Muro de Sueños Vacío',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Cuáles son sus metas en común?',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _dreams.length,
                    itemBuilder: (ctx, i) {
                      final dream = _dreams[i];
                      final idx = _dreams.indexOf(dream);
                      final done = dream['done'] == true;
                      final iconKey = dream['icon'] as String? ?? 'star';
                      final icon = _dreamIcons[iconKey] ?? Icons.star_rounded;
                      final title = dream['title'] as String? ?? '';
                      final desc = dream['desc'] as String? ?? '';
                      final proposedBy = dream['proposedBy'] as String? ?? 'both';

                      String proposerText = 'Ambos';
                      if (proposedBy == 'me') {
                        proposerText = 'Yo';
                      } else if (proposedBy == 'partner') {
                        proposerText = 'Pareja';
                      }

                      return GestureDetector(
                        onTap: () => _toggle(idx),
                        onLongPress: () => _editOrDeleteDream(idx),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          glow: done,
                          glowColor: Colors.green,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: done ? Colors.green.withValues(alpha: 0.15) : cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, color: done ? Colors.green : cs.primary, size: 20),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    color: done ? Colors.green : cs.onSurface.withValues(alpha: 0.25),
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: done ? cs.onSurface.withValues(alpha: 0.38) : cs.onSurface,
                                          decoration: done ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: done ? cs.onSurface.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.54),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.onSurface.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Por: $proposerText',
                                      style: TextStyle(fontSize: 8, color: cs.onSurface.withValues(alpha: 0.38)),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (done)
                                    const Text(
                                      '¡Cumplido! 🎉',
                                      style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDream,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
