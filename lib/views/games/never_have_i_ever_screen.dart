import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class NeverHaveIEverScreen extends StatefulWidget {
  const NeverHaveIEverScreen({super.key});

  @override
  State<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends State<NeverHaveIEverScreen> {
  static const _categories = [
    'Todas', 'Romantico', 'Divertido', 'Parejas',
    'Viajes', 'Universidad', 'Infancia', 'Picante'
  ];

  static const _defaults = [
    {'text': 'Yo nunca he mentido en una cita', 'category': 'Romantico'},
    {'text': 'Yo nunca he enviado un mensaje borracho/a', 'category': 'Divertido'},
    {'text': 'Yo nunca he cocinado para mi pareja', 'category': 'Parejas'},
    {'text': 'Yo nunca he viajado solo/a', 'category': 'Viajes'},
    {'text': 'Yo nunca he copiado en un examen', 'category': 'Universidad'},
    {'text': 'Yo nunca me he perdido en un centro comercial', 'category': 'Infancia'},
    {'text': 'Yo nunca he visto una pelicula para adultos', 'category': 'Picante'},
    {'text': 'Yo nunca he dicho te quiero sin sentirlo', 'category': 'Romantico'},
    {'text': 'Yo nunca he cantado en la ducha', 'category': 'Divertido'},
    {'text': 'Yo nunca he hecho una cena romantica', 'category': 'Parejas'},
    {'text': 'Yo nunca he dormido en un aeropuerto', 'category': 'Viajes'},
    {'text': 'Yo nunca he llegado tarde a clase', 'category': 'Universidad'},
    {'text': 'Yo nunca he tenido una mascota', 'category': 'Infancia'},
    {'text': 'Yo nunca he enviado una foto intima', 'category': 'Picante'},
    {'text': 'Yo nunca he escrito una carta de amor', 'category': 'Romantico'},
    {'text': 'Yo nunca he bailado solo/a en casa', 'category': 'Divertido'},
    {'text': 'Yo nunca he visto el amanecer con mi pareja', 'category': 'Parejas'},
    {'text': 'Yo nunca he viajado en avion', 'category': 'Viajes'},
    {'text': 'Yo nunca he hecho una fiesta en el campus', 'category': 'Universidad'},
    {'text': 'Yo nunca me he escapado de casa', 'category': 'Infancia'},
    {'text': 'Yo nunca he usado un juguete intimo', 'category': 'Picante'},
    {'text': 'Yo nunca he tenido una cita a ciegas', 'category': 'Romantico'},
    {'text': 'Yo nunca he visto una serie completa en un dia', 'category': 'Divertido'},
    {'text': 'Yo nunca he discutido por celos', 'category': 'Parejas'},
    {'text': 'Yo nunca he hecho un viaje por carretera', 'category': 'Viajes'},
    {'text': 'Yo nunca he estudiado toda la noche', 'category': 'Universidad'},
    {'text': 'Yo nunca me he subido a un arbol', 'category': 'Infancia'},
    {'text': 'Yo nunca he tenido un sueno erotico', 'category': 'Picante'},
    {'text': 'Yo nunca he llorado por una pelicula romantica', 'category': 'Romantico'},
    {'text': 'Yo nunca he hecho una broma pesada', 'category': 'Divertido'},
  ];

  List<Map<String, dynamic>> _allStatements = [];
  String _selectedCategory = 'Todas';
  int _currentIndex = 0;
  int _playerTurn = 1;
  bool _gameOver = false;

  Map<String, int> _p1CategoryScores = {};
  Map<String, int> _p2CategoryScores = {};
  int _p1Total = 0;
  int _p2Total = 0;

  StreamSubscription? _sub;
  List<Map<String, dynamic>> _customStatements = [];

  @override
  void initState() {
    super.initState();
    _sub = GameService().streamNever().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customStatements = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, 'text': data['text'], 'category': data['category'] ?? 'Personalizado', 'custom': true};
        }).toList();
      });
    });
    _startGame();
  }

  List<Map<String, dynamic>> _filteredStatements() {
    final combined = [
      ..._defaults.map((e) => Map<String, dynamic>.from(e)..['custom'] = false),
      ..._customStatements,
    ];
    if (_selectedCategory == 'Todas') return combined;
    return combined.where((s) => s['category'] == _selectedCategory).toList();
  }

  void _startGame() {
    final filtered = _filteredStatements();
    filtered.shuffle(Random());
    setState(() {
      _allStatements = filtered;
      _currentIndex = 0;
      _playerTurn = 1;
      _gameOver = false;
      _p1CategoryScores = {};
      _p2CategoryScores = {};
      _p1Total = 0;
      _p2Total = 0;
    });
  }

  void _answer(bool done) {
    if (_gameOver || _currentIndex >= _allStatements.length) return;
    final statement = _allStatements[_currentIndex];
    final cat = statement['category'] as String? ?? 'General';
    setState(() {
      if (_playerTurn == 1) {
        if (done) {
          _p1CategoryScores[cat] = (_p1CategoryScores[cat] ?? 0) + 1;
          _p1Total++;
        }
        _playerTurn = 2;
      } else {
        if (done) {
          _p2CategoryScores[cat] = (_p2CategoryScores[cat] ?? 0) + 1;
          _p2Total++;
        }
        if (_currentIndex >= _allStatements.length - 1) {
          _gameOver = true;
          _showResult();
        } else {
          _currentIndex++;
          _playerTurn = 1;
        }
      }
    });
    if (_gameOver) _saveStats();
  }

  void _saveStats() {
    GameService().saveGameStats('yo_nunca', {
      'p1Score': _p1Total,
      'p2Score': _p2Total,
      'total': _allStatements.length,
      'category': _selectedCategory,
    });
  }

  void _showResult() {
    final cs = Theme.of(context).colorScheme;
    final allCats = <String>{};
    allCats.addAll(_p1CategoryScores.keys);
    allCats.addAll(_p2CategoryScores.keys);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resultado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Jugador 1: $_p1Total  |  Jugador 2: $_p2Total',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...allCats.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat, style: GoogleFonts.outfit(fontSize: 14)),
                    Text('${_p1CategoryScores[cat] ?? 0} - ${_p2CategoryScores[cat] ?? 0}',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Text(
                _p1Total > _p2Total
                    ? 'Gana Jugador 1!'
                    : _p2Total > _p1Total
                        ? 'Gana Jugador 2!'
                        : 'Empate!',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: cs.secondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); _startGame(); },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final textCtrl = TextEditingController();
    String selectedCat = _categories[1];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Agregar declaracion', style: GoogleFonts.outfit()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(labelText: 'Yo nunca...', border: OutlineInputBorder()),
                style: GoogleFonts.outfit(),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCat,
                items: _categories.where((c) => c != 'Todas').map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit()))).toList(),
                onChanged: (v) { if (v != null) selectedCat = v; },
                decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
            TextButton(
              onPressed: () async {
                if (textCtrl.text.trim().isEmpty) return;
                await GameService().saveNever({
                  'text': 'Yo nunca ${textCtrl.text.trim()}',
                  'category': selectedCat,
                });
                Navigator.pop(ctx);
              },
              child: Text('Guardar', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteStatement(String id) {
    GameService().deleteNever(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nunca he...', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text('P1: $_p1Total  P2: $_p2Total',
                  style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat, style: GoogleFonts.outfit(fontSize: 12)),
                    selected: _selectedCategory == cat,
                    onSelected: (v) {
                      setState(() => _selectedCategory = cat);
                      _startGame();
                    },
                  ),
                )).toList(),
              ),
            ),
          ),
          if (_allStatements.isEmpty)
            Expanded(
              child: Center(
                child: Text('No hay declaraciones para esta categoria',
                    style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Turno: Jugador $_playerTurn',
                            style: GoogleFonts.outfit(fontSize: 14, color: cs.secondary, fontWeight: FontWeight.bold)),
                        Text('${_currentIndex + 1} de ${_allStatements.length}',
                            style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            _allStatements[_currentIndex]['text'] ?? '',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _allStatements[_currentIndex]['category'] ?? '',
                            style: GoogleFonts.outfit(fontSize: 12, color: cs.secondary),
                          ),
                          if (_allStatements[_currentIndex]['custom'] == true)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _deleteStatement(_allStatements[_currentIndex]['id']),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: _gameOver ? null : () => _answer(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('He hecho', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: _gameOver ? null : () => _answer(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Nunca', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_gameOver)
                    ElevatedButton(
                      onPressed: _showResult,
                      style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                      child: Text('Ver resultado', style: GoogleFonts.outfit(color: cs.onSurface)),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: cs.primary,
        child: Icon(Icons.add, color: cs.onSurface),
      ),
    );
  }
}
