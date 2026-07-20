import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage.dart';
import 'auth_service.dart';
import 'user_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;
  ProfileService._();

  String? get myName {
    return LocalStorage().getUserName() ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Yo';
  }

  String? get partnerName {
    return UserService().partnerName ?? LocalStorage().getPartnerName() ?? 'Mi pareja';
  }

  String get coupleDisplay {
    final me = myName;
    final partner = partnerName;
    if (me != null && partner != null) return '$me & $partner';
    if (me != null) return me;
    if (partner != null) return partner;
    return 'EverUs';
  }

  String? get myPhotoUrl => FirebaseAuth.instance.currentUser?.photoURL;

  Future<void> init() async {
  }

  Future<void> logout() async {
    await AuthService().signOut();
  }
}
