import 'local_storage.dart';
import 'google_auth_service.dart';
import 'user_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._();
  factory ProfileService() => _instance;
  ProfileService._();

  String? get myName {
    return GoogleAuthService().displayName ?? LocalStorage().getUserName() ?? 'Yo';
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

  String? get myPhotoUrl => GoogleAuthService().photoUrl;

  Future<void> init() async {
  }

  Future<void> logout() async {
    await GoogleAuthService().signOut();
  }
}
