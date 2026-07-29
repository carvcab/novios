import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  static const _faceOptions = [6, 8, 10, 20];

  bool _isNumeric = true;
  int _selectedFaces = 6;
  List<Map<String, dynamic>> _customDiceList = [];
  Map<String, dynamic>? _selectedCustomDice;
  StreamSubscription? _sub;

  bool _rolling = false;
  String _result = '';
  String _tempResult = '';
  Timer? _rollTimer;
  int _rollCount = 0;

  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _sub = GameService().streamDice().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customDiceList = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, ...data};
        }).toList();
      });
    });
  }

  void _roll() {
    if (_rolling) return;
    setState(() {
      _rolling = true;
      _result = '';
      _rollCount = 0;
    });
    _rollTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      _rollCount++;
      setState(() {
        _tempResult = _randomFace();
      });
      if (_rollCount >= 20) {
        timer.cancel();
        setState(() {
          _result = _randomFace();
          _rolling = false;
        });
        _saveStats();
      }
    });
  }

  String _randomFace() {
    if (_isNumeric) {
      return (Random().nextInt(_selectedFaces) + 1).toString();
    }
    final faces = List<String>.from(_selectedCustomDice?['faces'] ?? []);
    if (faces.isEmpty) return '?';
    return faces[Random().nextInt(faces.length)];
  }

  List<String> _currentFaces() {
    if (_isNumeric) {
      return List.generate(_selectedFaces, (i) => (i + 1).toString());
    }
    return List<String>.from(_selectedCustomDice?['faces'] ?? []);
  }

  void _saveStats() {
    GameService().saveGameStats('dados', {
      'result': _result,
      'mode': _isNumeric ? 'numeric' : 'custom',
      'faces': _selectedFaces,
      'diceName': _isNumeric ? null : _selectedCustomDice?['name'],
    });
  }

  void _showCreateDialog({Map<String, dynamic>? edit}) {
    final nameCtrl = TextEditingController(text: edit?['name'] ?? '');
    final faceCtrl = TextEditingController();
    final faces = ValueNotifier<List<String>>(
      edit != null ? List<String>.from(edit['faces']) : [],
    );
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(edit != null ? 'Editar dado' : 'Nuevo dado',
              style: GoogleFonts.outfit()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre', border: OutlineInputBorder()),
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: faceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Agregar cara',
                            border: OutlineInputBorder()),
                        style: GoogleFonts.outfit(),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            faces.value = [...faces.value, v.trim()];
                            faceCtrl.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        if (faceCtrl.text.trim().isNotEmpty) {
                          faces.value = [
                            ...faces.value,
                            faceCtrl.text.trim()
                          ];
                          faceCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<String>>(
                  valueListenable: faces,
                  builder: (_, list, __) => Column(
                    children: list.asMap().entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.value, style: GoogleFonts.outfit()),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          faces.value = List.from(list)..removeAt(e.key);
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.outfit())),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || faces.value.isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'faces': faces.value,
                };
                if (edit != null) {
                  await GameService().saveDice(data, id: edit['id']);
                } else {
                  await GameService().saveDice(data);
                }
                Navigator.pop(ctx);
              },
              child: Text('Guardar', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDice(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar', style: GoogleFonts.outfit()),
        content: Text('Eliminar este dado personalizado?',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              GameService().deleteDice(id);
              if (_selectedCustomDice?['id'] == id) {
                setState(() {
                  _selectedCustomDice = null;
                  _isNumeric = true;
                  _selectedFaces = 6;
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Eliminar',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = _rolling ? _tempResult : _result;
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.play_arrow_rounded : Icons.edit_note_rounded, color: cs.onSurface),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: _editMode ? _buildEditMode(cs) : _buildGameMode(cs, display),
      floatingActionButton: _editMode
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(),
              backgroundColor: cs.primary,
              child: Icon(Icons.add, color: cs.onSurface),
            )
          : null,
    );
  }

  Widget _buildGameMode(ColorScheme cs, String display) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: true,
                  label: Text('Numerico', style: GoogleFonts.outfit())),
              ButtonSegment(
                  value: false,
                  label: Text('Personalizado', style: GoogleFonts.outfit())),
            ],
            selected: {_isNumeric},
            onSelectionChanged: (v) {
              setState(() {
                _isNumeric = v.first;
                _result = '';
                if (_isNumeric) _selectedCustomDice = null;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_isNumeric)
            SegmentedButton<int>(
              segments: _faceOptions
                  .map((f) => ButtonSegment(
                      value: f,
                      label: Text('$f', style: GoogleFonts.outfit())))
                  .toList(),
              selected: {_selectedFaces},
              onSelectionChanged: (v) {
                setState(() {
                  _selectedFaces = v.first;
                  _result = '';
                });
              },
            ),
          if (!_isNumeric && _customDiceList.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: _customDiceList.map((d) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(d['name'] ?? '',
                        style: GoogleFonts.outfit()),
                    selected: _selectedCustomDice?['id'] == d['id'],
                    onSelected: (_) {
                      setState(() {
                        _selectedCustomDice = d;
                        _result = '';
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
          if (!_isNumeric && _customDiceList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Crea tu primer dado personalizado!',
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.6))),
            ),
          const SizedBox(height: 32),
          AnimatedScale(
            scale: _rolling ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    display.isEmpty
                        ? _isNumeric
                            ? '$_selectedFaces'
                            : '?'
                        : display,
                    key: ValueKey(display),
                    style: GoogleFonts.outfit(
                        color: cs.onSurface,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_result.isNotEmpty && !_rolling)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: cs.secondary.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Resultado',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: cs.onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    Text(_result,
                        style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: cs.primary)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!_isNumeric && _selectedCustomDice != null)
            Text(_selectedCustomDice!['name'] ?? '',
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.5))),
          const Spacer(),
          ElevatedButton(
            onPressed: _rolling
                ? null
                : (!_isNumeric && _selectedCustomDice == null)
                    ? null
                    : _roll,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
                _rolling
                    ? '...'
                    : 'Lanzar dado',
                style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text('Caras: ${_currentFaces().join(", ")}',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEditMode(ColorScheme cs) {
    if (_customDiceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No hay dados personalizados', style: GoogleFonts.outfit(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Crea el primero con +', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _customDiceList.length,
      itemBuilder: (_, i) {
        final d = _customDiceList[i];
        final isOwner = d['authorId'] == LocalStorage().getUserId();
        final faceCount = (d['faces'] as List?)?.length ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.casino_rounded, color: cs.primary),
            title: Text(d['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text('$faceCount caras', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            trailing: isOwner ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: cs.primary),
                  onPressed: () => _showCreateDialog(edit: d),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteDice(d['id']),
                ),
              ],
            ) : null,
          ),
        );
      },
    );
  }
}
