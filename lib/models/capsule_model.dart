import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleModel {
  final String id;
  final String title;
  final String description;
  final DateTime unlockDate;
  final List<String> mediaPaths; // Files or photos saved
  final String letterText;
  final bool isOpened;
  final DateTime dateCreated;

  CapsuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockDate,
    this.mediaPaths = const [],
    this.letterText = '',
    this.isOpened = false,
    required this.dateCreated,
  });

  bool get isUnlockable {
    return DateTime.now().isAfter(unlockDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'unlockDate': unlockDate.toIso8601String(),
      'mediaPaths': mediaPaths,
      'letterText': letterText,
      'isOpened': isOpened,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory CapsuleModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        return DateTime.tryParse(val);
      } else if (val is Timestamp) {
        return val.toDate();
      }
      return null;
    }

    return CapsuleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      unlockDate: parseDate(map['unlockDate']) ?? DateTime.now(),
      mediaPaths: List<String>.from(map['mediaPaths'] ?? []),
      letterText: map['letterText'] ?? '',
      isOpened: map['isOpened'] ?? false,
      dateCreated: parseDate(map['dateCreated']) ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CapsuleModel.fromJson(String source) => CapsuleModel.fromMap(json.decode(source));

  CapsuleModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? unlockDate,
    List<String>? mediaPaths,
    String? letterText,
    bool? isOpened,
    DateTime? dateCreated,
  }) {
    return CapsuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      unlockDate: unlockDate ?? this.unlockDate,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      letterText: letterText ?? this.letterText,
      isOpened: isOpened ?? this.isOpened,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
