import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool autoDetected;
  final DateTime createdAt;
  final bool notifyOnEnter;
  final bool notifyOnExit;

  ZoneModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.autoDetected = false,
    DateTime? createdAt,
    this.notifyOnEnter = true,
    this.notifyOnExit = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'autoDetected': autoDetected,
    'createdAt': createdAt.toIso8601String(),
    'notifyOnEnter': notifyOnEnter,
    'notifyOnExit': notifyOnExit,
  };

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt = DateTime.now();
    try {
      final val = map['createdAt'];
      if (val is String) {
        parsedCreatedAt = DateTime.parse(val);
      } else if (val is Timestamp) {
        parsedCreatedAt = val.toDate();
      }
    } catch (_) {}

    return ZoneModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusMeters: (map['radiusMeters'] ?? 200).toDouble(),
      autoDetected: map['autoDetected'] ?? false,
      createdAt: parsedCreatedAt,
      notifyOnEnter: map['notifyOnEnter'] ?? true,
      notifyOnExit: map['notifyOnExit'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory ZoneModel.fromJson(String s) => ZoneModel.fromMap(json.decode(s));

  ZoneModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? autoDetected,
    DateTime? createdAt,
    bool? notifyOnEnter,
    bool? notifyOnExit,
  }) => ZoneModel(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    autoDetected: autoDetected ?? this.autoDetected,
    createdAt: createdAt ?? this.createdAt,
    notifyOnEnter: notifyOnEnter ?? this.notifyOnEnter,
    notifyOnExit: notifyOnExit ?? this.notifyOnExit,
  );
}
