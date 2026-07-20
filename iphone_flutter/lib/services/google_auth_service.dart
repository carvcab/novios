import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage.dart';
import 'user_service.dart';

class GoogleAuthService extends ChangeNotifier {
  static final GoogleAuthService _instance = GoogleAuthService._();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._();

  static const _currentEmailKey = 'google_current_email';

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _currentEmail;
  bool _isSignedIn = false;
  String? _displayName;
  String? _photoUrl;

  String? get currentEmail => _currentEmail;
  
  bool get isSignedIn {
    final user = FirebaseAuth.instance.currentUser;
    return _isSignedIn && user != null && !user.isAnonymous;
  }
  
  String? get displayName => _displayName;
  String? get photoUrl => _photoUrl;

  String? get partnerName => LocalStorage().getPartnerName();

  bool get setupComplete {
    if (_currentEmail == null) return false;
    return LocalStorage().getBool('setup_complete_$_currentEmail');
  }

  Future<void> markSetupComplete() async {
    await LocalStorage().setBool('setup_complete_${_currentEmail ?? ''}', true);
    notifyListeners();
  }

  void init() {
    final user = FirebaseAuth.instance.currentUser;
    _currentEmail = LocalStorage().getString(_currentEmailKey);
    if (user != null && !user.isAnonymous && _currentEmail != null) {
      _isSignedIn = true;
      _displayName = LocalStorage().getUserName() ?? user.displayName;
      _photoUrl = LocalStorage().getString('google_photo_url') ?? user.photoURL;
    } else {
      _isSignedIn = false;
      _currentEmail = null;
      _displayName = null;
      _photoUrl = null;
    }
  }

  Future<String?> signIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'canceled';

      final email = googleUser.email;
      final name = googleUser.displayName ?? email.split('@').first;
      final photoUrl = googleUser.photoUrl ?? '';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null && auth.currentUser!.isAnonymous) {
        await auth.currentUser!.linkWithCredential(credential);
      } else {
        await auth.signInWithCredential(credential);
      }

      _currentEmail = email;
      _displayName = name;
      _photoUrl = photoUrl;
      _isSignedIn = true;

      await LocalStorage().setString(_currentEmailKey, email);
      await LocalStorage().setString('user_name', name);
      await LocalStorage().setString('google_photo_url', photoUrl);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? email;
      await LocalStorage().setString('user_id', uid);
      
      // Auto-complete setup since we already have Google credentials
      await LocalStorage().setBool('setup_complete_$email', true);

      // Read Firestore — with UID migration from previous anonymous UID
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        // If doc doesn't exist under current UID, try to migrate from old UID via email mapping
        if (!doc.exists) {
          try {
            final emailDoc = await FirebaseFirestore.instance.collection('user_emails').doc(email).get();
            if (emailDoc.exists) {
              final oldUid = emailDoc.get('uid') as String?;
              if (oldUid != null && oldUid != uid) {
                final oldDoc = await FirebaseFirestore.instance.collection('users').doc(oldUid).get();
                if (oldDoc.exists) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).set(
                    oldDoc.data()!,
                    SetOptions(merge: true),
                  );
                  final oldData = oldDoc.data()!;
                  if (oldData['partnerUid'] != null) {
                    await FirebaseFirestore.instance.collection('users').doc(oldData['partnerUid'] as String).set(
                      {'partnerUid': uid},
                      SetOptions(merge: true),
                    );
                  }
                  doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                }
              }
            }
          } catch (_) {}
        }

        if (doc.exists) {
          final data = doc.data()!;

          final remoteName = data['name'] as String?;
          if (remoteName != null && remoteName.isNotEmpty) {
            await LocalStorage().setString('user_name', remoteName);
            _displayName = remoteName;
          }

          final bday = data['birthdayDate'];
          if (bday != null) {
            String bdayStr;
            if (bday is Timestamp) {
              final dt = bday.toDate();
              bdayStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } else {
              bdayStr = bday.toString();
            }
            await LocalStorage().setString('birthday_date', bdayStr);
            await LocalStorage().setString('dob', bdayStr);
          }

          final remoteUsername = data['username'] as String?;
          if (remoteUsername != null && remoteUsername.isNotEmpty) {
            await LocalStorage().setString('username', remoteUsername);
          } else {
            final displayName = LocalStorage().getUserName() ?? name;
            await LocalStorage().setString('username', displayName.toLowerCase().replaceAll(RegExp(r'\s+'), ''));
          }

          final remoteCoupleId = data['coupleId'] as String?;
          if (remoteCoupleId != null && remoteCoupleId.isNotEmpty) {
            await LocalStorage().setString('couple_id', remoteCoupleId);
          }
          final remotePartnerUid = data['partnerUid'] as String?;
          if (remotePartnerUid != null && remotePartnerUid.isNotEmpty) {
            await LocalStorage().setString('partner_uid', remotePartnerUid);
          }
          final remotePartnerName = data['partnerName'] as String?;
          if (remotePartnerName != null && remotePartnerName.isNotEmpty) {
            await LocalStorage().setString('partner_name', remotePartnerName);
          }

          // Mark everything complete — this user already has a profile
          await LocalStorage().setBool('setup_complete_$email', true);
          await LocalStorage().setBool('has_firestore_profile', true);
        }
      } catch (e) {
        debugPrint("Firestore restore error (non-fatal): $e");
      }

      notifyListeners();
      try { await UserService().syncFromFirestore(); } catch (_) {}
      try { UserService().startListening(); } catch (_) {}
      return null;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return 'error';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    _isSignedIn = false;
    _currentEmail = null;
    _displayName = null;
    _photoUrl = null;
    await LocalStorage().remove(_currentEmailKey);
    await LocalStorage().remove('user_name');
    await LocalStorage().remove('user_id');
    await LocalStorage().remove('partner_name');
    await LocalStorage().remove('google_photo_url');
    notifyListeners();
  }
}
