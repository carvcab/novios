import SwiftUI
import FirebaseFirestore

public struct MusicView: View {
    @State private var featuredTitle = "Nuestra Canción"
    @State private var featuredArtist = "Aún no asignado"
    @State private var featuredUrl = ""
    @State private var featuredBy = ""
    @State private var playlistSongs: [(id: String, title: String, artist: String, url: String, addedBy: String)] = []
    @State private var showFeaturedDialog = false
    @State private var showAddDialog = false
    @State private var editTitle = ""
    @State private var editArtist = ""
    @State private var editUrl = ""
    @State private var spin = false
    @State private var featuredListener: ListenerRegistration?
    @State private var playlistListener: ListenerRegistration?

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var featuredRef: DocumentReference {
        db.collection("couples").document(coupleId).collection("music").document("featured")
    }

    private var playlistRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("playlist")
    }

    private var myName: String {
        AuthService.shared.currentUser?.id == CoupleService.diegoUid ? CoupleService.diegoName : CoupleService.yosmariName
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView {
                VStack(spacing: 24) {
                    featuredSection
                    playlistSection
                }
                .padding(20)
            }
        }
        .navigationTitle("Nuestra Música")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startListening() }
        .onDisappear { stopListening() }
        .sheet(isPresented: $showFeaturedDialog) { featuredDialog }
        .sheet(isPresented: $showAddDialog) { addDialog }
    }

    private var featuredSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [theme.primary, theme.primaryPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                    .shadow(color: theme.primary.opacity(0.25), radius: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(spin ? Animation.linear(duration: 10).repeatForever(autoreverses: false) : .default, value: spin)
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .onAppear { spin = true }

            Text(featuredTitle)
                .appFont(size: 20, weight: .bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(featuredArtist)
                .appFont(size: 14)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !featuredBy.isEmpty {
                Text("Puesta con amor por \(featuredBy) ❤️")
                    .appFont(size: 10, weight: .medium)
                    .foregroundColor(theme.primary.opacity(0.8))
            }

            HStack(spacing: 8) {
                Button {
                    guard let url = URL(string: featuredUrl), !featuredUrl.isEmpty else { return }
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                        Text("Escuchar en Spotify")
                            .appFont(size: 13, weight: .medium)
                    }
                    .foregroundColor(Color(red: 0.1, green: 0.5, blue: 0.1))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { showFeaturedDialog = true } label: {
                    Image(systemName: "pencil")
                        .appFont(size: 14)
                        .foregroundColor(theme.primary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }

    private var playlistSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "playlist.fill")
                    .foregroundColor(theme.primary)
                Text("Playlist Compartida")
                    .appFont(size: 16, weight: .bold)
                Spacer()
                Button { showAddDialog = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Agregar")
                            .appFont(size: 13)
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, 4)

            if playlistSongs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundColor(theme.textSecondary.opacity(0.2))
                    Text("La playlist está vacía")
                        .appFont(size: 12)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(playlistSongs.indices, id: \.self) { i in
                        let song = playlistSongs[i]
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.primary.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "music.note")
                                    .foregroundColor(theme.primary)
                                    .appFont(size: 16)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(song.title)
                                    .appFont(size: 14, weight: .semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("\(song.artist) • De \(song.addedBy)")
                                    .appFont(size: 11)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                guard let url = URL(string: song.url), !song.url.isEmpty else { return }
                                UIApplication.shared.open(url)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .appFont(size: 24)
                                    .foregroundColor(.green)
                            }

                            Button {
                                deleteSong(at: i)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .appFont(size: 14)
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
            }
        }
    }

    private var featuredDialog: some View {
        NavigationStack {
            Form {
                Section("Nuestra Canción") {
                    TextField("Título", text: $editTitle)
                    TextField("Artista", text: $editArtist)
                    TextField("Enlace de Spotify", text: $editUrl)
                }
            }
            .navigationTitle("Editar Canción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showFeaturedDialog = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveFeatured() }
                    }
                    .disabled(editTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var addDialog: some View {
        NavigationStack {
            Form {
                Section("Canción") {
                    TextField("Título", text: $editTitle)
                    TextField("Artista", text: $editArtist)
                    TextField("Enlace de Spotify", text: $editUrl)
                }
            }
            .navigationTitle("Agregar a Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showAddDialog = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        Task { await addSong() }
                    }
                    .disabled(editTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func startListening() {
        featuredListener = featuredRef.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                self.featuredTitle = data["title"] as? String ?? "Nuestra Canción"
                self.featuredArtist = data["artist"] as? String ?? "Aún no asignado"
                self.featuredUrl = data["spotifyUrl"] as? String ?? ""
                self.featuredBy = data["addedBy"] as? String ?? ""
            }
        }

        playlistListener = playlistRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let songs = docs.compactMap { doc -> (id: String, title: String, artist: String, url: String, addedBy: String)? in
                let data = doc.data()
                guard let title = data["title"] as? String, !title.isEmpty else { return nil }
                return (
                    id: doc.documentID,
                    title: title,
                    artist: data["artist"] as? String ?? "",
                    url: data["spotifyUrl"] as? String ?? "",
                    addedBy: data["addedBy"] as? String ?? ""
                )
            }
            DispatchQueue.main.async {
                self.playlistSongs = songs
            }
        }
    }

    private func stopListening() {
        featuredListener?.remove()
        playlistListener?.remove()
        featuredListener = nil
        playlistListener = nil
    }

    private func saveFeatured() async {
        let title = editTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let artist = editArtist.trimmingCharacters(in: .whitespaces)
        let url = editUrl.trimmingCharacters(in: .whitespaces)
        try? await featuredRef.setData([
            "title": title,
            "artist": artist,
            "spotifyUrl": url,
            "addedBy": myName,
            "timestamp": FieldValue.serverTimestamp()
        ])
        let historyId = "\(Date().timeIntervalSince1970 * 1000)"
        try? await db.collection("couples").document(coupleId).collection("music_history").document(historyId).setData([
            "id": historyId,
            "title": title,
            "artist": artist,
            "spotifyUrl": url,
            "addedBy": myName,
            "timestamp": FieldValue.serverTimestamp()
        ])
        await MainActor.run { showFeaturedDialog = false }
    }

    private func addSong() async {
        let title = editTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let docId = "\(Date().timeIntervalSince1970 * 1000)"
        try? await playlistRef.document(docId).setData([
            "id": docId,
            "title": title,
            "artist": editArtist.trimmingCharacters(in: .whitespaces),
            "spotifyUrl": editUrl.trimmingCharacters(in: .whitespaces),
            "addedBy": myName,
            "timestamp": FieldValue.serverTimestamp()
        ])
        await MainActor.run { showAddDialog = false; editTitle = ""; editArtist = ""; editUrl = "" }
    }

    private func deleteSong(at index: Int) {
        let song = playlistSongs[index]
        let title = song.title
        Task {
            try? await playlistRef.document(song.id).delete()
        }
    }
}
