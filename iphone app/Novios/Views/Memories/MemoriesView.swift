import SwiftUI
import PhotosUI

public struct MemoriesView: View {
    @State private var photos: [UIImage] = []
    @State private var showPicker = false
    @State private var selectedItem: PhotosPickerItem?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

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
                                GlassCard {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 160)
                                            .clipped()
                                            .cornerRadius(14)

                                        Button {
                                            deletePhoto(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 3)
                                        }
                                        .padding(8)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Recuerdos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadPhoto(from: newItem)
                }
            }
            .onAppear {
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
        guard let data = image.jpegData(compressionQuality: 0.8),
              let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let filename = "\(UUID().uuidString).jpg"
        try? data.write(to: documentsDir.appendingPathComponent(filename))
    }

    private func loadSavedPhotos() {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let files = (
            try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
        ) ?? []
        let jpegs = files
            .filter { $0.pathExtension == "jpg" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        photos = jpegs.compactMap {
            guard let data = try? Data(contentsOf: $0) else { return nil }
            return UIImage(data: data)
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
