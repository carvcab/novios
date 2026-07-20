import Foundation
import AVFoundation
import Combine

public class AudioService: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    public static let shared = AudioService()
    
    @Published public var isRecording: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    private override init() {
        super.init()
    }
    
    public func startRecording() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.beginRecordingSession()
            }
        }
    }
    
    private func beginRecordingSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = docPath.appendingPathComponent("voice_note_\(Int(Date().timeIntervalSince1970)).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.isRecording = true
            self.recordingDuration = 0
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1.0
            }
        } catch {
            print("Error al iniciar grabación: \(error.localizedDescription)")
            self.isRecording = false
        }
    }
    
    public func stopRecording() -> String? {
        timer?.invalidate()
        timer = nil
        self.isRecording = false
        
        audioRecorder?.stop()
        let path = audioRecorder?.url.path
        audioRecorder = nil
        return path
    }
    
    public func playAudio(url: String) {
        let fileURL: URL
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            guard let remoteURL = URL(string: url) else { return }
            fileURL = remoteURL
        } else {
            fileURL = URL(fileURLWithPath: url)
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            self.isPlaying = true
        } catch {
            print("Error al reproducir audio: \(error.localizedDescription)")
            self.isPlaying = false
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
