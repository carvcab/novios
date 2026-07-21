import SwiftUI
import PhotosUI
import UIKit

public struct ProfileView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var couple = CoupleService.shared

    @State private var showSettings = false
    @State private var showPhotoPicker = false
    @State private var showEditBirthday = false
    @State private var birthdayDate: Date?
    @State private var profileImage: UIImage?
    @State private var profilePhotoFirestoreUrl: String?

    private let defaults = UserDefaults.standard
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private let df = ISO8601DateFormatter()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Couple header
                    VStack(spacing: 8) {
                        Text(couple.coupleName)
                            .appFont(size: 26, weight: .bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("En línea")
                                .appFont(size: 13)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.top, 20)

                    // Photos
                    HStack(spacing: -12) {
                        profileCircle(for: couple.currentUid == CoupleService.diegoUid ? "Diego" : "Yosmari",
                                      photo: nil, color: theme.primary)
                        profileCircle(for: couple.currentUid == CoupleService.diegoUid ? "Yosmari" : "Diego",
                                      photo: nil, color: theme.secondary)
                    }
                    .padding(.bottom, 8)

                    // Quick access cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        navCard(icon: "message.fill", title: "Nuestro Chat", color: theme.primary) { }
                        navCard(icon: "photo.fill", title: "Nuestro Álbum", color: theme.pastelPeach) { }
                        navCard(icon: "heart.fill", title: "Nuestra Historia", color: .red) { }
                        navCard(icon: "location.fill", title: "Nuestro Mapa", color: theme.pastelBlue) { }
                        navCard(icon: "calendar", title: "Calendario", color: theme.pastelMint) { }
                        navCard(icon: "music.note", title: "Música", color: theme.pastelLavender) { }
                        navCard(icon: "gamecontroller.fill", title: "Juegos", color: .orange) { }
                        navCard(icon: "moon.stars.fill", title: "Sueños", color: .purple) { }
                    }
                    .padding(.horizontal, 4)

                    // Settings button
                    Button {
                        showSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Configuración")
                        }
                        .appFont(size: 15, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.primaryGradient)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { image in
                if let data = image.jpegData(compressionQuality: 0.6) {
                    let b64 = data.base64EncodedString()
                    profileImage = image
                    let uid = AuthService.shared.currentUser?.id ?? ""
                    Task {
                        try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(uid)", fields: [
                            "foto": "data:image/jpeg;base64,\(b64)"
                        ])
                    }
                }
            }
        }
    }

    private func profileCircle(for name: String, photo: UIImage?, color: Color) -> some View {
        Button { showPhotoPicker = true } label: {
            ZStack {
                if let img = profileImage, name == (couple.currentUid == CoupleService.diegoUid ? "Diego" : "Yosmari") {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 80, height: 80).clipShape(Circle())
                } else {
                    Circle().fill(color.opacity(0.2)).frame(width: 80, height: 80)
                        .overlay(Text(name.prefix(1)).appFont(size: 32, weight: .bold).foregroundColor(color))
                }
                Circle().stroke(.white, lineWidth: 3).frame(width: 80, height: 80)
            }
        }
    }

    private func navCard(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).appFont(size: 24).foregroundColor(color)
                Text(title).appFont(size: 12, weight: .semibold).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .background(color.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.15)))
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(); config.filter = .images; config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage { DispatchQueue.main.async { self.parent.onImagePicked(uiImage) } }
            }
        }
    }
}
