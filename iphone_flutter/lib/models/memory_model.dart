import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'photo', 'video', 'audio', 'concert_ticket', 'movie_ticket', 'chat_screenshot', 'general'
  final List<String> mediaPaths; // Local paths or URLs of attachments
  final bool isFavorite;
  
  // Associated Song
  final String? songTitle;
  final String? songArtist;
  final String? songSpotifyUrl;
  
  // Associated Location
  final String? locationName;
  final double? latitude;
  final double? longitude;

  // Decoration Options
  final String? decorStyle; // 'standard', 'polaroid', 'romantic', 'vintage', 'ticket'
  final List<String>? decorStickers; // Sticker IDs overlayed
  final String? decorFrameColor; // Hex string

  MemoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.mediaPaths = const [],
    this.isFavorite = false,
    this.songTitle,
    this.songArtist,
    this.songSpotifyUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.decorStyle = 'standard',
    this.decorStickers = const [],
    this.decorFrameColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'mediaPaths': mediaPaths,
      'isFavorite': isFavorite,
      'songTitle': songTitle,
      'songArtist': songArtist,
      'songSpotifyUrl': songSpotifyUrl,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'decorStyle': decorStyle,
      'decorStickers': decorStickers,
      'decorFrameColor': decorFrameColor,
    };
  }

  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    try {
      final d = map['date'];
      if (d is String) {
        parsedDate = DateTime.parse(d);
      } else if (d is Timestamp) {
        parsedDate = d.toDate();
      }
    } catch (_) {}

    return MemoryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parsedDate,
      type: map['type'] ?? 'general',
      mediaPaths: List<String>.from(map['mediaPaths'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      songTitle: map['songTitle'],
      songArtist: map['songArtist'],
      songSpotifyUrl: map['songSpotifyUrl'],
      locationName: map['locationName'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      decorStyle: map['decorStyle'] ?? 'standard',
      decorStickers: List<String>.from(map['decorStickers'] ?? []),
      decorFrameColor: map['decorFrameColor'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MemoryModel.fromJson(String source) => MemoryModel.fromMap(json.decode(source));

  MemoryModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    List<String>? mediaPaths,
    bool? isFavorite,
    String? songTitle,
    String? songArtist,
    String? songSpotifyUrl,
    String? locationName,
    double? latitude,
    double? longitude,
    String? decorStyle,
    List<String>? decorStickers,
    String? decorFrameColor,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      isFavorite: isFavorite ?? this.isFavorite,
      songTitle: songTitle ?? this.songTitle,
      songArtist: songArtist ?? this.songArtist,
      songSpotifyUrl: songSpotifyUrl ?? this.songSpotifyUrl,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      decorStyle: decorStyle ?? this.decorStyle,
      decorStickers: decorStickers ?? this.decorStickers,
      decorFrameColor: decorFrameColor ?? this.decorFrameColor,
    );
  }
}
