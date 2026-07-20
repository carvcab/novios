import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String type;
  final List<String> photos;
  final DateTime dateAdded;
  final bool visited;

  PlaceModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.type = 'visited',
    this.photos = const [],
    DateTime? dateAdded,
    this.visited = true,
  }) : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'type': type,
    'photos': photos,
    'dateAdded': dateAdded.toIso8601String(),
    'visited': visited,
  };

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDateAdded = DateTime.now();
    try {
      final val = map['dateAdded'];
      if (val is String) {
        parsedDateAdded = DateTime.parse(val);
      } else if (val is Timestamp) {
        parsedDateAdded = val.toDate();
      }
    } catch (_) {}

    return PlaceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'visited',
      photos: List<String>.from(map['photos'] ?? []),
      dateAdded: parsedDateAdded,
      visited: map['visited'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory PlaceModel.fromJson(String s) => PlaceModel.fromMap(json.decode(s));
  PlaceModel copyWith({String? id, String? name, String? description, double? latitude, double? longitude, String? type, List<String>? photos, DateTime? dateAdded, bool? visited}) => PlaceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    type: type ?? this.type,
    photos: photos ?? this.photos,
    dateAdded: dateAdded ?? this.dateAdded,
    visited: visited ?? this.visited,
  );
}
