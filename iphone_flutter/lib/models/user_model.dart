import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? partnerId;
  final String? partnerName;
  final DateTime? anniversaryDate;
  final String mood;
  final String moodReason;
  final DateTime? lastMoodUpdate;
  final String emotionalWeather;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;
  final String themeName; // pink, black, red, blue, custom
  final String customPrimaryColor; // Hex string
  final String customSecondaryColor; // Hex string
  final int lovePoints;
  final String? profilePhotoUrl;
  final String? partnerProfilePhotoUrl;
  final DateTime? lastSeenDate;
  final String? coupleId;
  final String? partnerUid;
  final DateTime? metDate;
  final DateTime? datingDate;
  final DateTime? weddingDate;
  final DateTime? birthdayDate;
  final bool isOnline;
  final String currentScreen;
  final int batteryLevel;
  final String currentApp;
  final Map<String, dynamic>? lastNotification;
  final double speed;

  UserModel({
    required this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    this.anniversaryDate,
    this.metDate,
    this.datingDate,
    this.weddingDate,
    this.birthdayDate,
    required this.mood,
    required this.moodReason,
    this.lastMoodUpdate,
    required this.emotionalWeather,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    required this.themeName,
    required this.customPrimaryColor,
    required this.customSecondaryColor,
    required this.lovePoints,
    this.profilePhotoUrl,
    this.partnerProfilePhotoUrl,
    this.lastSeenDate,
    this.coupleId,
    this.partnerUid,
    this.isOnline = false,
    this.currentScreen = '',
    this.batteryLevel = -1,
    this.currentApp = '',
    this.lastNotification,
    this.speed = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'anniversaryDate': anniversaryDate?.toIso8601String(),
      'metDate': metDate?.toIso8601String(),
      'datingDate': datingDate?.toIso8601String(),
      'weddingDate': weddingDate?.toIso8601String(),
      'birthdayDate': birthdayDate?.toIso8601String(),
      'mood': mood,
      'moodReason': moodReason,
      'lastMoodUpdate': lastMoodUpdate?.toIso8601String(),
      'emotionalWeather': emotionalWeather,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'themeName': themeName,
      'customPrimaryColor': customPrimaryColor,
      'customSecondaryColor': customSecondaryColor,
      'lovePoints': lovePoints,
      'profilePhotoUrl': profilePhotoUrl,
      'partnerProfilePhotoUrl': partnerProfilePhotoUrl,
      'lastSeenDate': lastSeenDate?.toIso8601String(),
      'coupleId': coupleId,
      'partnerUid': partnerUid,
      'isOnline': isOnline,
      'currentScreen': currentScreen,
      'batteryLevel': batteryLevel,
      'currentApp': currentApp,
      'lastNotification': lastNotification,
      'speed': speed,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        return DateTime.tryParse(val);
      } else if (val is Timestamp) {
        return val.toDate();
      }
      return null;
    }

    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      partnerId: map['partnerId'],
      partnerName: map['partnerName'],
      anniversaryDate: parseDate(map['anniversaryDate']),
      metDate: parseDate(map['metDate']),
      datingDate: parseDate(map['datingDate']),
      weddingDate: parseDate(map['weddingDate']),
      birthdayDate: parseDate(map['birthdayDate']),
      mood: map['mood'] ?? 'Feliz',
      moodReason: map['moodReason'] ?? '',
      lastMoodUpdate: parseDate(map['lastMoodUpdate']),
      emotionalWeather: map['emotionalWeather'] ?? 'Soleado',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      lastLocationUpdate: parseDate(map['lastLocationUpdate']),
      themeName: map['themeName'] ?? 'pink',
      customPrimaryColor: map['customPrimaryColor'] ?? '#FF69B4',
      customSecondaryColor: map['customSecondaryColor'] ?? '#FFC0CB',
      lovePoints: map['lovePoints'] ?? 0,
      profilePhotoUrl: map['profilePhotoUrl'],
      partnerProfilePhotoUrl: map['partnerProfilePhotoUrl'],
      lastSeenDate: parseDate(map['lastSeenDate']),
      coupleId: map['coupleId'],
      partnerUid: map['partnerUid'],
      isOnline: map['isOnline'] ?? false,
      currentScreen: map['currentScreen'] ?? '',
      batteryLevel: map['batteryLevel'] ?? -1,
      currentApp: map['currentApp'] ?? '',
      lastNotification: map['lastNotification'],
      speed: (map['speed'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));

  UserModel copyWith({
    String? id,
    String? name,
    String? partnerId,
    String? partnerName,
    DateTime? anniversaryDate,
    DateTime? metDate,
    DateTime? datingDate,
    DateTime? weddingDate,
    DateTime? birthdayDate,
    String? mood,
    String? moodReason,
    DateTime? lastMoodUpdate,
    String? emotionalWeather,
    double? latitude,
    double? longitude,
    DateTime? lastLocationUpdate,
    String? themeName,
    String? customPrimaryColor,
    String? customSecondaryColor,
    int? lovePoints,
    String? profilePhotoUrl,
    String? partnerProfilePhotoUrl,
    DateTime? lastSeenDate,
    String? coupleId,
    String? partnerUid,
    bool? isOnline,
    String? currentScreen,
    int? batteryLevel,
    String? currentApp,
    Map<String, dynamic>? lastNotification,
    double? speed,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      metDate: metDate ?? this.metDate,
      datingDate: datingDate ?? this.datingDate,
      weddingDate: weddingDate ?? this.weddingDate,
      birthdayDate: birthdayDate ?? this.birthdayDate,
      mood: mood ?? this.mood,
      moodReason: moodReason ?? this.moodReason,
      lastMoodUpdate: lastMoodUpdate ?? this.lastMoodUpdate,
      emotionalWeather: emotionalWeather ?? this.emotionalWeather,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      themeName: themeName ?? this.themeName,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
      lovePoints: lovePoints ?? this.lovePoints,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      partnerProfilePhotoUrl: partnerProfilePhotoUrl ?? this.partnerProfilePhotoUrl,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      coupleId: coupleId ?? this.coupleId,
      partnerUid: partnerUid ?? this.partnerUid,
      isOnline: isOnline ?? this.isOnline,
      currentScreen: currentScreen ?? this.currentScreen,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      currentApp: currentApp ?? this.currentApp,
      lastNotification: lastNotification ?? this.lastNotification,
      speed: speed ?? this.speed,
    );
  }
}
