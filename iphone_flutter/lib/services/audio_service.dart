import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  double _volume = 0.5;

  bool get isMusicPlaying => _isMusicPlaying;
  double get volume => _volume;
  Stream<Duration> get onPositionChanged => _bgPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _bgPlayer.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _bgPlayer.onPlayerStateChanged;
  Stream<void> get onPlayerComplete => _bgPlayer.onPlayerComplete;

  Future<void> playBackgroundMusic(String urlOrAsset, {bool isAsset = false, bool loop = false}) async {
    try {
      if (loop) {
        await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _bgPlayer.setReleaseMode(ReleaseMode.release);
      }
      await _bgPlayer.setVolume(_volume);
      if (isAsset) {
        await _bgPlayer.play(AssetSource(urlOrAsset));
      } else {
        await _bgPlayer.play(UrlSource(urlOrAsset));
      }
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint("Error playing background music: $e");
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _bgPlayer.stop();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint("Error stopping background music: $e");
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgPlayer.pause();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint("Error pausing background music: $e");
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      await _bgPlayer.resume();
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint("Error resuming background music: $e");
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _bgPlayer.seek(position);
    } catch (e) {
      debugPrint("Error seeking: $e");
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol;
    try {
      await _bgPlayer.setVolume(vol);
    } catch (e) {
      debugPrint("Error setting volume: $e");
    }
  }

  Future<void> playHeartbeat() async {
    try {
      await _effectPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/1393/1393-200.wav'));
    } catch (e) {
      debugPrint("Error playing heartbeat effect: $e");
    }
  }
}
