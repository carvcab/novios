import Foundation
import Combine

public class UserService: ObservableObject {
    public static let shared = UserService()

    @Published public var partnerUser: UserModel?

    public init() {
        loadPartnerFromDefaults()
    }

    public func loadPartnerFromDefaults() {
        let defaults = UserDefaults.standard
        let uid = CoupleService.shared.partnerUID
        let name = CoupleService.shared.partnerName
        partnerUser = UserModel(id: uid, email: "", displayName: name, username: name.lowercased(), partnerUid: AuthService.shared.currentUser?.id)
    }
}
