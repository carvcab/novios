import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../models/memory_model.dart';
import '../../models/goal_model.dart';
import '../../models/capsule_model.dart';
import '../../widgets/firestore_image.dart';

class RelationshipBookScreen extends StatefulWidget {
  const RelationshipBookScreen({super.key});

  @override
  State<RelationshipBookScreen> createState() => _RelationshipBookScreenState();
}

class _RelationshipBookScreenState extends State<RelationshipBookScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isBookOpened = false;

  List<MemoryModel> _memories = [];
  List<GoalModel> _goals = [];
  List<CapsuleModel> _capsules = [];
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    try {
      final firebase = FirebaseService();
      final memList = await firebase.streamMemories().first;
      final goalList = await firebase.streamGoals().first;
      final capList = await firebase.streamCapsules().first;
      if (mounted) {
        setState(() {
          _memories = memList;
          _goals = goalList;
          _capsules = capList;
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _exportAsTXT() async {
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    final buf = StringBuffer();
    buf.writeln('========================================');
    buf.writeln('    LIBRO DE NUESTRA HISTORIA DE AMOR   ');
    buf.writeln('      $myName ♥ $partnerName');
    buf.writeln('========================================');
    buf.writeln('Generado el: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buf.writeln('');
    buf.writeln('--- PRÓLOGO ---');
    buf.writeln('Dos almas que decidieron caminar juntas, coleccionando momentos,');
    buf.writeln('superando retos y construyendo un amor a prueba del tiempo.');
    buf.writeln('');
    buf.writeln('--- NUESTROS RECUERDOS (${_memories.length}) ---');
    for (final m in _memories) {
      buf.writeln('• [${m.date.day}/${m.date.month}/${m.date.year}] - ${m.title}');
      if (m.description.isNotEmpty) buf.writeln('  "${m.description}"');
    }
    buf.writeln('');
    buf.writeln('--- NUESTRAS METAS (${_goals.length}) ---');
    for (final g in _goals) {
      final status = (g.progress >= 1.0) ? '[COMPLETADA]' : '[EN PROGRESO ${(g.progress * 100).round()}%]';
      buf.writeln('• $status ${g.title}');
    }
    buf.writeln('');
    buf.writeln('--- CÁPSULAS DEL TIEMPO (${_capsules.length}) ---');
    for (final c in _capsules) {
      final lockStatus = c.unlockDate.isAfter(DateTime.now()) ? 'CERRADA' : 'ABIERTA';
      buf.writeln('• [$lockStatus] ${c.title} - Se abre el: ${c.unlockDate.day}/${c.unlockDate.month}/${c.unlockDate.year}');
    }
    buf.writeln('');
    buf.writeln('========================================');
    buf.writeln('      Generado con amor por Novios App  ');
    buf.writeln('========================================');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/libro_relacion_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buf.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en: ${file.path} 📄'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _getDaysTogether() {
    final ann = DateTime.tryParse(LocalStorage().getAnniversaryDate() ?? '');
    if (ann == null) return 0;
    return DateTime.now().difference(ann).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    if (_loadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Libro de la Relación', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Exportar a TXT',
            onPressed: _exportAsTXT,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceContainerLowest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: !_isBookOpened ? _buildCoverPage(cs, myName, partnerName) : _buildBookViewer(cs, myName, partnerName),
      ),
    );
  }

  // PORTADA DEL LIBRO
  Widget _buildCoverPage(ColorScheme cs, String myName, String partnerName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: const Color(0xFF5C1D24), // Elegant burgundy color
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Gold frame outline
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFD4AF37),
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                'NUESTRA HISTORIA',
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFD4AF37),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'DE AMOR',
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFD4AF37),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                width: 120,
                color: const Color(0xFFD4AF37),
              ),
              const SizedBox(height: 32),
              Text(
                '$myName ♥ $partnerName',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Aniversario: ${LocalStorage().getAnniversaryDate() ?? 'No asignado'}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isBookOpened = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF5C1D24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(
                  'ABRIR LIBRO',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // VISOR DE LIBRO INTERACTIVO
  Widget _buildBookViewer(ColorScheme cs, String myName, String partnerName) {
    final pageCount = 5;

    return Column(
      children: [
        // Indicador de páginas en el tope
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isBookOpened = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Cerrar'),
              ),
              Text(
                'Página ${_currentPage + 1} de $pageCount',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ],
          ),
        ),
        // Lector de páginas
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            children: [
              _buildProloguePage(cs, myName, partnerName),
              _buildMemoriesPage(cs),
              _buildGoalsPage(cs),
              _buildCapsulesPage(cs),
              _buildEpiloguePage(cs, myName, partnerName),
            ],
          ),
        ),
        // Controles de navegación en la parte inferior
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : null,
              ),
              Row(
                children: List.generate(pageCount, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == i ? cs.primary : cs.primary.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: _currentPage < pageCount - 1
                    ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaperPage({required String title, required Widget child, required ColorScheme cs}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7), // Warm paper-like background
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6DFD3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde superior decorativo estilo libro
            Container(height: 6, color: cs.primary.withValues(alpha: 0.7)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6DFD3)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // PÁGINA 1: PRÓLOGO
  Widget _buildProloguePage(ColorScheme cs, String myName, String partnerName) {
    final daysTogether = _getDaysTogether();

    return _buildPaperPage(
      title: 'Prólogo',
      cs: cs,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.auto_stories_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 24),
            Text(
              'A las almas de',
              style: GoogleFonts.cinzel(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '$myName & $partnerName',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Esta es la recopilación escrita de su camino juntos. Una bitácora que contiene cada risa compartida, cada paso dado de la mano y cada promesa enterrada en el tiempo.',
              style: GoogleFonts.caveat(fontSize: 20, color: Colors.grey.shade800, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Han transcurrido más de $daysTogether días de complicidad amorosa, de momentos grabados no solo en esta aplicación sino en sus corazones.',
              style: GoogleFonts.caveat(fontSize: 20, color: Colors.grey.shade800, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              '“El amor no consiste en mirarse el uno al otro, sino en mirar juntos en la misma dirección.”',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // PÁGINA 2: RECUERDOS (DIARIO)
  Widget _buildMemoriesPage(ColorScheme cs) {
    if (_memories.isEmpty) {
      return _buildPaperPage(
        title: 'Álbum de Recuerdos',
        cs: cs,
        child: const Center(
          child: Text('No hay recuerdos grabados en el libro todavía.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
      );
    }

    return _buildPaperPage(
      title: 'Álbum de Recuerdos',
      cs: cs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _memories.length,
        itemBuilder: (ctx, i) {
          final m = _memories[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    Text(
                      '${m.date.day}/${m.date.month}/${m.date.year}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (m.mediaPaths.isNotEmpty) ...[
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: FirestoreImage(path: m.mediaPaths.first, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  m.description,
                  style: GoogleFonts.caveat(fontSize: 18, color: Colors.grey.shade700, height: 1.2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // PÁGINA 3: METAS (SUEÑOS)
  Widget _buildGoalsPage(ColorScheme cs) {
    if (_goals.isEmpty) {
      return _buildPaperPage(
        title: 'Nuestros Sueños',
        cs: cs,
        child: const Center(
          child: Text('No hay metas ingresadas en el libro todavía.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
      );
    }

    return _buildPaperPage(
      title: 'Nuestros Sueños',
      cs: cs,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _goals.length,
        itemBuilder: (ctx, i) {
          final g = _goals[i];
          final completed = g.progress >= 1.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  completed ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: completed ? Colors.green : cs.primary.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    g.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: completed ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                ),
                if (!completed)
                  Text(
                    '${(g.progress * 100).round()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // PÁGINA 4: CÁPSULAS DEL TIEMPO
  Widget _buildCapsulesPage(ColorScheme cs) {
    if (_capsules.isEmpty) {
      return _buildPaperPage(
        title: 'Mensajes del Futuro',
        cs: cs,
        child: const Center(
          child: Text('No hay cápsulas del tiempo enterradas todavía.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
      );
    }

    return _buildPaperPage(
      title: 'Cápsulas del Tiempo',
      cs: cs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _capsules.length,
        itemBuilder: (ctx, i) {
          final c = _capsules[i];
          final locked = c.unlockDate.isAfter(DateTime.now());

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6DFD3)),
            ),
            child: Row(
              children: [
                Icon(
                  locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: locked ? Colors.amber : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Desenterrar el: ${c.unlockDate.day}/${c.unlockDate.month}/${c.unlockDate.year}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // PÁGINA 5: EPÍLOGO Y FIRMA
  Widget _buildEpiloguePage(ColorScheme cs, String myName, String partnerName) {
    return _buildPaperPage(
      title: 'Epílogo',
      cs: cs,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 20),
            Text(
              'A las futuras páginas de nuestra historia...',
              style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Que esta historia que hoy escribimos sea eterna. Que sigamos llenando hojas virtuales e historias reales con el mismo amor y emoción que el primer día.',
              style: GoogleFonts.caveat(fontSize: 20, color: Colors.grey.shade800, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      myName,
                      style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                    Container(height: 1, width: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    const Text('Firma', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      partnerName,
                      style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                    ),
                    Container(height: 1, width: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    const Text('Firma', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
