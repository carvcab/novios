import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String title;
  final String category; // 'travel', 'home', 'pet', 'car', 'marriage', 'kids', 'saving', 'other'
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final DateTime dateCreated;
  final DateTime? dateCompleted;
  final String notes;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.dateCreated,
    this.dateCompleted,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'progress': progress,
      'isCompleted': isCompleted,
      'dateCreated': dateCreated.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
      'notes': notes,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        return DateTime.tryParse(val);
      } else if (val is Timestamp) {
        return val.toDate();
      }
      return null;
    }

    return GoalModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'other',
      progress: map['progress']?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] ?? false,
      dateCreated: parseDate(map['dateCreated']) ?? DateTime.now(),
      dateCompleted: parseDate(map['dateCompleted']),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GoalModel.fromJson(String source) => GoalModel.fromMap(json.decode(source));

  GoalModel copyWith({
    String? id,
    String? title,
    String? category,
    double? progress,
    bool? isCompleted,
    DateTime? dateCreated,
    DateTime? dateCompleted,
    String? notes,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      dateCreated: dateCreated ?? this.dateCreated,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      notes: notes ?? this.notes,
    );
  }
}
