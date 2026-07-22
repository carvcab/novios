import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type; // 'chat', 'letter', 'voice', 'video', 'sticker', 'gift'
  
  // Special features
  final bool isDisappearing;
  final int disappearDurationSeconds; // e.g. 10 seconds, 60 seconds
  final DateTime? readTimestamp;
  
  final DateTime? scheduledTime; // For scheduled messages
  
  // Custom content fields
  final String? letterTitle;
  final String? voiceNotePath;
  final String? videoMessagePath;
  final String? mediaUrl; // Sticker path, GIF url, or sent photo
  final String? giftId; // If it's a virtual gift
  
  // Reply & Reaction features
  final String? replyToId; // ID of the message being replied to
  final String? replyToText; // Text preview of the replied message
  final String? replyToSenderId; // Sender of the replied message
  final Map<String, String>? reactions; // userId → emoji

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.isDisappearing = false,
    this.disappearDurationSeconds = 0,
    this.readTimestamp,
    this.scheduledTime,
    this.letterTitle,
    this.voiceNotePath,
    this.videoMessagePath,
    this.mediaUrl,
    this.giftId,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
    this.reactions,
  });

  bool get isVisible {
    if (scheduledTime != null) {
      return DateTime.now().isAfter(scheduledTime!);
    }
    return true;
  }

  bool get shouldBeDeleted {
    if (isDisappearing && readTimestamp != null) {
      final deleteTime = readTimestamp!.add(Duration(seconds: disappearDurationSeconds));
      return DateTime.now().isAfter(deleteTime);
    }
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'type': type,
      'isDisappearing': isDisappearing,
      'disappearDurationSeconds': disappearDurationSeconds,
      'readTimestamp': readTimestamp?.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'letterTitle': letterTitle,
      'voiceNotePath': voiceNotePath,
      'videoMessagePath': videoMessagePath,
      'mediaUrl': mediaUrl,
      'giftId': giftId,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'reactions': reactions,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp = DateTime.now();
    try {
      final ts = map['timestamp'];
      if (ts is String) {
        parsedTimestamp = DateTime.parse(ts);
      } else if (ts is Timestamp) {
        parsedTimestamp = ts.toDate();
      }
    } catch (_) {}

    DateTime? parsedReadTimestamp;
    try {
      final ts = map['readTimestamp'];
      if (ts is String) {
        parsedReadTimestamp = DateTime.parse(ts);
      } else if (ts is Timestamp) {
        parsedReadTimestamp = ts.toDate();
      }
    } catch (_) {}

    DateTime? parsedScheduledTime;
    try {
      final ts = map['scheduledTime'];
      if (ts is String) {
        parsedScheduledTime = DateTime.parse(ts);
      } else if (ts is Timestamp) {
        parsedScheduledTime = ts.toDate();
      }
    } catch (_) {}

    final rawReactions = map['reactions'];
    Map<String, String>? reactions;
    if (rawReactions is Map) {
      reactions = rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedTimestamp,
      type: map['type'] ?? 'chat',
      isDisappearing: map['isDisappearing'] ?? false,
      disappearDurationSeconds: map['disappearDurationSeconds'] ?? 0,
      readTimestamp: parsedReadTimestamp,
      scheduledTime: parsedScheduledTime,
      letterTitle: map['letterTitle'],
      voiceNotePath: map['voiceNotePath'],
      videoMessagePath: map['videoMessagePath'],
      mediaUrl: map['mediaUrl'],
      giftId: map['giftId'],
      replyToId: map['replyToId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      reactions: reactions,
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageModel.fromJson(String source) => MessageModel.fromMap(json.decode(source));

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    String? type,
    bool? isDisappearing,
    int? disappearDurationSeconds,
    DateTime? readTimestamp,
    DateTime? scheduledTime,
    String? letterTitle,
    String? voiceNotePath,
    String? videoMessagePath,
    String? mediaUrl,
    String? giftId,
    String? replyToId,
    String? replyToText,
    String? replyToSenderId,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isDisappearing: isDisappearing ?? this.isDisappearing,
      disappearDurationSeconds: disappearDurationSeconds ?? this.disappearDurationSeconds,
      readTimestamp: readTimestamp ?? this.readTimestamp,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      letterTitle: letterTitle ?? this.letterTitle,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      videoMessagePath: videoMessagePath ?? this.videoMessagePath,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      giftId: giftId ?? this.giftId,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      reactions: reactions ?? this.reactions,
    );
  }
}
