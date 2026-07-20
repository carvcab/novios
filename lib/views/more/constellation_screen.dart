import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';

class ConstellationScreen extends StatefulWidget {
  const ConstellationScreen({super.key});

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  String _selectedShape = 'heart'; // 'heart', 'infinity', 'stars', 'aries', 'taurus', etc.
  final List<Map<String, dynamic>> _customStars = []; // {'pos': Offset, 'name': String, 'dist': double}
  final List<Map<String, dynamic>> _backgroundStars = [];

  final List<String> _starNames = [
    'Estrella del Beso 💋',
    'Estrella del Abrazo 🫂',
    'Estrella de la Sonrisa 😊',
    'Estrella de la Promesa 🤝',
    'Estrella del Destino ✨',
    'Estrella de la Pasión 🔥',
    'Estrella de la Ternura 🧸',
    'Estrella del Futuro 🔮',
    'Estrella del Recuerdo 📸',
    'Estrella de la Eternidad ♾️',
  ];

  final Map<String, List<Offset>> _zodiacStars = {
    'aries': [
      const Offset(0.3, 0.4),
      const Offset(0.45, 0.35),
      const Offset(0.6, 0.42),
      const Offset(0.65, 0.48)
    ],
    'taurus': [
      const Offset(0.25, 0.25),
      const Offset(0.4, 0.4),
      const Offset(0.5, 0.45),
      const Offset(0.65, 0.42),
      const Offset(0.7, 0.3),
      const Offset(0.5, 0.55),
      const Offset(0.6, 0.68)
    ],
    'gemini': [
      const Offset(0.3, 0.25),
      const Offset(0.35, 0.45),
      const Offset(0.4, 0.65),
      const Offset(0.6, 0.28),
      const Offset(0.62, 0.48),
      const Offset(0.65, 0.68)
    ],
    'cancer': [
      const Offset(0.5, 0.45),
      const Offset(0.5, 0.3),
      const Offset(0.35, 0.55),
      const Offset(0.65, 0.58)
    ],
    'leo': [
      const Offset(0.3, 0.6),
      const Offset(0.45, 0.62),
      const Offset(0.6, 0.58),
      const Offset(0.65, 0.45),
      const Offset(0.58, 0.32),
      const Offset(0.48, 0.35),
      const Offset(0.45, 0.45),
      const Offset(0.35, 0.42)
    ],
    'virgo': [
      const Offset(0.3, 0.3),
      const Offset(0.4, 0.45),
      const Offset(0.5, 0.42),
      const Offset(0.58, 0.55),
      const Offset(0.7, 0.5),
      const Offset(0.5, 0.68),
      const Offset(0.35, 0.6),
      const Offset(0.45, 0.32)
    ],
    'libra': [
      const Offset(0.5, 0.25),
      const Offset(0.35, 0.45),
      const Offset(0.65, 0.45),
      const Offset(0.5, 0.65),
      const Offset(0.38, 0.62)
    ],
    'scorpio': [
      const Offset(0.3, 0.3),
      const Offset(0.4, 0.35),
      const Offset(0.5, 0.42),
      const Offset(0.48, 0.55),
      const Offset(0.42, 0.68),
      const Offset(0.48, 0.78),
      const Offset(0.58, 0.75),
      const Offset(0.65, 0.65)
    ],
    'sagittarius': [
      const Offset(0.35, 0.45),
      const Offset(0.48, 0.35),
      const Offset(0.6, 0.42),
      const Offset(0.62, 0.55),
      const Offset(0.5, 0.6),
      const Offset(0.38, 0.58)
    ],
    'capricorn': [
      const Offset(0.3, 0.35),
      const Offset(0.5, 0.32),
      const Offset(0.7, 0.42),
      const Offset(0.65, 0.6),
      const Offset(0.45, 0.58),
      const Offset(0.32, 0.52)
    ],
    'aquarius': [
      const Offset(0.25, 0.35),
      const Offset(0.38, 0.32),
      const Offset(0.42, 0.45),
      const Offset(0.55, 0.42),
      const Offset(0.62, 0.55),
      const Offset(0.72, 0.5),
      const Offset(0.58, 0.68)
    ],
    'pisces': [
      const Offset(0.25, 0.25),
      const Offset(0.35, 0.38),
      const Offset(0.45, 0.48),
      const Offset(0.55, 0.58),
      const Offset(0.68, 0.68),
      const Offset(0.75, 0.58),
      const Offset(0.65, 0.48),
      const Offset(0.5, 0.35)
    ],
  };

  final Map<String, List<List<int>>> _zodiacConnections = {
    'aries': [[0, 1], [1, 2], [2, 3]],
    'taurus': [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [5, 6]],
    'gemini': [[0, 1], [1, 2], [3, 4], [4, 5], [1, 4], [0, 3]],
    'cancer': [[0, 1], [0, 2], [0, 3]],
    'leo': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7]],
    'virgo': [[0, 1], [1, 2], [2, 3], [3, 4], [3, 5], [5, 6], [1, 6], [2, 7]],
    'libra': [[0, 1], [0, 2], [1, 3], [2, 3], [1, 4]],
    'scorpio': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7]],
    'sagittarius': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0], [1, 4], [0, 3]],
    'capricorn': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0], [1, 4]],
    'aquarius': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [4, 6]],
    'pisces': [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 2]],
  };

  @override
  void initState() {
    super.initState();
    // Animation Controller para titileo y nebulosas
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _generateBackgroundStars();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateBackgroundStars() {
    final rand = Random();
    for (int i = 0; i < 70; i++) {
      _backgroundStars.add({
        'x': rand.nextDouble(),
        'y': rand.nextDouble(),
        'size': rand.nextDouble() * 2.5 + 0.5,
        'phase': rand.nextDouble() * 2 * pi, // Fase inicial del titileo
        'speed': rand.nextDouble() * 2 + 1, // Velocidad del titileo
      });
    }
  }

  void _handleTap(TapUpDetails details, Size size) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final relativeOffset = Offset(
      localPosition.dx / size.width,
      localPosition.dy / size.height,
    );

    final rand = Random();
    final starName = _starNames[rand.nextInt(_starNames.length)];
    final lightYears = rand.nextDouble() * 10 + 1.5; // Distancia ficticia en años luz

    setState(() {
      if (_customStars.length > 25) _customStars.removeAt(0);
      _customStars.add({
        'pos': relativeOffset,
        'name': starName,
        'dist': lightYears,
      });
    });
  }

  void _showZodiacSelector() {
    final cs = Theme.of(context).colorScheme;
    final zodiacs = [
      {'id': 'aries', 'name': 'Aries ♈'},
      {'id': 'taurus', 'name': 'Tauro ♉'},
      {'id': 'gemini', 'name': 'Géminis ♊'},
      {'id': 'cancer', 'name': 'Cáncer ♋'},
      {'id': 'leo', 'name': 'Leo ♌'},
      {'id': 'virgo', 'name': 'Virgo ♍'},
      {'id': 'libra', 'name': 'Libra ♎'},
      {'id': 'scorpio', 'name': 'Escorpio ♏'},
      {'id': 'sagittarius', 'name': 'Sagitario ♐'},
      {'id': 'capricorn', 'name': 'Capricornio ♑'},
      {'id': 'aquarius', 'name': 'Acuario ♒'},
      {'id': 'pisces', 'name': 'Piscis ♓'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona un Signo del Zodiaco',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: zodiacs.length,
                  itemBuilder: (ctx, idx) {
                    final z = zodiacs[idx];
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedShape = z['id']!;
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        z['name']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getShapeTitle() {
    switch (_selectedShape) {
      case 'heart':
        return 'Constelación de Amor ❤️';
      case 'infinity':
        return 'Constelación de Eternidad ♾️';
      case 'stars':
        return 'Cielo Libre 🌌';
      default:
        return 'Zodiaco: ${_selectedShape.toUpperCase()} 🌟';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';
    final initialA = myName.isNotEmpty ? myName[0].toUpperCase() : 'Y';
    final initialB = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFF040615),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Mapa Astronómico',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // Canvas de Estrellas y Nebulosas animadas
              GestureDetector(
                onTapUp: (details) => _handleTap(details, size),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: size,
                      painter: _ConstellationPainter(
                        backgroundStars: _backgroundStars,
                        customStars: _customStars,
                        shape: _selectedShape,
                        time: _animationController.value,
                        primaryColor: cs.primary,
                        initials: '$initialA + $initialB',
                        zodiacStars: _zodiacStars,
                        zodiacConnections: _zodiacConnections,
                      ),
                    );
                  },
                ),
              ),

              // Indicador Superior de Constelación
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _getShapeTitle(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controles Inferiores
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Text(
                      'Toca en cualquier parte del cielo para colgar una estrella ✨',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F122B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShapeButton('heart', Icons.favorite_rounded, 'Amor'),
                          _buildShapeButton('infinity', Icons.all_inclusive_rounded, 'Eterno'),
                          ElevatedButton.icon(
                            onPressed: _showZodiacSelector,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedShape != 'heart' && _selectedShape != 'infinity' && _selectedShape != 'stars'
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                              foregroundColor: _selectedShape != 'heart' && _selectedShape != 'infinity' && _selectedShape != 'stars'
                                  ? const Color(0xFF040615)
                                  : Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.star_purple500_rounded, size: 14),
                            label: const Text('Zodiaco', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          _buildShapeButton('stars', Icons.refresh_rounded, 'Libre'),
                          if (_customStars.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() => _customStars.clear()),
                              tooltip: 'Limpiar cielo',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShapeButton(String shape, IconData icon, String label) {
    final isSelected = _selectedShape == shape;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedShape = shape),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
        foregroundColor: isSelected ? const Color(0xFF040615) : Colors.white70,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<Map<String, dynamic>> backgroundStars;
  final List<Map<String, dynamic>> customStars;
  final String shape;
  final double time;
  final Color primaryColor;
  final String initials;
  final Map<String, List<Offset>> zodiacStars;
  final Map<String, List<List<int>>> zodiacConnections;

  _ConstellationPainter({
    required this.backgroundStars,
    required this.customStars,
    required this.shape,
    required this.time,
    required this.primaryColor,
    required this.initials,
    required this.zodiacStars,
    required this.zodiacConnections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. DIBUJAR NEBULOSA ESPACIAL (GALAXY BACKDROP) ──
    final bgPaint = Paint()..color = const Color(0xFF040615);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Múltiples radial gradients simulando nubes estelares (nebulosas)
    final nebula1Center = Offset(size.width * 0.35, size.height * 0.4);
    final nebulaPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9C27B0).withValues(alpha: 0.12), // Violet nebula
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: nebula1Center, radius: size.width * 0.7));
    canvas.drawCircle(nebula1Center, size.width * 0.7, nebulaPaint1);

    final nebula2Center = Offset(size.width * 0.7, size.height * 0.6);
    final nebulaPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00BCD4).withValues(alpha: 0.10), // Cyan nebula
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: nebula2Center, radius: size.width * 0.6));
    canvas.drawCircle(nebula2Center, size.width * 0.6, nebulaPaint2);

    // ── 2. DIBUJAR RED DE COORDENADAS CELESTIALES ──
    final coordPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height * 0.45);

    // Círculos concéntricos del mapa celestial
    canvas.drawCircle(center, size.width * 0.2, coordPaint);
    canvas.drawCircle(center, size.width * 0.4, coordPaint);
    canvas.drawCircle(center, size.width * 0.6, coordPaint);

    // Líneas radiales (ejes)
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), coordPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), coordPaint);

    // ── 3. DIBUJAR ESTRELLAS DE FONDO CON TITILEO REALISTA ──
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in backgroundStars) {
      final sx = (star['x'] as double) * size.width;
      final sy = (star['y'] as double) * size.height;
      final phase = star['phase'] as double;
      final speed = star['speed'] as double;
      final sz = star['size'] as double;

      // Calcular opacidad en base al tiempo y fase para simular titileo individual
      final opacity = 0.2 + 0.8 * (0.5 + 0.5 * sin(time * 2 * pi * speed + phase));

      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(sx, sy), sz, starPaint);
    }

    // ── 4. DIBUJAR LA CONSTELACIÓN SELECCIONADA ──
    final constellationPoints = <Offset>[];
    final connections = <List<int>>[];

    if (shape == 'heart') {
      constellationPoints.addAll([
        const Offset(0.5, 0.45), // Centro
        const Offset(0.65, 0.32),
        const Offset(0.8, 0.4),
        const Offset(0.8, 0.58),
        const Offset(0.5, 0.8), // Abajo punta
        const Offset(0.2, 0.58),
        const Offset(0.2, 0.4),
        const Offset(0.35, 0.32),
      ]);
      connections.addAll([
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 0], [0, 4]
      ]);
    } else if (shape == 'infinity') {
      constellationPoints.addAll([
        const Offset(0.5, 0.55), // Centro cruz
        const Offset(0.65, 0.38),
        const Offset(0.8, 0.55),
        const Offset(0.65, 0.72),
        const Offset(0.35, 0.38),
        const Offset(0.2, 0.55),
        const Offset(0.35, 0.72),
      ]);
      connections.addAll([
        [0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [4, 5], [5, 6], [6, 0]
      ]);
    } else if (zodiacStars.containsKey(shape)) {
      constellationPoints.addAll(zodiacStars[shape]!);
      connections.addAll(zodiacConnections[shape]!);
    }

    // Parpadeo suave para las líneas principales de la constelación
    final neonAlpha = 0.3 + 0.15 * sin(time * 2 * pi * 2);
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: neonAlpha)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: neonAlpha * 0.3)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    if (constellationPoints.isNotEmpty) {
      for (final conn in connections) {
        if (conn[0] < constellationPoints.length && conn[1] < constellationPoints.length) {
          final p1 = Offset(
            constellationPoints[conn[0]].dx * size.width,
            constellationPoints[conn[0]].dy * size.height,
          );
          final p2 = Offset(
            constellationPoints[conn[1]].dx * size.width,
            constellationPoints[conn[1]].dy * size.height,
          );
          canvas.drawLine(p1, p2, glowPaint);
          canvas.drawLine(p1, p2, linePaint);
        }
      }

      // Dibujar estrellas en los nodos de la constelación
      final nodePaint = Paint()..color = Colors.white;
      final nodeGlow = Paint()..color = Colors.white.withValues(alpha: neonAlpha);
      for (final pt in constellationPoints) {
        final nodePos = Offset(pt.dx * size.width, pt.dy * size.height);
        canvas.drawCircle(nodePos, 8, nodeGlow);
        canvas.drawCircle(nodePos, 3, nodePaint);
      }

      // Mostrar Iniciales en el centro de las figuras geométricas románticas
      if (shape == 'heart' || shape == 'infinity') {
        final textPainter = TextPainter(
          text: TextSpan(
            text: initials,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(size.width / 2 - textPainter.width / 2, size.height * 0.55 - textPainter.height / 2),
        );
      }
    }

    // ── 5. DIBUJAR ESTRELLAS AGREGADAS POR EL USUARIO ──
    final userPaint = Paint()..color = Colors.cyanAccent;
    final userGlow = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.4);
    final userLine = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int i = 0; i < customStars.length; i++) {
      final star = customStars[i];
      final pos = Offset(star['pos'].dx * size.width, star['pos'].dy * size.height);
      final name = star['name'] as String;
      final dist = star['dist'] as double;

      canvas.drawCircle(pos, 7, userGlow);
      canvas.drawCircle(pos, 2.5, userPaint);

      // Dibujar etiqueta de texto de la estrella personalizada
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$name\n(${dist.toStringAsFixed(1)} AL)',
          style: GoogleFonts.outfit(
            color: Colors.cyanAccent.withValues(alpha: 0.7),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx + 8, pos.dy - 8),
      );

      // Conectar estrella agregada con la anterior
      if (i > 0) {
        final prevPos = Offset(customStars[i - 1]['pos'].dx * size.width, customStars[i - 1]['pos'].dy * size.height);
        canvas.drawLine(pos, prevPos, userLine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
