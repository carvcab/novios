import SwiftUI
import AVFoundation

public struct ChatBubbleView: View {
    public let message: MessageModel
    public var isFromMe: Bool
    public var onReply: () -> Void
    public var onReact: (String) -> Void
    public var onTapReply: ((String) -> Void)?

    @State private var loadedImage: UIImage?
    @State private var isLoadingMedia = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isAppeared = true
    @State private var showImageViewer = false

    private let reactions = ["❤️", "😘", "😂", "😮", "😢", "🔥", "💖", "👍", "👎"]

    public var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if isFromMe { Spacer(minLength: 55) }
            if !isFromMe { partnerAvatar }

            messageContent
                .padding(.horizontal, 13).padding(.vertical, 10)
                .background(bubbleBackground)
                .clipShape(bubbleShape)
                .overlay(bubbleBorder)
                .overlay(bubbleGlass)
                .shadow(color: shadowColor, radius: 4, y: 2)
                .frame(maxWidth: isFromMe ? UIScreen.main.bounds.width * 0.82 : UIScreen.main.bounds.width * 0.72, alignment: isFromMe ? .trailing : .leading)
                .modifier(BubbleAppearModifier(isAppeared: $isAppeared, isFromMe: isFromMe))

            if !isFromMe { Spacer(minLength: 55) }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let img = loadedImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Button {
                        showImageViewer = false
                    } label: {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                }
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

    private var theme: ThemeManager { ThemeManager.shared }

    private var bubbleBackground: Color {
        isFromMe ? theme.myBubbleBackground : theme.partnerBubbleBackground
    }

    private var bubbleGlass: some View {
        Group {
            if isFromMe {
                bubbleShape
                    .fill(LinearGradient(gradient: Gradient(colors: [
                        Color.white.opacity(0.35),
                        Color.clear,
                        Color.white.opacity(0.12)
                    ]), startPoint: .top, endPoint: .bottom))
            }
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        isFromMe
            ? UnevenRoundedRectangle(cornerRadii: .init(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18), style: .continuous)
            : UnevenRoundedRectangle(cornerRadii: .init(topLeading: 18, bottomLeading: 4, bottomTrailing: 18, topTrailing: 18), style: .continuous)
    }

    private var shadowColor: Color {
        isFromMe ? theme.myBubbleShadow : .black.opacity(0.04)
    }

    private var partnerAvatar: some View {
        Circle()
            .fill(ThemeManager.shared.primaryPink.opacity(0.1))
            .frame(width: 28, height: 28)
            .overlay(Image(systemName: "person.fill").appFont(size: 11).foregroundColor(ThemeManager.shared.primaryPink.opacity(0.5)))
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
                    .appFont(size: 15, weight: isSpecialType ? .semibold : .regular)
                    .foregroundColor(isFromMe ? theme.myBubbleText : (theme.isDarkMode ? .white.opacity(0.8) : Color(.darkGray))).lineSpacing(4)
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
                Text(message.replyToSenderId == nil ? "" : "En respuesta")
                    .appFont(size: 8, weight: .semibold)
                    .foregroundColor(isFromMe ? .white.opacity(0.6) : ThemeManager.shared.primaryPink.opacity(0.8))
                Text(text).appFont(size: 11)
                    .foregroundColor(isFromMe ? .white.opacity(0.5) : .primary.opacity(0.5)).lineLimit(2)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(replyBg).clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            if let replyId = message.replyToId {
                onTapReply?(replyId)
            }
        }
    }

    private var replyBg: Color {
        isFromMe ? Color.white.opacity(0.2) : Color(.systemBackground).opacity(0.4)
    }

    private var timestampRow: some View {
        HStack(spacing: 4) {
            Text(message.timestamp, style: .time)
                .appFont(size: 10, weight: .light)
                .foregroundColor(isFromMe ? .white.opacity(0.65) : .primary.opacity(0.45))
            if isFromMe {
                Image(systemName: message.readTimestamp != nil ? "heart.fill" : "heart")
                    .appFont(size: 8)
                    .foregroundColor(message.readTimestamp != nil ? theme.myBubbleHeart : .white.opacity(0.4))
            }
        }
    }

    private var reactionRow: some View {
        HStack(spacing: 3) {
            ForEach(Array(Set(message.reactions!.values)), id: \.self) { emoji in
                Text(emoji).appFont(size: 14)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(isFromMe ? Color.white.opacity(0.15) : Color(.systemGray5).opacity(0.5))
                    .clipShape(Capsule())
            }
        }
    }

    private var voiceContent: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isPlaying ? (isFromMe ? Color.white.opacity(0.25) : ThemeManager.shared.primaryPink.opacity(0.15)) : Color.white.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .appFont(size: 13)
                    .foregroundColor(isFromMe ? .white : (isPlaying ? ThemeManager.shared.primaryPink : .gray))
            }
            .onTapGesture { togglePlay() }
            VStack(alignment: .leading, spacing: 1) {
                Text("Nota de voz").appFont(size: 12, weight: .semibold).foregroundColor(isFromMe ? .white : (theme.isDarkMode ? .white.opacity(0.8) : Color(.darkGray)))
                if isPlaying {
                    Text("Reproduciendo...").appFont(size: 10)
                        .foregroundColor(isFromMe ? .white.opacity(0.7) : .gray)
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
                    .onTapGesture { showImageViewer = true }
            } else if isLoadingMedia {
                ProgressView().frame(width: 180, height: 180)
            } else {
                Image(systemName: "photo.fill").appFont(size: 28)
                    .foregroundColor(isFromMe ? .white.opacity(0.5) : .secondary.opacity(0.3))
                    .frame(width: 180, height: 150)
                    .background(isFromMe ? Color.white.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .onTapGesture { loadMediaIfNeeded() }
            }
        }
    }

    @ViewBuilder
    private var bubbleBorder: some View {
        if isFromMe {
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18), style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.6)
        } else {
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 18, bottomLeading: 4, bottomTrailing: 18, topTrailing: 18), style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        }
    }

    private func togglePlay() {
        if isPlaying { audioPlayer?.stop(); isPlaying = false }
        else if let player = audioPlayer { player.currentTime = 0; player.play(); isPlaying = true }
        else { loadAndPlayAudio() }
    }

    private func loadAndPlayAudio() {
        guard let urlStr = message.mediaUrl, !urlStr.isEmpty else { return }
        Task {
            var audioData: Data? = nil
            if urlStr.hasPrefix("firestore://") {
                let path = urlStr.replacingOccurrences(of: "firestore://", with: "")
                if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
                   let fields = doc["fields"] as? [String: Any],
                   let rawB64 = (fields["data"] as? [String: Any])?["stringValue"] as? String {
                    let cleanB64 = rawB64.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: " ", with: "")
                    audioData = Data(base64Encoded: cleanB64, options: .ignoreUnknownCharacters)
                }
            } else if let httpURL = URL(string: urlStr), urlStr.hasPrefix("http") {
                audioData = try? (await URLSession.shared.data(from: httpURL)).0
            } else {
                audioData = Data(base64Encoded: urlStr, options: .ignoreUnknownCharacters)
            }

            guard let data = audioData, !data.isEmpty else { return }
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
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
        guard let urlStr = message.mediaUrl, !urlStr.isEmpty else { return }
        guard (message.type == .image || message.type == .video), loadedImage == nil, !isLoadingMedia else { return }
        isLoadingMedia = true
        Task {
            if urlStr.hasPrefix("firestore://") {
                let path = urlStr.replacingOccurrences(of: "firestore://", with: "")
                if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
                   let fields = doc["fields"] as? [String: Any],
                   let rawB64 = (fields["data"] as? [String: Any])?["stringValue"] as? String {
                    let cleanB64 = rawB64.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: " ", with: "")
                    if let data = Data(base64Encoded: cleanB64, options: .ignoreUnknownCharacters),
                       let image = UIImage(data: data) {
                        await MainActor.run { loadedImage = image; isLoadingMedia = false }
                        return
                    }
                }
            } else if let httpURL = URL(string: urlStr), urlStr.hasPrefix("http") {
                if let (data, _) = try? await URLSession.shared.data(from: httpURL),
                   let image = UIImage(data: data) {
                    await MainActor.run { loadedImage = image; isLoadingMedia = false }
                    return
                }
            }

            if !retrying {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
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
            .scaleEffect(isAppeared ? 1 : 0.96)
            .opacity(1)
            .offset(x: isAppeared ? 0 : (isFromMe ? 5 : -5))
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isAppeared = true }
            }
    }
}
