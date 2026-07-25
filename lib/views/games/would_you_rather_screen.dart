import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  static const _categories = [
    'Todas', 'Romantico', 'Divertido', 'Viajes', 'Comida', 'Futuro', 'Personalizado'
  ];

  static const _defaults = [
    {'a': 'Viajar por el mundo conmigo', 'b': 'Recibir un regalo sorpresa cada mes', 'category': 'Viajes'},
    {'a': 'Una cena romantica en casa', 'b': 'Una cita en un restaurante elegante', 'category': 'Romantico'},
    {'a': 'Reir sin parar todos los dias', 'b': 'Conversar profundamente cada noche', 'category': 'Divertido'},
    {'a': 'Comer pizza todas las semanas', 'b': 'Comer sushi todas las semanas', 'category': 'Comida'},
    {'a': 'Vivir en la ciudad', 'b': 'Vivir en el campo', 'category': 'Futuro'},
    {'a': 'Besos apasionados cada manana', 'b': 'Abrazos largos cada noche', 'category': 'Romantico'},
    {'a': 'Una discusion honesta que duele', 'b': 'Una mentira piadosa que protege', 'category': 'Romantico'},
    {'a': 'Cocinar juntos todas las noches', 'b': 'Pedir comida y ver peliculas', 'category': 'Comida'},
    {'a': 'Un viaje espontaneo de fin de semana', 'b': 'Vacaciones perfectas de dos semanas', 'category': 'Viajes'},
    {'a': 'Que me escribas un poema cada dia', 'b': 'Que me cantes en publico', 'category': 'Divertido'},
    {'a': 'Tener el mismo sueno cada noche', 'b': 'Sonar contigo cuando quiera', 'category': 'Romantico'},
    {'a': 'Un fin de semana en la montana', 'b': 'Un fin de semana en la playa', 'category': 'Viajes'},
    {'a': 'Despertar con un beso cada manana', 'b': 'Dormir abrazados cada noche', 'category': 'Romantico'},
    {'a': 'Una cita en un concierto', 'b': 'Una cita en una obra de teatro', 'category': 'Divertido'},
    {'a': 'Comprar una casa juntos', 'b': 'Viajar por el mundo sin casa fija', 'category': 'Futuro'},
    {'a': 'Un masaje relajante de 30 min', 'b': 'Un baile sensual de 10 min', 'category': 'Romantico'},
    {'a': 'Recibir flores cada semana', 'b': 'Mensajes romanticos cada dia', 'category': 'Romantico'},
    {'a': 'Una cita sorpresa preparada por ti', 'b': 'Planear juntos cada detalle', 'category': 'Divertido'},
    {'a': 'Poder leer tu mente', 'b': 'Que puedas leer la mia', 'category': 'Futuro'},
    {'a': 'Un beso bajo la lluvia', 'b': 'Un abrazo frente a la chimenea', 'category': 'Romantico'},
    {'a': 'Hacer un album de fotos juntos', 'b': 'Escribir un diario de pareja', 'category': 'Romantico'},
    {'a': 'Bailar bajo la lluvia', 'b': 'Hacer un muneco de nieve juntos', 'category': 'Divertido'},
    {'a': 'Una cita en un globo aerostatico', 'b': 'Un paseo en barco al atardecer', 'category': 'Viajes'},
    {'a': 'Tener una cita en la azotea', 'b': 'Un picnic en el parque', 'category': 'Romantico'},
    {'a': 'Desayuno en la cama todos los dias', 'b': 'Cena a la luz de las velas', 'category': 'Comida'},
    {'a': 'Ver el atardecer juntos', 'b': 'Ver el amanecer juntos', 'category': 'Romantico'},
    {'a': 'Tener 3 hijos', 'b': 'Tener 3 mascotas', 'category': 'Futuro'},
    {'a': 'Aprender a bailar salsa juntos', 'b': 'Aprender a cocinar juntos', 'category': 'Divertido'},
    {'a': 'Vivir cerca de la familia', 'b': 'Vivir lejos pero viajar seguido', 'category': 'Futuro'},
    {'a': 'Compartir el mismo celular', 'b': 'Tener total privacidad', 'category': 'Personalizado'},
  ];

  List<Map<String, dynamic>> _allDilemmas = [];
  String _selectedCategory = 'Todas';
  int _currentIndex = 0;
  int _currentPlayer = 1;
  final List<int> _p1Choices = [];
  final List<int> _p2Choices = [];
  bool _gameOver = false;
  bool _showBoth = false;
  int? _lastP2Choice;

  StreamSubscription? _sub;
  List<Map<String, dynamic>> _customDilemmas = [];

  @override
  void initState() {
    super.initState();
    _sub = GameService().streamPrefer().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customDilemmas = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'id': d.id,
            'a': data['optionA'],
            'b': data['optionB'],
            'category': data['category'] ?? 'Personalizado',
            'custom': true,
          };
        }).toList();
      });
    });
    _startGame();
  }

  List<Map<String, dynamic>> _filteredDilemmas() {
    final combined = [
      ..._defaults.map((e) => Map<String, dynamic>.from(e)..['custom'] = false),
      ..._customDilemmas,
    ];
    if (_selectedCategory == 'Todas') return combined;
    return combined.where((d) => d['category'] == _selectedCategory).toList();
  }

  void _startGame() {
    final filtered = _filteredDilemmas();
    filtered.shuffle(Random());
    setState(() {
      _allDilemmas = filtered;
      _currentIndex = 0;
      _currentPlayer = 1;
      _p1Choices.clear();
      _p2Choices.clear();
      _gameOver = false;
      _showBoth = false;
      _lastP2Choice = null;
    });
  }

  void _pick(int choice) {
    if (_gameOver) return;
    final idx = _currentIndex;
    setState(() {
      if (_currentPlayer == 1) {
        _p1Choices.add(choice);
        _currentPlayer = 2;
      } else {
        _p2Choices.add(choice);
        _lastP2Choice = choice;
        if (idx >= _allDilemmas.length - 1) {
          _gameOver = true;
          _saveStats();
          _showResult();
        } else {
          setState(() {
            _showBoth = true;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() {
              _currentIndex++;
              _currentPlayer = 1;
              _showBoth = false;
              _lastP2Choice = null;
            });
          });
        }
      }
    });
  }

  double get _matchPercentage {
    if (_p1Choices.isEmpty) return 0;
    int matches = 0;
    for (int i = 0; i < _p1Choices.length; i++) {
      if (i < _p2Choices.length && _p1Choices[i] == _p2Choices[i]) matches++;
    }
    return (matches / _p1Choices.length) * 100;
  }

  void _saveStats() {
    GameService().saveGameStats('que_prefieres', {
      'matchPercentage': _matchPercentage,
      'total': _p1Choices.length,
      'matches': (_matchPercentage / 100 * _p1Choices.length).round(),
      'category': _selectedCategory,
    });
  }

  void _showResult() {
    final cs = Theme.of(context).colorScheme;
    final total = _p1Choices.length;
    final matches = (_matchPercentage / 100 * total).round();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Compatibilidad', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_matchPercentage.toStringAsFixed(0)}% de coincidencia',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: cs.secondary)),
            const SizedBox(height: 12),
            Text('$matches de $total respuestas coinciden',
                style: GoogleFonts.outfit(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _matchPercentage >= 70
                  ? 'Son muy compatibles!'
                  : _matchPercentage >= 40
                      ? 'Siguen conociendose'
                      : 'Tienen mucho que descubrir',
              style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _startGame();
            },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final aCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    String selectedCat = _categories[1];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Nuevo dilema', style: GoogleFonts.outfit()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: aCtrl,
                decoration: const InputDecoration(labelText: 'Opcion A', border: OutlineInputBorder()),
                style: GoogleFonts.outfit(),
              ),
              const SizedBox(height: 8),
              Text('O', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: bCtrl,
                decoration: const InputDecoration(labelText: 'Opcion B', border: OutlineInputBorder()),
                style: GoogleFonts.outfit(),
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
                if (aCtrl.text.trim().isEmpty || bCtrl.text.trim().isEmpty) return;
                await GameService().savePrefer({
                  'optionA': aCtrl.text.trim(),
                  'optionB': bCtrl.text.trim(),
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

  void _deleteDilemma(String id) {
    GameService().deletePrefer(id);
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
        title: Text('Que prefieres...', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
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
          if (_allDilemmas.isEmpty)
            Expanded(
              child: Center(
                child: Text('No hay dilemas para esta categoria',
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
                        Text('Jugador $_currentPlayer',
                            style: GoogleFonts.outfit(fontSize: 14, color: cs.secondary, fontWeight: FontWeight.bold)),
                        Text('${_p1Choices.length + 1} de ${_allDilemmas.length}',
                            style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Que prefieres...',
                      style: GoogleFonts.outfit(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OptionCard(
                          0,
                          _allDilemmas[_currentIndex]['a'] ?? '',
                          cs.primary,
                          cs.onSurface,
                          _gameOver || _currentPlayer == 2 && !_showBoth && _p1Choices.length > _p2Choices.length,
                          () => _pick(0),
                          _showBoth && _p1Choices.length > _currentIndex ? _p1Choices[_currentIndex] == 0 : null,
                          _showBoth && _p2Choices.length > _currentIndex ? _p2Choices[_currentIndex] == 0 : null,
                        ),
                        const SizedBox(height: 12),
                        Text('O', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: cs.secondary)),
                        const SizedBox(height: 12),
                        _OptionCard(
                          1,
                          _allDilemmas[_currentIndex]['b'] ?? '',
                          cs.secondary,
                          cs.onSurface,
                          _gameOver || _currentPlayer == 2 && !_showBoth && _p1Choices.length > _p2Choices.length,
                          () => _pick(1),
                          _showBoth && _p1Choices.length > _currentIndex ? _p1Choices[_currentIndex] == 1 : null,
                          _showBoth && _p2Choices.length > _currentIndex ? _p2Choices[_currentIndex] == 1 : null,
                        ),
                      ],
                    ),
                  ),
                  if (_showBoth && _lastP2Choice != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _p1Choices[_currentIndex] == _lastP2Choice
                            ? 'Coincidieron!'
                            : 'Respuestas diferentes!',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _p1Choices[_currentIndex] == _lastP2Choice ? Colors.green : Colors.red.shade400,
                        ),
                      ),
                    ),
                  if (_allDilemmas[_currentIndex]['custom'] == true)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDilemma(_allDilemmas[_currentIndex]['id']),
                    ),
                  if (_gameOver)
                    ElevatedButton(
                      onPressed: _showResult,
                      style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                      child: Text('Ver resultado', style: GoogleFonts.outfit(color: cs.onSurface)),
                    ),
                  const SizedBox(height: 16),
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

class _OptionCard extends StatelessWidget {
  final int index;
  final String text;
  final Color bg;
  final Color fg;
  final bool disabled;
  final VoidCallback onTap;
  final bool? p1Picked;
  final bool? p2Picked;

  const _OptionCard(this.index, this.text, this.bg, this.fg, this.disabled, this.onTap, this.p1Picked, this.p2Picked);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color borderColor = Colors.transparent;
    if (p1Picked == true && p2Picked == true) borderColor = Colors.green;
    else if (p1Picked == true && p2Picked == false) borderColor = Colors.orange;
    else if (p1Picked == false && p2Picked == true) borderColor = Colors.orange;
    else if (p1Picked == true) borderColor = cs.primary;
    else if (p2Picked == true) borderColor = cs.secondary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != Colors.transparent
                ? BorderSide(color: borderColor, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: GoogleFonts.outfit(color: fg, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            if (p1Picked != null || p2Picked != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (p1Picked != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('P1${p1Picked! ? ' ✓' : ' ✗'}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11)),
                    ),
                  if (p2Picked != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('P2${p2Picked! ? ' ✓' : ' ✗'}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
