import SwiftUI
import AVFoundation

public struct ChatBubbleView: View {
    public let message: MessageModel
    public var isFromMe: Bool
    public var onReply: () -> Void
    public var onReact: (String) -> Void

    @State private var loadedImage: UIImage?
    @State private var isLoadingMedia = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isAppeared = false

    private let reactions = ["❤️", "😘", "😂", "😮", "😢", "🔥", "💖", "👍", "👎"]

    public var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 8) {
                if isFromMe { Spacer(minLength: 50) }
                if !isFromMe { partnerAvatar }

                messageContent
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background {
                        if isFromMe { ThemeManager.shared.neonGlowGradient.opacity(0.92) }
                        else { Color(.systemGray5) }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(bubbleBorder)
                    .shadow(color: bubbleShadowColor, radius: 8, y: 4)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromMe ? .trailing : .leading)
                    .modifier(BubbleAppearModifier(isAppeared: $isAppeared, isFromMe: isFromMe))

                if !isFromMe { Spacer(minLength: 50) }
                if isFromMe { Spacer(minLength: 40) }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button { onReact("❤️") } label: { Label("❤️ Me gusta", systemImage: "heart") }
            Button { onReact("😂") } label: { Label("😂 Jaja", systemImage: "face.smiling") }
            Button { onReact("😢") } label: { Label("😢 Triste", systemImage: "hand.raised") }
            Divider()
            Button { onReply() } label: { Label("Responder", systemImage: "arrowshape.turn.up.left") }
        }
        .onAppear { loadMediaIfNeeded() }
        .task(id: message.id) { loadMediaIfNeeded() }
    }

    private var partnerAvatar: some View {
        Circle()
            .fill(ThemeManager.shared.primaryPink.opacity(0.1))
            .frame(width: 28, height: 28)
            .overlay(Image(systemName: "person.fill").font(.system(size: 11)).foregroundColor(ThemeManager.shared.primaryPink.opacity(0.5)))
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
    }

    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let replyText = message.replyToText {
                replyPreview(text: replyText)
            }
            if message.type == .voice {
                voiceContent
            } else if message.type == .image || message.type == .video {
                mediaContent
            } else {
                Text(message.text ?? "")
                    .font(.system(size: 15, weight: isSpecialType ? .semibold : .regular))
                    .foregroundColor(isFromMe ? .white : .primary).lineSpacing(4)
            }
            if let reactions = message.reactions, !reactions.isEmpty {
                reactionRow
            }
            timestampRow
                .padding(.top, 1)
        }
    }

    private var isSpecialType: Bool {
        message.type == .kiss || message.type == .hug || message.type == .touch
    }

    private func replyPreview(text: String) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(ThemeManager.shared.primaryPink).frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(isFromSender ? "Ella/Él" : "Tú")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isFromMe ? .white.opacity(0.7) : ThemeManager.shared.primaryPink)
                Text(text).font(.system(size: 11))
                    .foregroundColor(isFromMe ? .white.opacity(0.6) : .primary.opacity(0.6)).lineLimit(1)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(replyBg).clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var isFromSender: Bool {
        message.replyToSenderId == message.senderId
    }

    private var replyBg: Color {
        isFromMe ? Color.white.opacity(0.1) : Color(.systemBackground).opacity(0.4)
    }

    private var timestampRow: some View {
        HStack(spacing: 5) {
            Text(message.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(isFromMe ? .white.opacity(0.7) : .primary.opacity(0.45))
            if isFromMe {
                Image(systemName: message.readTimestamp != nil ? "heart.fill" : "heart")
                    .font(.system(size: 10))
                    .foregroundColor(message.readTimestamp != nil ? .white : .white.opacity(0.4))
            }
        }
    }

    private var reactionRow: some View {
        HStack(spacing: 2) {
            ForEach(Array(message.reactions!.values), id: \.self) { emoji in
                Text(emoji).font(.system(size: 12))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.ultraThinMaterial.opacity(0.8)).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.3))
            }
        }
    }

    private var voiceContent: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isPlaying ? ThemeManager.shared.primaryPink.opacity(0.2) : Color.white.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 13))
                    .foregroundColor(isFromMe ? .white : ThemeManager.shared.primaryPink)
            }
            .onTapGesture { togglePlay() }
            VStack(alignment: .leading, spacing: 1) {
                Text("Nota de voz").font(.system(size: 12, weight: .semibold)).foregroundColor(isFromMe ? .white : .primary)
                if isPlaying {
                    Text("Reproduciendo...").font(.system(size: 10))
                        .foregroundColor(isFromMe ? .white.opacity(0.6) : .primary.opacity(0.4))
                }
            }
        }
        .padding(2)
    }

    private var mediaContent: some View {
        VStack(spacing: 4) {
            if let img = loadedImage {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(maxWidth: 200, maxHeight: 200).cornerRadius(12).clipped()
            } else if isLoadingMedia {
                ProgressView().frame(width: 180, height: 180)
            } else {
                Image(systemName: "photo.fill").font(.system(size: 28))
                    .foregroundColor(isFromMe ? .white.opacity(0.5) : .secondary.opacity(0.3))
                    .frame(width: 180, height: 150)
                    .background(isFromMe ? Color.white.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .onTapGesture { loadMediaIfNeeded() }
            }
        }
    }

    private var bubbleBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(isFromMe ? Color.white.opacity(0.12) : Color.white.opacity(0.6), lineWidth: 0.6)
    }

    private var bubbleShadowColor: Color {
        isFromMe ? ThemeManager.shared.primaryPink.opacity(0.12) : .black.opacity(0.04)
    }

    private func togglePlay() {
        if isPlaying { audioPlayer?.stop(); isPlaying = false }
        else if let player = audioPlayer { player.currentTime = 0; player.play(); isPlaying = true }
        else { loadAndPlayAudio() }
    }

    private func loadAndPlayAudio() {
        guard let url = message.mediaUrl, url.hasPrefix("firestore://") else { return }
        Task {
            let path = url.replacingOccurrences(of: "firestore://", with: "")
            guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
                  let fields = doc["fields"] as? [String: Any],
                  let b64 = (fields["data"] as? [String: Any])?["stringValue"] as? String,
                  let data = Data(base64Encoded: b64) else { return }
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try? AVAudioSession.sharedInstance().setActive(true)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("audio_\(message.id).m4a")
            try? data.write(to: tempURL)
            if let player = try? AVAudioPlayer(contentsOf: tempURL) {
                audioPlayer = player
                player.numberOfLoops = 0
                player.play()
                await MainActor.run { isPlaying = true }
                while player.isPlaying { try? await Task.sleep(nanoseconds: 100_000_000) }
                await MainActor.run { isPlaying = false }
            }
        }
    }

    private func loadMediaIfNeeded(retrying: Bool = false) {
        guard let url = message.mediaUrl, url.hasPrefix("firestore://") else { return }
        guard message.type == .image, loadedImage == nil, !isLoadingMedia else { return }
        isLoadingMedia = true
        Task {
            let path = url.replacingOccurrences(of: "firestore://", with: "")
            if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
               let fields = doc["fields"] as? [String: Any],
               let b64 = (fields["data"] as? [String: Any])?["stringValue"] as? String,
               let data = Data(base64Encoded: b64),
               let image = UIImage(data: data) {
                await MainActor.run { loadedImage = image; isLoadingMedia = false }
            } else if !retrying {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { isLoadingMedia = false }
                loadMediaIfNeeded(retrying: true)
            } else {
                await MainActor.run { isLoadingMedia = false }
            }
        }
    }
}

private struct BubbleAppearModifier: ViewModifier {
    @Binding var isAppeared: Bool
    let isFromMe: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAppeared ? 1 : (isFromMe ? 0.85 : 0.92))
            .opacity(isAppeared ? 1 : 0)
            .offset(x: isAppeared ? 0 : (isFromMe ? 15 : -15))
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.04)) { isAppeared = true }
            }
    }
}
