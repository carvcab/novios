import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TruthDareCustomScreen extends StatefulWidget {
  const TruthDareCustomScreen({super.key});

  @override
  State<TruthDareCustomScreen> createState() => _TruthDareCustomScreenState();
}

class _TruthDareCustomScreenState extends State<TruthDareCustomScreen> with SingleTickerProviderStateMixin {
  final _coupleId = ['joeBcVn2o1hfXfU68rWNOyAZIqt2', 'Dd1X94n3gxg7leWtMtnLlxDVHcm2'].join('_');
  late TabController _tabCtrl;

  static const _categories = ['Verdad', 'Reto', 'Video Reto', 'Picante'];

  static const _defaults = {
    'Verdad': [
      'Cual fue tu primera impresion de mi?',
      'Que es lo que mas te gusta de mi fisicamente?',
      'Cual es tu fantasia secreta?',
      'Has pensado en casarte conmigo?',
      'Que es lo que mas te gusta de nuestra relacion?',
      'Cual es tu recuerdo favorito juntos?',
      'Que miedo tienes en la relacion?',
      'Que fue lo que te hizo enamorarte?',
      'Cual es tu lugar favorito para tener citas?',
      'Que cancion te recuerda a nosotros?',
      'Cual es tu mayor arrepentimiento en el amor?',
      'Que es lo que mas valoras de mi?',
    ],
    'Reto': [
      'Da un beso de 10 segundos',
      'Baila una cancion romantica con tu pareja',
      'Di algo dulce al oido de tu pareja',
      'Abraza a tu pareja por 30 segundos',
      'Masajea los hombros de tu pareja',
      'Cantale una cancion a tu pareja',
      'Hazle cosquillas a tu pareja por 15 segundos',
      'Toma una foto juntos ahora mismo',
      'Escribe un poema corto para tu pareja',
      'Prepara algo rico para comer juntos',
      'Di 3 cosas que amas de tu pareja',
      'Besa la frente de tu pareja',
    ],
    'Video Reto': [
      'Graben un video bailando juntos',
      'Graben un mensaje de amor de 15 segundos',
      'Hagan un video de una cita rapida',
      'Graben un tutorial de como se dan besos',
      'Hagan un video cantando una cancion juntos',
      'Graben una confesion de amor',
      'Hagan un video contando un chiste malo',
      'Graben un time-lapse de algo juntos',
      'Hagan un video de ellos disfrazados',
      'Graben un video haciendo una promesa de pareja',
      'Hagan un video de su dia perfecto juntos',
      'Graben un video de reto de risa',
    ],
    'Picante': [
      'Describe tu parte favorita del cuerpo de tu pareja',
      'Que es lo que mas te prende de tu pareja?',
      'Donde te gustaria hacerlo que nunca hemos hecho?',
      'Cual es tu posicion favorita?',
      'Que fantasia te gustaria cumplir?',
      'Susurra algo picante al oido de tu pareja',
      'Besa el cuello de tu pareja lentamente',
      'Que es lo mas atrevido que has hecho?',
      'Que parte de tu cuerpo te gusta que bese?',
      'Cual es tu recuerdo mas intimo favorito?',
      'Que te gustaria probar en la intimidad?',
      'Di algo que te guste como besa tu pareja',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  CollectionReference _catRef(String cat) =>
      FirebaseFirestore.instance.collection('couples').doc(_coupleId).collection('customTD').doc(cat).collection('items');

  void _addItem(String cat) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Agregar a $cat', style: GoogleFonts.outfit()),
        content: TextField(controller: c, decoration: InputDecoration(hintText: 'Nueva entrada para $cat')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                _catRef(cat).add({'text': c.text.trim()});
              }
              Navigator.pop(ctx);
            },
            child: Text('Agregar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentCat = _categories[_tabCtrl.index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Verdad o Reto', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: cs.onSurface,
          labelColor: cs.onSurface,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _categories.map((cat) => _CategoryView(cat, _catRef(cat), _defaults[cat]!, cs, () => _addItem(cat))).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(currentCat),
        backgroundColor: cs.primary,
        child: Icon(Icons.add, color: cs.onSurface),
      ),
    );
  }
}

class _CategoryView extends StatefulWidget {
  final String category;
  final CollectionReference ref;
  final List<String> defaults;
  final ColorScheme cs;
  final VoidCallback onAdd;
  const _CategoryView(this.category, this.ref, this.defaults, this.cs, this.onAdd);

  @override
  State<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<_CategoryView> {
  String? _currentText;
  bool _revealed = false;
  List<String> _firestoreItems = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAndPick();
  }

  Future<void> _loadAndPick() async {
    final snap = await widget.ref.get();
    setState(() {
      _firestoreItems = snap.docs.map((d) => (d.data() as Map<String, dynamic>)['text'] as String).toList();
      _loaded = true;
      _pickRandom();
    });
  }

  void _pickRandom() {
    final all = [...widget.defaults, ..._firestoreItems];
    if (all.isEmpty) return;
    setState(() {
      _currentText = all[Random().nextInt(all.length)];
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _revealed ? null : () => setState(() => _revealed = true),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _revealed ? _RevealedCard(_currentText, widget.cs, widget.category) : _HiddenCard(widget.category, widget.cs),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _pickRandom,
            style: ElevatedButton.styleFrom(backgroundColor: widget.cs.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: Text(_revealed ? 'Siguiente' : 'Saltar', style: GoogleFonts.outfit(color: widget.cs.onSurface, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          Text('Toca la tarjeta para revelar', style: GoogleFonts.outfit(color: widget.cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          Text('${_firestoreItems.length + widget.defaults.length} entradas', style: GoogleFonts.outfit(color: widget.cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _HiddenCard extends StatelessWidget {
  final String category;
  final ColorScheme cs;
  const _HiddenCard(this.category, this.cs);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('hidden_$category'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.primary.withValues(alpha: 0.8),
      elevation: 6,
      child: Container(
        width: double.infinity,
        height: 260,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            Text(category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Toca para revelar', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _RevealedCard extends StatelessWidget {
  final String? text;
  final ColorScheme cs;
  final String category;
  const _RevealedCard(this.text, this.cs, this.category);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('revealed_$text'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      elevation: 6,
      child: Container(
        width: double.infinity,
        height: 260,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            text != null
                ? Text(text!, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center)
                : Text('No hay entradas', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
