import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage.dart';
import 'couple_service.dart';

class AiMemory {
  String key;
  String value;
  String category;
  DateTime updatedAt;

  AiMemory({
    required this.key,
    required this.value,
    required this.category,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'category': category,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AiMemory.fromJson(Map<String, dynamic> json) => AiMemory(
    key: json['key'] as String,
    value: json['value'] as String,
    category: json['category'] as String,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class AiMemoryService extends ChangeNotifier {
  static final AiMemoryService _instance = AiMemoryService._();
  factory AiMemoryService() => _instance;
  AiMemoryService._();

  final List<AiMemory> _memories = [];
  bool _loaded = false;

  List<AiMemory> get memories => List.unmodifiable(_memories);
  bool get isLoaded => _loaded;

  // Memoria predefinida de la pareja
  static const _defaults = {
    'nombres': 'ambos',
    'reaccion': 'carinosa',
  };

  Future<void> load() async {
    if (_loaded) return;
    final cached = LocalStorage().getString('ai_memories');
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        _memories.addAll(list.map((e) => AiMemory.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    // Cargar desde Firestore
    try {
      final doc = await CoupleService().ref.collection('ai').doc('memoria').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        for (final entry in data.entries) {
          if (entry.value is Map) {
            final m = AiMemory(
              key: entry.key,
              value: entry.value['value'] as String? ?? '',
              category: entry.value['category'] as String? ?? 'general',
            );
            _memories.add(m);
          }
        }
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMemory(String key, String value, {String category = 'general'}) async {
    _memories.removeWhere((m) => m.key == key);
    _memories.add(AiMemory(key: key, value: value, category: category));
    _saveToLocal();
    // Sync to Firestore
    try {
      await CoupleService().ref.collection('ai').doc('memoria').set({
        key: {'value': value, 'category': category, 'updatedAt': DateTime.now().toIso8601String()},
      }, SetOptions(merge: true));
    } catch (_) {}
    notifyListeners();
  }

  String? getMemory(String key) {
    try {
      return _memories.firstWhere((m) => m.key == key).value;
    } catch (_) {
      return null;
    }
  }

  String buildContextPrompt() {
    final buf = StringBuffer();
    buf.writeln('Informacion de la pareja:');
    for (final m in _memories) {
      buf.writeln('- ${m.key}: ${m.value}');
    }
    return buf.toString();
  }

  void _saveToLocal() {
    final json = jsonEncode(_memories.map((m) => m.toJson()).toList());
    LocalStorage().setString('ai_memories', json);
  }
}
