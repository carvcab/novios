import Foundation
import Combine

public enum ScreenShareStatus: String, Codable {
    case idle
    case requesting
    case streaming
    case ended
}

public class ScreenShareService: ObservableObject {
    public static let shared = ScreenShareService()
    
    @Published public var status: ScreenShareStatus = .idle
    @Published public var isPartnerSharing: Bool = false
    @Published public var partnerStreamTitle: String?
    @Published public var isHeartbeatSynced: Bool = false
    @Published public var currentBpm: Int = 72
    
    private var heartbeatTimer: Timer?
    
    private init() {
        startHeartbeatSimulation()
    }
    
    public func requestScreenShare() {
        self.status = .requesting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.status = .streaming
        }
    }
    
    public func stopScreenShare() {
        self.status = .ended
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.status = .idle
        }
    }
    
    public func toggleHeartbeatSync() {
        self.isHeartbeatSynced.toggle()
    }
    
    private func startHeartbeatSimulation() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            if self.isHeartbeatSynced {
                self.currentBpm = Int.random(in: 68...82)
            }
        }
    }
}
