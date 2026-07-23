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
        let uid = CoupleService.shared.partnerUid
        let name = CoupleService.shared.partnerName
        partnerUser = UserModel(id: uid, nombre: name, correo: "", parejaId: CoupleService.coupleId)
    }
}
