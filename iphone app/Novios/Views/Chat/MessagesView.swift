import SwiftUI
import PhotosUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var authService: AuthService
    @State private var textInput = ""
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSettings = false
    @State private var scrollTargetId: String?
    private var currentUserId: String { authService.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me" }

    private func messageBubble(_ msg: MessageModel) -> ChatBubbleView {
        let isMe = msg.senderId == currentUserId
        let s = ChatService.shared
        return ChatBubbleView(message: msg, isFromMe: isMe, onReply: { s.setReplyTo(message: msg) }, onReact: { s.addReaction(to: msg.id, emoji: $0) }, onTapReply: { self.scrollTargetId = $0 })
    }

    @State private var nextDateLabel: String?
    @State private var nextDateDays: Int?

    private let emojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                VStack(spacing: 0) {
                    dateBanner

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(chatService.messages) { msg in
                                    self.messageBubble(msg)
                                        .id(msg.id)
                                }
                                Color.clear.frame(height: 4).id("bottom")
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                        }
                        .scrollIndicators(.hidden)
                        .onReceive(chatService.autoScrollToBottom) { _ in
                            withAnimation(.spring(duration: 0.45)) { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                        .onChange(of: scrollTargetId) { id in
                            if let id = id {
                                withAnimation(.spring(duration: 0.45)) {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                                scrollTargetId = nil
                            }
                        }
                        .onReceive(chatService.$messages) { msgs in
                            for msg in msgs where msg.readTimestamp == nil && msg.senderId != (authService.currentUser?.id ?? "me") {
                                chatService.markAsRead(messageId: msg.id)
                                break
                            }
                        }
                    }

                    emojiBar
                    inputBar
                }
            }
            .navigationTitle("Diego 💞 Yosmari (v1.4.0)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .appFont(size: 18)
                            .foregroundColor(ThemeManager.shared.primary.opacity(0.6))
                    }
                }
            }
            .onAppear {
                chatService.fetchMessages()
                Task { await loadDates() }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                    chatService.sendImage(imageData: data); selectedPhotoItem = nil
                }
            }
        }
    }

    private var emojiBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(emojis, id: \.self) { e in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        chatService.sendMessage(text: e)
                    } label: {
                        Text(e).appFont(size: 18)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .background(ThemeManager.shared.pastelWarmBg.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            .shadow(color: ThemeManager.shared.pastelRose.opacity(0.06), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
        }
        .frame(height: 42)
        .background(.ultraThinMaterial.opacity(0.7))
    }

    @ViewBuilder
    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if chatService.isRecording { _ = chatService.stopRecording() }
                    else { chatService.startRecording() }
                } label: {
                    ZStack {
                        if chatService.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.red, lineWidth: 2).scaleEffect(1.3))
                                .overlay(Circle().fill(Color.red).frame(width: 10, height: 10))
                        } else {
                        Image(systemName: "mic.fill")
                            .appFont(size: 18)
                            .foregroundColor(ThemeManager.shared.primary.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .background(ThemeManager.shared.pastelWarmBg.opacity(0.2))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .appFont(size: 16)
                            .foregroundColor(ThemeManager.shared.primary.opacity(0.7))
                    }

                    TextField("Escribe un mensaje...", text: $textInput)
                        .appFont(size: 15)
                        .foregroundColor(.primary)
                        .tint(ThemeManager.shared.primary)
                        .onSubmit { sendText() }

                    flameButton
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .background(ThemeManager.shared.pastelWarmBg.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.6))

                Button {
                    sendText()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .appFont(size: 30)
                        .foregroundColor(textInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? ThemeManager.shared.textSecondary.opacity(0.2) : ThemeManager.shared.primary)
                }
                .disabled(textInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)

            if chatService.isRecording {
                recordingIndicator
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial.opacity(0.6))
        .overlay(alignment: .top) { Divider().opacity(0.3) }
    }

    private var flameButton: some View {
        Button {
            chatService.isShowingDisappearing.toggle()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if chatService.isShowingDisappearing {
                        Image(systemName: "flame.fill")
                            .appFont(size: 16)
                            .foregroundColor(Color(red: 0.95, green: 0.6, blue: 0.3))
                            .shadow(color: Color(red: 0.95, green: 0.6, blue: 0.3).opacity(0.4), radius: 4)
                    }
                    Image(systemName: chatService.isShowingDisappearing ? "flame.fill" : "flame")
                        .appFont(size: 16)
                        .foregroundColor(chatService.isShowingDisappearing ? Color(red: 0.95, green: 0.6, blue: 0.3) : ThemeManager.shared.textSecondary.opacity(0.3))
                }
                Text("EFÍMERO")
                    .appFont(size: 6, weight: .bold)
                    .foregroundColor(chatService.isShowingDisappearing ? Color(red: 0.95, green: 0.6, blue: 0.3) : ThemeManager.shared.textSecondary.opacity(0.2))
                    .tracking(0.8)
            }
        }
        .overlay(alignment: .top) {
            if chatService.isShowingDisappearing {
                Text("Los mensajes se autodestruyen")
                    .appFont(size: 8, weight: .medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(red: 0.95, green: 0.6, blue: 0.3))
                    .clipShape(Capsule())
                    .offset(y: -24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: chatService.isShowingDisappearing)
    }

    private var recordingIndicator: some View {
        HStack(spacing: 10) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
            Text("Grabando...")
                .appFont(size: 12, weight: .medium)
                .foregroundColor(.red)
            Text(String(format: "%.1fs", chatService.recordingDuration))
                .appFont(size: 12, weight: .medium)
                .foregroundColor(.secondary)
                .monospacedDigit()
            Spacer()
            Button {
                _ = chatService.stopRecording()
            } label: {
                Text("Enviar").appFont(size: 12, weight: .semibold).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(
                        ThemeManager.shared.primaryGradient
                    ).clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private var dateBanner: some View {
        if let label = nextDateLabel, let days = nextDateDays {
            HStack(spacing: 8) {
                Image(systemName: days == 0 ? "heart.fill" : "calendar")
                    .appFont(size: 12)
                    .foregroundColor(days == 0 ? ThemeManager.shared.primary : ThemeManager.shared.textSecondary)
                Text(days == 0 ? "💕 ¡Hoy es \(label)!" : "\(label) en \(days) días")
                    .appFont(size: 12, weight: .medium)
                    .foregroundColor(days == 0 ? ThemeManager.shared.primary : ThemeManager.shared.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.5))
            .overlay(alignment: .bottom) { Divider().opacity(0.15) }
        }
    }

    private func loadDates() async {
        let defaults = UserDefaults.standard
        let dateKeys: [(String, String, String)] = [
            ("anniversary_date", "anniversaryDate", "Aniversario"),
            ("met_date", "metDate", "Conocimos"),
            ("dating_date", "datingDate", "Primera cita"),
            ("wedding_date", "weddingDate", "Boda"),
            ("invitation_date", "invitationDate", "Invitación"),
        ]
        let formatter = ISO8601DateFormatter()
        let today = Calendar.current.startOfDay(for: Date())

        // Try parejas doc for partner-synced dates
        var dates: [String: Date] = [:]
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "parejas/pareja_001"),
           let fields = doc["fields"] as? [String: Any] {
            for (_, fsKey, _) in dateKeys {
                if let val = (fields[fsKey] as? [String: Any])?["stringValue"] as? String,
                   let d = formatter.date(from: val) {
                    dates[fsKey] = d
                }
            }
        }

        var nearestLabel: String?
        var nearestDays: Int?

        for (udKey, fsKey, label) in dateKeys {
            let date: Date?
            if let iso = defaults.string(forKey: udKey), !iso.isEmpty {
                date = formatter.date(from: iso)
            } else {
                date = dates[fsKey]
            }
            guard let d = date else { continue }
            let day = Calendar.current.startOfDay(for: d)
            let diff = Calendar.current.dateComponents([.day], from: today, to: day).day ?? 0
            if diff >= 0 {
                if nearestDays == nil || diff < nearestDays! {
                    nearestDays = diff
                    nearestLabel = label
                }
            }
        }
        await MainActor.run {
            nextDateLabel = nearestLabel
            nextDateDays = nearestDays
        }
    }

    private func sendText() {
        let t = textInput.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chatService.sendMessage(text: t)
        textInput = ""
    }
}
