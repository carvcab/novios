import Foundation
import AVFoundation
import Combine

public class AudioService: ObservableObject {
    public static let shared = AudioService()
    
    @Published public var isRecording: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    
    private var timer: Timer?
    
    private init() {}
    
    public func startRecording() {
        self.isRecording = true
        self.recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.recordingDuration += 1.0
        }
    }
    
    public func stopRecording() -> String? {
        timer?.invalidate()
        timer = nil
        self.isRecording = false
        // Return dummy URL / path
        return "voice_note_\(Int(Date().timeIntervalSince1970)).m4a"
    }
    
    public func playAudio(url: String) {
        self.isPlaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isPlaying = false
        }
    }
}
