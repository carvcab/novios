import SwiftUI

public struct LoveLettersView: View {
    @State private var letters: [(title: String, content: String)] = [
        ("Abrir cuando estés triste 🌧️", "Recuerda que no estoy solo/a. Te amo incondicionalmente y siempre estaré a tu lado."),
        ("Abrir cuando me extrañes 💔", "Cierra los ojos e imagina un abrazo fuerte. Cada segundo sin ti me hace valorar más nuestro amor."),
        ("Abrir en tu cumpleaños 🎂", "¡Feliz cumpleaños al amor de mi vida! Gracias por llenar mis días de felicidad."),
        ("Abrir cuando no puedas dormir 🌙", "Piensa en todos nuestros momentos mágicos. Descansa bien mi vida."),
        ("Abrir cuando estés enojado/a 😤", "Te amo incluso cuando estamos enojados. Esto también pasará."),
        ("Abrir cuando dudes de ti 💪", "Eres increíble. No dejes que nadie te haga sentir menos."),
    ]
    @State private var openLetter: (title: String, content: String)? = nil
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
                        Text("Cartas de Amor 💌").font(.system(size: 24, weight: .bold)).foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)

                        if !receivedLetters.isEmpty {
                            Text("Recibidas").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                            ForEach(receivedLetters, id: \.id) { letter in
                                GlassCard {
                                    Button {
                                        openLetter = (letter.title, letter.content)
                                        logLetterOpened(letter)
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "envelope.fill").font(.system(size: 24)).foregroundColor(ThemeManager.shared.primaryPink)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(letter.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                                                Text(letter.content.prefix(60) + "...").font(.system(size: 11)).foregroundColor(.primary.opacity(0.5))
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.primary.opacity(0.3))
                                        }
                                    }
                                }.padding(.horizontal, 20)
                            }
                        }

                        Text("Sobres para abrir").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(letters.indices, id: \.self) { i in
                                Button {
                                    openLetter = letters[i]
                                    sendLetterToPartner(letters[i])
                                } label: {
                                    GlassCard {
                                        VStack(spacing: 12) {
                                            Image(systemName: "envelope.badge.shield.halffilled")
                                                .font(.system(size: 36)).foregroundColor(ThemeManager.shared.primaryPink)
                                            Text(letters[i].title).font(.system(size: 13, weight: .bold)).foregroundColor(.primary)
                                                .multilineTextAlignment(.center).lineLimit(2)
                                        }.frame(height: 110).padding(4)
                                    }
                                }
                            }
                        }.padding(.horizontal, 20)

                        Button {
                            showCompose = true
                        } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Escribir carta personalizada").font(.system(size: 14, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Spacer()
                                }
                            }
                        }.padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Cartas")
            .sheet(item: $openLetter.map()) { letter in
                letterDetailView(letter)
            }
            .alert("Nueva carta", isPresented: $showCompose) {
                TextField("Título", text: $newTitle)
                TextField("Contenido", text: $newContent)
                Button("Cancelar", role: .cancel) { newTitle = ""; newContent = "" }
                Button("Enviar") {
                    if !newTitle.isEmpty && !newContent.isEmpty {
                        sendCustomLetter(title: newTitle, content: newContent)
                        newTitle = ""; newContent = ""
                    }
                }
            }
            .task { await loadReceivedLetters() }
        }
    }

    private func letterDetailView(_ letter: (title: String, content: String)) -> some View {
        ZStack {
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "envelope.open.fill").font(.system(size: 60)).foregroundStyle(ThemeManager.shared.neonGlowGradient)
                Text(letter.title).font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                Text(letter.content).font(.system(size: 16)).foregroundColor(ThemeManager.shared.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
                Button("Cerrar") { openLetter = nil }
                    .font(.system(size: 16, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
            }.padding()
        }
    }

    private func sendLetterToPartner(_ letter: (title: String, content: String)) {
        Task {
            await FirestoreSyncService.shared.saveLetter(title: letter.title, content: letter.content, emoji: "💌")
        }
    }

    private func sendCustomLetter(title: String, content: String) {
        Task {
            await FirestoreSyncService.shared.saveLetter(title: title, content: content, emoji: "💌")
            openLetter = (title, content)
        }
    }

    private func logLetterOpened(_ letter: (id: String, title: String, content: String)) {
        Task {
            await FirestoreSyncService.shared.logActivity(type: "letter_read", description: "Leyó: \(letter.title)")
        }
    }

    private func loadReceivedLetters() async {
        if let cid = coupleId {
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

    private var coupleId: String? {
        guard let myUid = FirebaseRESTService.shared.localId else { return nil }
        let partnerUid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
        guard !partnerUid.isEmpty else { return nil }
        return [myUid, partnerUid].sorted().joined(separator: "_")
    }
}

private extension Binding where Value == (title: String, content: String)? {
    func map() -> Binding<IdentifiableLetter?> {
        Binding<IdentifiableLetter?>(
            get: { self.wrappedValue.map { IdentifiableLetter(title: $0.title, content: $0.content) } },
            set: { self.wrappedValue = $0.map { (title: $0.title, content: $0.content) } }
        )
    }
}

private struct IdentifiableLetter: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}
