import SwiftUI
import FirebaseFirestore
import PhotosUI

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public struct MemoriesView: View {
    @State private var memories: [MemoryItem] = []
    @State private var showAdd = false
    @State private var showDetail = false
    @State private var detailMemory: MemoryItem?
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var newTitle = ""
    @State private var newDesc = ""
    @State private var newDate = Date()
    @State private var newStyle = "standard"
    @State private var newStickers: [String] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var viewerImage: UIImage?
    @State private var detailTab: DetailTab = .frames
    @State private var editTitle = ""
    @State private var editDesc = ""
    @State private var editStyle = "standard"
    @State private var editStickers: [String] = []
    @State private var editFrameColor: Color = .white

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared

    private let styles: [(id: String, name: String, icon: String)] = [
        ("standard", "Estándar", "square.on.square"),
        ("polaroid", "Polaroid", "camera.viewfinder"),
        ("romantic", "Romántico", "heart.fill"),
        ("vintage", "Vintage", "clock.fill"),
        ("ticket", "Boleto", "ticket.fill"),
        ("heart_frame", "Corazones", "heart.circle"),
        ("stars_frame", "Estrellado", "star.fill"),
        ("floral", "Floral", "leaf.fill"),
        ("glow", "Neón", "sparkles"),
    ]

    private let stickers: [(id: String, emoji: String)] = [
        ("heart", "❤️"), ("star", "⭐"), ("flower", "🌸"), ("cat", "🐱"),
        ("kiss", "💋"), ("party", "🎉"), ("bear", "🧸"), ("ring", "💍"),
        ("sparkles", "✨"), ("rainbow", "🌈"), ("chocolate", "🍫"), ("music", "🎵"),
        ("popcorn", "🍿"), ("airplane", "✈️"), ("house", "🏠"),
    ]

    private let pastelColors: [Color] = [
        .white, Color(red: 1, green: 0.94, blue: 0.96), Color(red: 0.94, green: 1, blue: 0.94),
        Color(red: 0.94, green: 0.97, blue: 1), Color(red: 1, green: 0.97, blue: 0.88),
        Color(red: 1, green: 0.89, blue: 0.88), Color(red: 0.9, green: 0.9, blue: 0.98),
        Color(red: 0.91, green: 0.96, blue: 0.91),
    ]
    @State private var selectedFrameColor: Color = .white

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var memoriesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("memories")
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if memories.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(memories) { memory in
                            memoryCard(memory)
                                .onTapGesture { openDetail(memory) }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteMemory(memory)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Recuerdos 📸")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.primaryPink)
                }
            }
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(isPresented: $showDetail) { if let m = detailMemory { detailSheet(m) } }
        .fullScreenCover(item: $viewerImage) { img in
            ZStack {
                Color.black.ignoresSafeArea()
                InteractiveViewer(img: img) { viewerImage = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryPink.opacity(0.6))
            Text("Álbum Vacío")
                .appFont(size: 18, weight: .semibold)
            Text("Agrega momentos inolvidables juntos 💖")
                .appFont(size: 13).foregroundColor(.secondary)
        }
    }

    // MARK: - Full-Screen Viewer with Zoom

    private struct InteractiveViewer: View {
        let img: UIImage
        let onDismiss: () -> Void

        var body: some View {
            Image(uiImage: img)
                .resizable().scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { onDismiss() }
        }
    }

    // MARK: - Memory Card with Styles

    private func memoryCard(_ m: MemoryItem) -> some View {
        let style = m.style
        let rotation = Double.random(in: -2...2)
        let frameColor = m.frameColor.flatMap { c in
            pastelColors.first { colorString($0) == c }
        } ?? defaultFrameColor(style)

        return Group {
            switch style {
            case "polaroid": polaroidCard(m, frameColor)
            case "romantic": romanticCard(m, frameColor)
            case "vintage": vintageCard(m, frameColor)
            case "ticket": ticketCard(m, frameColor)
            case "heart_frame": heartFrameCard(m, frameColor)
            case "stars_frame": starsFrameCard(m, frameColor)
            case "floral": floralCard(m, frameColor)
            case "glow": glowCard(m, frameColor)
            default: standardCard(m, frameColor)
            }
        }
        .rotationEffect(.degrees(rotation))
    }

    private func imageContent(_ m: MemoryItem) -> some View {
        ZStack {
            if let img = m.loadedImage {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                theme.primaryPink.opacity(0.1)
                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.primaryPink.opacity(0.3))
            }
            stickerOverlay(m.stickers)
        }
    }

    private func stickerOverlay(_ selected: [String]) -> some View {
        let selectedEmojis = stickers.filter { selected.contains($0.id) }.map(\.emoji)
        let positions: [Alignment] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing, .center]
        return ZStack {
            ForEach(Array(selectedEmojis.enumerated()), id: \.offset) { i, emoji in
                Text(emoji)
                    .font(.system(size: i == 4 ? 28 : 20))
                    .shadow(color: .black.opacity(0.2), radius: 1)
                    .alignmentGuide(positions[i % positions.count].horizontal) { d in
                        positions[i % positions.count] == .topLeading || positions[i % positions.count] == .bottomLeading ? d.width * 0.3 : -d.width * 0.3
                    }
                    .alignmentGuide(positions[i % positions.count].vertical) { d in
                        positions[i % positions.count] == .topLeading || positions[i % positions.count] == .topTrailing ? d.height * 0.3 : -d.height * 0.3
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func defaultFrameColor(_ style: String) -> Color {
        switch style {
        case "polaroid": return .white
        case "romantic": return Color(red: 1, green: 0.89, blue: 0.88)
        case "vintage": return Color(red: 0.9, green: 0.83, blue: 0.7)
        case "ticket": return Color(red: 1, green: 0.97, blue: 0.88)
        default: return .white
        }
    }

    // Standard
    private func standardCard(_ m: MemoryItem, _ fc: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            imageContent(m).frame(height: 130).clipShape(RoundedRectangle(cornerRadius: 12))
            Text(m.title).appFont(size: 13, weight: .semibold).lineLimit(1).foregroundColor(.primary)
            if !m.desc.isEmpty { Text(m.desc).appFont(size: 11).foregroundColor(.secondary).lineLimit(2) }
        }
        .padding(10).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))
    }

    // Polaroid
    private func polaroidCard(_ m: MemoryItem, _ fc: Color) -> some View {
        VStack(spacing: 0) {
            imageContent(m).frame(height: 120).clipped().padding(6)
            Text(m.title).appFont(size: 11, weight: .bold).lineLimit(1).padding(.bottom, 20).padding(.horizontal, 4)
        }
        .background(fc).clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    // Romantic
    private func romanticCard(_ m: MemoryItem, _ fc: Color) -> some View {
        VStack(spacing: 4) {
            imageContent(m).frame(height: 120).clipped().clipShape(RoundedRectangle(cornerRadius: 10)).padding(6)
            Text(m.title.isEmpty ? "Amor" : m.title).appFont(size: 10, weight: .medium).foregroundColor(.pink).lineLimit(1)
        }
        .padding(6).background(fc).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 2))
        .shadow(color: .pink.opacity(0.05), radius: 4, y: 2)
    }

    // Vintage
    private func vintageCard(_ m: MemoryItem, _ fc: Color) -> some View {
        VStack(spacing: 4) {
            imageContent(m).frame(height: 100).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 4)).padding(8)
            Text(m.title).appFont(size: 10, weight: .semibold).lineLimit(1).foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.2))
        }
        .padding(4).background(fc).clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    // Ticket
    private func ticketCard(_ m: MemoryItem, _ fc: Color) -> some View {
        HStack(spacing: 0) {
            imageContent(m).frame(width: 60, height: 80).clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(m.title).appFont(size: 11, weight: .bold).lineLimit(2)
                if !m.desc.isEmpty { Text(m.desc).appFont(size: 9).foregroundColor(.secondary).lineLimit(1) }
            }.padding(6)
        }
        .frame(height: 90).background(fc).clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.08)))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // Heart Frame
    private func heartFrameCard(_ m: MemoryItem, _ fc: Color) -> some View {
        imageContent(m).frame(height: 130).clipShape(Circle().inset(by: 4))
            .overlay(Circle().stroke(theme.primaryPink.opacity(0.4), lineWidth: 3))
            .overlay(Text(m.title).appFont(size: 9, weight: .medium).foregroundColor(theme.primaryPink).lineLimit(1), alignment: .bottom)
            .padding(6)
    }

    // Stars Frame
    private func starsFrameCard(_ m: MemoryItem, _ fc: Color) -> some View {
        imageContent(m).frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.yellow.opacity(0.5), lineWidth: 2))
            .overlay(Text(m.title).appFont(size: 9, weight: .medium).foregroundColor(.orange).lineLimit(1), alignment: .bottom)
            .padding(6)
    }

    // Floral
    private func floralCard(_ m: MemoryItem, _ fc: Color) -> some View {
        imageContent(m).frame(height: 130).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 2))
            .overlay(Text("🌸 \(m.title)").appFont(size: 9, weight: .medium).lineLimit(1), alignment: .bottom)
            .padding(6)
    }

    // Glow/Neon
    private func glowCard(_ m: MemoryItem, _ fc: Color) -> some View {
        imageContent(m).frame(height: 130).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: theme.primary.opacity(0.3), radius: 8)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.primary.opacity(0.3), lineWidth: 1))
            .overlay(Text(m.title).appFont(size: 9, weight: .medium).foregroundColor(theme.primary).lineLimit(1), alignment: .bottom)
            .padding(6)
    }

    // MARK: - Style & Sticker Pickers

    private var stylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(styles, id: \.id) { st in
                    VStack(spacing: 4) {
                        let isSelected = newStyle == st.id
                        Image(systemName: st.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? theme.primary : .secondary)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Material.ultraThinMaterial))
                            .background(isSelected ? theme.primary.opacity(0.15) : Color.clear)
                        Text(st.name)
                            .appFont(size: 9)
                            .foregroundColor(isSelected ? theme.primary : .secondary)
                    }
                    .onTapGesture { newStyle = st.id }
                }
            }
        }
    }

    private var stickerGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 8) {
            ForEach(stickers, id: \.id) { st in
                Text(st.emoji).font(.system(size: 24))
                    .padding(4)
                    .background(newStickers.contains(st.id) ? theme.primary.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        if newStickers.contains(st.id) { newStickers.removeAll { $0 == st.id } }
                        else { newStickers.append(st.id) }
                    }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pastelColors.enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 36, height: 36)
                        .overlay(Circle().stroke(colorString(selectedFrameColor) == colorString(color) ? theme.primary : Color.gray.opacity(0.3), lineWidth: 2))
                        .onTapGesture { selectedFrameColor = color }
                }
            }
        }
    }

    private var editStylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(styles, id: \.id) { st in
                    VStack(spacing: 4) {
                        let isSelected = editStyle == st.id
                        Image(systemName: st.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? theme.primary : .secondary)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Material.ultraThinMaterial))
                            .background(isSelected ? theme.primary.opacity(0.15) : Color.clear)
                        Text(st.name)
                            .appFont(size: 9)
                            .foregroundColor(isSelected ? theme.primary : .secondary)
                    }
                    .onTapGesture { editStyle = st.id }
                }
            }
        }
    }

    private var editStickerGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 8) {
            ForEach(stickers, id: \.id) { st in
                Text(st.emoji).font(.system(size: 24))
                    .padding(4)
                    .background(editStickers.contains(st.id) ? theme.primary.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        if editStickers.contains(st.id) { editStickers.removeAll { $0 == st.id } }
                        else { editStickers.append(st.id) }
                    }
            }
        }
    }

    private var editColorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pastelColors.enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 36, height: 36)
                        .overlay(Circle().stroke(colorString(editFrameColor) == colorString(color) ? theme.primary : Color.gray.opacity(0.3), lineWidth: 2))
                        .onTapGesture { editFrameColor = color }
                }
            }
        }
    }

    // MARK: - Add Sheet

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let img = selectedImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(height: 200).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            HStack { Image(systemName: "photo.fill"); Text("Seleccionar foto") }.foregroundColor(theme.primary)
                        }
                    }
                }
                Section("Título") { TextField("Lugar o momento...", text: $newTitle) }
                Section("Descripción") { TextField("Detalles...", text: $newDesc) }
                Section("Fecha") {
                    DatePicker("Fecha del recuerdo", selection: $newDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section("Estilo") { stylePicker }
                Section("Stickers") { stickerGrid }
                Section("Color de Fondo") { colorPicker }
            }
            .navigationTitle("Nuevo Recuerdo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showAdd = false; resetForm() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await saveMemory() } }
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: photoItem) { item in
            Task {
                guard let item, let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                selectedImage = image
            }
        }
    }

    // MARK: - Detail Sheet with 3 Tabs

    private enum DetailTab: String, CaseIterable {
        case frames = "Marcos"
        case stickers = "Stickers"
        case text = "Texto"
    }

    private func detailSheet(_ m: MemoryItem) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                memoryCard(m).padding(16)

                Picker("", selection: $detailTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                ScrollView {
                    switch detailTab {
                    case .frames:
                        frameTabContent
                    case .stickers:
                        stickerTabContent
                    case .text:
                        textTabContent
                    }
                }
            }
            .background(LiquidBackgroundView())
            .navigationTitle("Editar Recuerdo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveEdits(m) }
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        deleteMemory(m)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear {
            editTitle = m.title
            editDesc = m.desc
            editStyle = m.style
            editStickers = m.stickers
            if let fc = m.frameColor {
                editFrameColor = pastelColors.first { colorString($0) == fc } ?? .white
            }
        }
    }

    private var frameTabContent: some View {
        VStack(spacing: 16) {
            editStylePicker
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Color de Fondo").appFont(size: 14, weight: .semibold).foregroundColor(.primary)
                editColorPicker
            }
        }
        .padding(16)
    }

    private var stickerTabContent: some View {
        VStack(spacing: 8) {
            Text("Toca para agregar/quitar stickers")
                .appFont(size: 13).foregroundColor(.secondary)
            editStickerGrid
        }
        .padding(16)
    }

    private var textTabContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Título").appFont(size: 14, weight: .semibold).foregroundColor(.primary)
                TextField("Título", text: $editTitle)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Descripción").appFont(size: 14, weight: .semibold).foregroundColor(.primary)
                TextEditor(text: $editDesc)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
            }
        }
        .padding(16)
    }

    // MARK: - Firestore

    private func startListening() {
        snapshotListener = memoriesRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc -> MemoryItem? in
                let d = doc.data()
                guard let title = d["title"] as? String, !title.isEmpty else { return nil }
                let paths = d["mediaPaths"] as? [String]
                return MemoryItem(
                    id: doc.documentID,
                    title: title,
                    desc: d["description"] as? String ?? "",
                    date: (d["date"] as? Timestamp)?.dateValue() ?? Date(),
                    mediaUrl: paths?.first,
                    style: d["decorStyle"] as? String ?? "standard",
                    stickers: (d["decorStickers"] as? [String]) ?? [],
                    frameColor: d["decorFrameColor"] as? String,
                    loadedImage: nil
                )
            }
            DispatchQueue.main.async {
                self.memories = items.sorted { $0.date > $1.date }
                loadImages()
            }
        }
    }

    private func stopListening() {
        snapshotListener?.remove()
        snapshotListener = nil
    }

    private func loadImages() {
        for i in memories.indices {
            guard let urlStr = memories[i].mediaUrl, memories[i].loadedImage == nil else { continue }
            Task {
                let img = await fetchImage(urlStr)
                await MainActor.run { if i < self.memories.count { self.memories[i].loadedImage = img } }
            }
        }
    }

    private func fetchImage(_ urlStr: String) async -> UIImage? {
        if urlStr.hasPrefix("http") {
            guard let url = URL(string: urlStr), let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }
        if urlStr.hasPrefix("firestore://") {
            let path = urlStr.replacingOccurrences(of: "firestore://", with: "")
            guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
                  let fields = doc["fields"] as? [String: Any],
                  let rawB64 = (fields["data"] as? [String: Any])?["stringValue"] as? String,
                  let data = Data(base64Encoded: rawB64, options: .ignoreUnknownCharacters) else { return nil }
            return UIImage(data: data)
        }
        guard let data = Data(base64Encoded: urlStr, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)
    }

    private func saveMemory() async {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        var mediaUrl: String?
        if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.6) {
            let b64 = data.base64EncodedString()
            if b64.count <= 730_000 {
                let mid = UUID().uuidString
                try? await db.document("chat_media/\(mid)").setData(["data": b64, "mimeType": "image/jpeg"])
                mediaUrl = "firestore://chat_media/\(mid)"
            }
        }

        let docId = UUID().uuidString
        var fields: [String: Any] = [
            "title": title,
            "description": newDesc.trimmingCharacters(in: .whitespaces),
            "date": Timestamp(date: newDate),
            "decorStyle": newStyle,
            "decorStickers": newStickers,
            "decorFrameColor": colorString(selectedFrameColor),
        ]
        if let url = mediaUrl { fields["mediaPaths"] = [url] }
        try? await memoriesRef.document(docId).setData(fields)
        await MainActor.run { showAdd = false; resetForm() }
    }

    private func saveEdits(_ m: MemoryItem) async {
        let title = editTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        try? await memoriesRef.document(m.id).updateData([
            "title": title,
            "description": editDesc.trimmingCharacters(in: .whitespaces),
            "decorStyle": editStyle,
            "decorStickers": editStickers,
            "decorFrameColor": colorString(editFrameColor),
        ])
        await MainActor.run { showDetail = false }
    }

    private func deleteMemory(_ m: MemoryItem) {
        Task {
            try? await memoriesRef.document(m.id).delete()
            if let urlStr = m.mediaUrl, urlStr.hasPrefix("firestore://") {
                let path = urlStr.replacingOccurrences(of: "firestore://", with: "")
                try? await db.document(path).delete()
            }
            await MainActor.run { showDetail = false }
        }
    }

    private func openDetail(_ m: MemoryItem) {
        detailMemory = m
        detailTab = .frames
        editTitle = m.title
        editDesc = m.desc
        editStyle = m.style
        editStickers = m.stickers
        if let fc = m.frameColor {
            editFrameColor = pastelColors.first { colorString($0) == fc } ?? .white
        }
        showDetail = true
    }

    private func resetForm() {
        newTitle = ""; newDesc = ""; newDate = Date(); selectedImage = nil; photoItem = nil
        newStyle = "standard"; newStickers = []; selectedFrameColor = .white
    }

    private func colorString(_ c: Color) -> String {
        let uiColor = UIColor(c)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))"
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .long; f.locale = Locale(identifier: "es")
        return f.string(from: d)
    }
}

private struct MemoryItem: Identifiable {
    let id: String
    let title: String
    let desc: String
    let date: Date
    let mediaUrl: String?
    let style: String
    let stickers: [String]
    let frameColor: String?
    var loadedImage: UIImage?
}
