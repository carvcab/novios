import SwiftUI

public struct LoveLettersView: View {
    @State private var letters: [(title: String, content: String)] = [
        ("Abrir cuando estés triste 🌧️", "Recuerda que no estás solo/a. Te amo incondicionalmente."),
        ("Abrir cuando me extrañes 💔", "Cierra los ojos e imagina un abrazo fuerte."),
        ("Abrir en tu cumpleaños 🎂", "¡Feliz cumpleaños al amor de mi vida!"),
        ("Abrir cuando no puedas dormir 🌙", "Piensa en todos nuestros momentos mágicos."),
        ("Abrir cuando estés enojado/a 😤", "Te amo incluso cuando estamos enojados."),
        ("Abrir cuando dudes de ti 💪", "Eres increíble. No dejes que nada te haga menos."),
    ]
    @State private var showDetail = false
    @State private var selectedTitle = ""
    @State private var selectedContent = ""
    @State private var receivedLetters: [(id: String, title: String, content: String)] = []
    @State private var showCompose = false
    @State private var newTitle = ""
    @State private var newContent = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        if !receivedLetters.isEmpty {
                            Text("Recibidas").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                            ForEach(receivedLetters, id: \.id) { letter in
                                GlassCard { rowContent(letter.title, letter.content, true) }
                                    .onTapGesture { open(title: letter.title, content: letter.content) }
                                    .padding(.horizontal, 20)
                            }
                        }

                        Text("Sobres para abrir").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(letters.indices, id: \.self) { i in
                                Button {
                                    open(title: letters[i].title, content: letters[i].content)
                                    sendLetter(letters[i])
                                } label: {
                                    GlassCard {
                                        VStack(spacing: 12) {
                                            Image(systemName: "envelope.badge.shield.halffilled").font(.system(size: 36)).foregroundColor(ThemeManager.shared.primaryPink)
                                            Text(letters[i].title).font(.system(size: 13, weight: .bold)).foregroundColor(.primary).multilineTextAlignment(.center).lineLimit(2)
                                        }.frame(height: 110).padding(4)
                                    }
                                }
                            }
                        }.padding(.horizontal, 20)

                        Button { showCompose = true } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Escribir carta personalizada").font(.system(size: 14, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Spacer()
                                }
                            }
                        }.padding(.horizontal, 20)
                    }.padding(.vertical, 20)
                }
            }
            .navigationTitle("Cartas")
            .sheet(isPresented: $showDetail) {
                ZStack {
                    ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "envelope.open.fill").font(.system(size: 60)).foregroundStyle(ThemeManager.shared.neonGlowGradient)
                        Text(selectedTitle).font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                        Text(selectedContent).font(.system(size: 16)).foregroundColor(.primary.opacity(0.7)).multilineTextAlignment(.center).padding(.horizontal, 30)
                        Spacer()
                        Button("Cerrar") { showDetail = false }.font(.system(size: 16, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                    }.padding()
                }
            }
            .alert("Nueva carta", isPresented: $showCompose) {
                TextField("Título", text: $newTitle)
                TextField("Contenido", text: $newContent)
                Button("Cancelar", role: .cancel) { newTitle = ""; newContent = "" }
                Button("Enviar") {
                    if !newTitle.isEmpty && !newContent.isEmpty {
                        open(title: newTitle, content: newContent)
                        Task { await FirestoreSyncService.shared.saveLetter(title: newTitle, content: newContent, emoji: "💌") }
                        newTitle = ""; newContent = ""
                    }
                }
            }
            .task { await loadReceived() }
        }
    }

    private func rowContent(_ title: String, _ content: String, _ isReceived: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: isReceived ? "envelope.fill" : "envelope.badge.shield.halffilled").font(.system(size: 24)).foregroundColor(ThemeManager.shared.primaryPink)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                Text(String(content.prefix(60)) + "...").font(.system(size: 11)).foregroundColor(.primary.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.primary.opacity(0.3))
        }
    }

    private func open(title: String, content: String) {
        selectedTitle = title; selectedContent = content; showDetail = true
    }

    private func sendLetter(_ letter: (title: String, content: String)) {
        Task { await FirestoreSyncService.shared.saveLetter(title: letter.title, content: letter.content, emoji: "💌") }
    }

    private func loadReceived() async {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        let puid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
        let cid = [myUid, puid].sorted().joined(separator: "_")
        let items = (try? await FirestoreSyncService.shared.getCollection(path: "couples/\(cid)/letters")) ?? []
        for item in items {
            if let id = item["id"] as? String, let title = item["title"] as? String, let content = item["content"] as? String {
                if !receivedLetters.contains(where: { $0.id == id }) {
                    receivedLetters.append((id: id, title: title, content: content))
                }
            }
        }
    }
}
