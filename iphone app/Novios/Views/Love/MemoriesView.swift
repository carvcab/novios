import SwiftUI
import FirebaseFirestore
import PhotosUI

public struct MemoriesView: View {
    @State private var memories: [MemoryItem] = []
    @State private var showAddMemory = false
    @State private var selectedImage: UIImage?
    @State private var showImageViewer = false
    @State private var viewerImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var isUploading = false
    @State private var snapshotListener: ListenerRegistration?

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared

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
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Recuerdos y Álbum 📸")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddMemory = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.primaryPink)
                }
            }
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
        .sheet(isPresented: $showAddMemory) { addMemorySheet }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let img = viewerImage {
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
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryPink.opacity(0.6))
            Text("Álbum Vacío")
                .appFont(size: 18, weight: .semibold)
            Text("Agrega momentos inolvidables juntos 💖")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private func memoryCard(_ memory: MemoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = memory.loadedImage {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(height: 130)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        viewerImage = image
                        showImageViewer = true
                    }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.primaryPink.opacity(0.1))
                        .frame(height: 130)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(theme.primaryPink.opacity(0.4))
                }
            }
            Text(memory.title)
                .appFont(size: 14, weight: .semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
            if !memory.description.isEmpty {
                Text(memory.description)
                    .appFont(size: 12)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            if memory.mediaUrl != nil {
                HStack(spacing: 8) {
                    Button(role: .destructive) {
                        deleteMemory(memory)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
    }

    private var addMemorySheet: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Seleccionar foto")
                            }
                            .foregroundColor(theme.primary)
                        }
                    }
                }
                Section("Título") {
                    TextField("Lugar o momento...", text: $newTitle)
                }
                Section("Descripción") {
                    TextField("Detalles...", text: $newDescription)
                }
            }
            .navigationTitle("Nuevo Recuerdo 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showAddMemory = false
                        resetForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveMemory() }
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty || isUploading)
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

    private func startListening() {
        snapshotListener = memoriesRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc -> MemoryItem? in
                let data = doc.data()
                guard let title = data["title"] as? String, !title.isEmpty else { return nil }
                let mediaPaths = data["mediaPaths"] as? [String]
                let url = mediaPaths?.first
                return MemoryItem(
                    id: doc.documentID,
                    title: title,
                    description: data["description"] as? String ?? "",
                    mediaUrl: url
                )
            }
            DispatchQueue.main.async {
                self.memories = items.sorted { $0.title > $1.title }
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
            guard let urlStr = memories[i].mediaUrl else { continue }
            if memories[i].loadedImage != nil { continue }
            Task {
                let image = await loadImage(from: urlStr)
                await MainActor.run {
                    if i < self.memories.count {
                        self.memories[i].loadedImage = image
                    }
                }
            }
        }
    }

    private func loadImage(from urlStr: String) async -> UIImage? {
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
            let base64 = data.base64EncodedString()
            if base64.count <= 730_000 {
                let mediaId = UUID().uuidString
                try? await db.document("chat_media/\(mediaId)").setData([
                    "data": base64,
                    "mimeType": "image/jpeg"
                ])
                mediaUrl = "firestore://chat_media/\(mediaId)"
            }
        }

        let docId = UUID().uuidString
        var fields: [String: Any] = [
            "title": title,
            "description": newDescription.trimmingCharacters(in: .whitespaces),
            "date": FieldValue.serverTimestamp()
        ]
        if let url = mediaUrl {
            fields["mediaPaths"] = [url]
        }
        try? await memoriesRef.document(docId).setData(fields)

        await MainActor.run {
            showAddMemory = false
            resetForm()
        }
    }

    private func deleteMemory(_ memory: MemoryItem) {
        Task {
            try? await memoriesRef.document(memory.id).delete()
            if let urlStr = memory.mediaUrl, urlStr.hasPrefix("firestore://") {
                let path = urlStr.replacingOccurrences(of: "firestore://", with: "")
                try? await db.document(path).delete()
            }
        }
    }

    private func resetForm() {
        newTitle = ""
        newDescription = ""
        selectedImage = nil
        photoItem = nil
    }
}

private struct MemoryItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let mediaUrl: String?
    var loadedImage: UIImage?
}
