import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlannerModel {
  final String id;
  final String title;
  final String type;
  final String? description;
  final String? imageUrl;
  final bool doneTogether;
  final DateTime dateAdded;
  final String? suggestedBy;

  PlannerModel({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.imageUrl,
    this.doneTogether = false,
    DateTime? dateAdded,
    this.suggestedBy,
  }) : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type,
    'description': description,
    'imageUrl': imageUrl,
    'doneTogether': doneTogether,
    'dateAdded': dateAdded.toIso8601String(),
    'suggestedBy': suggestedBy,
  };

  factory PlannerModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDateAdded = DateTime.now();
    try {
      final val = map['dateAdded'];
      if (val is String) {
        parsedDateAdded = DateTime.parse(val);
      } else if (val is Timestamp) {
        parsedDateAdded = val.toDate();
      }
    } catch (_) {}

    return PlannerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'movie',
      description: map['description'],
      imageUrl: map['imageUrl'],
      doneTogether: map['doneTogether'] ?? false,
      dateAdded: parsedDateAdded,
      suggestedBy: map['suggestedBy'],
    );
  }

  String toJson() => json.encode(toMap());
  factory PlannerModel.fromJson(String s) => PlannerModel.fromMap(json.decode(s));
  PlannerModel copyWith({String? id, String? title, String? type, String? description, String? imageUrl, bool? doneTogether, DateTime? dateAdded, String? suggestedBy}) => PlannerModel(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    doneTogether: doneTogether ?? this.doneTogether,
    dateAdded: dateAdded ?? this.dateAdded,
    suggestedBy: suggestedBy ?? this.suggestedBy,
  );
}
