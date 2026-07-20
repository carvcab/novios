import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class JournalModel {
  final String id;
  final String dateKey; // format YYYY-MM-DD
  final String authorId;
  final String daySummary; // Cómo estuvo el día
  final String missedReason; // Qué extrañaron
  final String happyMoment; // Qué los hizo felices
  final String lessonLearned; // Qué aprendieron
  final String? photoPath; // Foto del día
  final DateTime timestamp;

  JournalModel({
    required this.id,
    required this.dateKey,
    required this.authorId,
    required this.daySummary,
    required this.missedReason,
    required this.happyMoment,
    required this.lessonLearned,
    this.photoPath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateKey': dateKey,
      'authorId': authorId,
      'daySummary': daySummary,
      'missedReason': missedReason,
      'happyMoment': happyMoment,
      'lessonLearned': lessonLearned,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp = DateTime.now();
    try {
      final ts = map['timestamp'];
      if (ts is String) {
        parsedTimestamp = DateTime.parse(ts);
      } else if (ts is Timestamp) {
        parsedTimestamp = ts.toDate();
      }
    } catch (_) {}

    return JournalModel(
      id: map['id'] ?? '',
      dateKey: map['dateKey'] ?? '',
      authorId: map['authorId'] ?? '',
      daySummary: map['daySummary'] ?? '',
      missedReason: map['missedReason'] ?? '',
      happyMoment: map['happyMoment'] ?? '',
      lessonLearned: map['lessonLearned'] ?? '',
      photoPath: map['photoPath'],
      timestamp: parsedTimestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory JournalModel.fromJson(String source) => JournalModel.fromMap(json.decode(source));

  JournalModel copyWith({
    String? id,
    String? dateKey,
    String? authorId,
    String? daySummary,
    String? missedReason,
    String? happyMoment,
    String? lessonLearned,
    String? photoPath,
    DateTime? timestamp,
  }) {
    return JournalModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      authorId: authorId ?? this.authorId,
      daySummary: daySummary ?? this.daySummary,
      missedReason: missedReason ?? this.missedReason,
      happyMoment: happyMoment ?? this.happyMoment,
      lessonLearned: lessonLearned ?? this.lessonLearned,
      photoPath: photoPath ?? this.photoPath,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
