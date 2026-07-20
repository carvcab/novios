import 'dart:math';
import 'package:home_widget/home_widget.dart';
import 'local_storage.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._();
  factory WidgetService() => _instance;
  WidgetService._();

  Future<void> init() async {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  Future<void> updateDistance(double? dist, bool isOnline) async {
    final distStr = dist != null ? '${dist.toStringAsFixed(1)} km' : '— km';
    final statusStr = isOnline ? '🟢 En línea' : '🔴 Desconectado';
    
    await HomeWidget.saveWidgetData('distance_text', distStr);
    await HomeWidget.saveWidgetData('distance_label', 'de distancia');
    await HomeWidget.saveWidgetData('distance_status', statusStr);
    
    try {
      await HomeWidget.updateWidget(
        name: 'DistanceWidget',
        androidName: 'com.novios.DistanceWidget',
      );
    } catch (_) {}
  }

  Future<void> updateAllWidgets() async {
    final ls = LocalStorage();
    final userName = ls.getUserName() ?? 'Tú';
    final partnerName = ls.getPartnerName() ?? 'Pareja';
    final annDate = ls.getAnniversaryDate();

    // 1. Countdown widget
    int days = 0;
    if (annDate != null) {
      final ann = DateTime.tryParse(annDate);
      if (ann != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final annDay = DateTime(ann.year, ann.month, ann.day);
        days = today.difference(annDay).inDays;
        final nextAnn = DateTime(
          now.month > ann.month || (now.month == ann.month && now.day > ann.day)
              ? now.year + 1
              : now.year,
          ann.month,
          ann.day,
        );
        final daysUntil = nextAnn.difference(today).inDays;

        await HomeWidget.saveWidgetData('countdown_days', days.toString());
        await HomeWidget.saveWidgetData('countdown_label', 'días juntos');
        await HomeWidget.saveWidgetData('countdown_names', '$userName ♥ $partnerName');
        await HomeWidget.saveWidgetData('countdown_until', '$daysUntil días');
      }
    }

    // 2. Love Quote widget
    final quotes = [
      'Eres lo mejor que me pasó',
      'Cada día a tu lado es especial',
      'Te amo más que ayer, menos que mañana',
      'Mi lugar favorito es a tu lado',
      'Contigo todo es mejor',
      'Eres mi razón para sonreír',
      'Nuestro amor es mi mayor aventura',
      'Tu sonrisa ilumina mis días',
      'Gracias por existir en mi vida',
      'Cada momento contigo es único',
    ];
    final quote = quotes[Random().nextInt(quotes.length)];
    await HomeWidget.saveWidgetData('quote_text', '"$quote"');
    await HomeWidget.saveWidgetData('quote_author', '- $userName');

    // 3. Notes widget
    final notes = ls.getLocalList('notes_list');
    if (notes.isNotEmpty) {
      final lastNote = notes.last;
      await HomeWidget.saveWidgetData(
          'note_title', (lastNote['title'] ?? 'Nota').toString());
      await HomeWidget.saveWidgetData(
          'note_text', (lastNote['content'] ?? '').toString());
      await HomeWidget.saveWidgetData(
          'note_date', (lastNote['date'] ?? '').toString());
    } else {
      await HomeWidget.saveWidgetData('note_title', 'Escribe una nota');
      await HomeWidget.saveWidgetData(
          'note_text', 'Toca para crear tu primera nota de amor');
      await HomeWidget.saveWidgetData('note_date', '');
    }

    // 4. Photo widget
    final photoPath = ls.getString('widget_photo_path') ?? '';
    final photoTitle = ls.getString('widget_photo_title') ?? 'Nuestro recuerdo 🌅';
    await HomeWidget.saveWidgetData('photo_path', photoPath);
    await HomeWidget.saveWidgetData('photo_title', photoTitle);

    // Trigger update for all widgets
    try {
      await HomeWidget.updateWidget(
        name: 'CountdownWidget',
        androidName: 'com.novios.CountdownWidget',
      );
      await HomeWidget.updateWidget(
        name: 'DistanceWidget',
        androidName: 'com.novios.DistanceWidget',
      );
      await HomeWidget.updateWidget(
        name: 'QuoteWidget',
        androidName: 'com.novios.QuoteWidget',
      );
      await HomeWidget.updateWidget(
        name: 'NotesWidget',
        androidName: 'com.novios.NotesWidget',
      );
      await HomeWidget.updateWidget(
        name: 'PhotoWidget',
        androidName: 'com.novios.PhotoWidget',
      );
      await HomeWidget.updateWidget(
        name: 'ActionsWidget',
        androidName: 'com.novios.ActionsWidget',
      );
    } catch (_) {}
  }

  static Future<void> backgroundCallback(Uri? uri) async {
    final service = WidgetService();
    await service.updateAllWidgets();
  }
}
