import SwiftUI
import PhotosUI

public struct MemoriesView: View {
    @State private var photos: [UIImage] = []
    @State private var showPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var styleSelected = "Standard"
    @State private var colorSelected = "white"
    @State private var stickers: [String] = []

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var pollingTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                if photos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                                photoCell(photo: photo, index: index)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Recuerdos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        NavigationLink(destination: MemoryDetailView()) {
                            Image(systemName: "paintbrush.fill").font(.system(size: 16)).foregroundColor(ThemeManager.shared.primaryPink)
                        }
                        Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
            .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                Task {
                    await loadPhoto(from: newItem)
                }
            }
            .onAppear {
                loadSavedPhotos()
            }
            .onReceive(pollingTimer) { _ in
                loadSavedPhotos()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
            Text("No hay recuerdos aún")
                .font(.title3.weight(.semibold))
                .foregroundColor(.secondary)
            Text("Toca + para agregar fotos")
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.textSecondary)
        }
    }

    private func photoCell(photo: UIImage, index: Int) -> some View {
        GlassCard {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: photo)
                    .resizable().scaledToFill().frame(height: 160).clipped().cornerRadius(14)
                Button { deletePhoto(at: index) } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                }.padding(8)
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                saveImage(image)
                photos.append(image)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    private func saveImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.6),
              let myUid = FirebaseRESTService.shared.localId else { return }
        let partnerUid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
        let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
        let photoId = UUID().uuidString

        // Save to Firestore base64
        let b64 = data.base64EncodedString()
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "pairs/\(coupleId)/photos/\(photoId)",
                fields: ["data": b64, "timestamp": Date(), "uploadedBy": myUid])
        }

        // Also save locally
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let filename = "\(photoId).jpg"
        try? data.write(to: documentsDir.appendingPathComponent(filename))
    }

    private func loadSavedPhotos() {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        let partnerUid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
        let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")

        // Load from Firestore
        Task { @MainActor in
            guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "pairs/\(coupleId)/photos?pageSize=50"),
                  let documents = (docs["documents"] as? [[String: Any]]) else { return }

            var loaded: [UIImage] = []
            for doc in documents {
                guard let fields = doc["fields"] as? [String: Any],
                      let b64 = (fields["data"] as? [String: Any])?["stringValue"] as? String,
                      let data = Data(base64Encoded: b64),
                      let image = UIImage(data: data) else { continue }
                loaded.append(image)
            }
            if !loaded.isEmpty { self.photos = loaded }
        }

        // Also load local files
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)) ?? []
        let jpegs = files.filter { $0.pathExtension == "jpg" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        if photos.isEmpty {
            photos = jpegs.compactMap { guard let data = try? Data(contentsOf: $0) else { return nil }; return UIImage(data: data) }
        }
    }

    private func deletePhoto(at index: Int) {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let files = (
            try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
        ) ?? []
        let jpegs = files
            .filter { $0.pathExtension == "jpg" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        guard index < jpegs.count else { return }
        try? FileManager.default.removeItem(at: jpegs[index])
        photos.remove(at: index)
    }
}
