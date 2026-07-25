import SwiftUI
import FirebaseFirestore

public struct TruthOrDareCustomView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var currentCard: String?
    @State private var isRevealed = false
    @State private var customEntries: [String: [TDCustomEntry]] = [:]
    @State private var showAddSheet = false
    @State private var addCategory = "Verdad"
    @State private var revealCount = 0

    private let categories = ["Verdad", "Reto", "Foto", "Video", "Picante", "Romanico", "Divertido", "Personalizado"]

    private let truthDefaults: [String] = [
        "Cual fue tu primera impresion de mi?",
        "Que es lo que mas te gusta de nuestra relacion?",
        "Cual fue tu momento favorito conmigo?",
        "Cuando supiste que me amabas?",
        "Que es lo que mas extranas cuando no estamos juntos?",
        "Cual es tu mayor miedo en la relacion?",
        "Que promesa quieres que te haga?",
        "Cual es tu recuerdo mas vergonzoso conmigo?",
        "Que es lo que mas te gusta de mi fisico?",
        "Cual fue tu cita favorita y por que?",
        "Que pelicula o cancion te recuerda a nosotros?",
        "Si pudieras cambiar algo de mi, que seria?",
        "Que es lo que mas valoras de mi personalidad?",
        "Cual es tu plan perfecto para un domingo juntos?",
    ]

    private let dareDefaults: [String] = [
        "Abrazame durante un minuto sin soltar",
        "Dame un beso en la mejilla",
        "Baila conmigo una cancion lenta",
        "Cantame tu cancion favorita",
        "Hazme reir con una cara graciosa",
        "Escribe algo bonito en mi brazo con tu dedo",
        "Preparame tu bebida favorita",
        "Inventa un apodo nuevo para nosotros",
        "Dibuja algo en un papel para mi",
        "Cuentame un chiste malo",
        "Masajea mis hombros por 2 minutos",
        "Bailame un baile ridiculo",
        "Haz un cumplido sincero sobre mi",
        "Tomate una foto conmigo ahora mismo",
    ]

    private let photoDefaults: [String] = [
        "Tomate una selfie haciendo una cara graciosa",
        "Foto de algo que te recuerde a mi",
        "Tomate una foto con mi prenda favorita puesta",
        "Foto de tu lugar favorito de la casa",
        "Selfie los dos en el espejo",
        "Foto de tu comida favorita que te guste compartir",
        "Foto de algo que hayas hecho hoy",
        "Foto de tu sonrisa mas bonita",
        "Foto de tus ojos de cerca",
        "Foto de un recuerdo nuestro que tengas cerca",
        "Foto de tu mano con la mia",
        "Foto de tu silueta contra la luz",
        "Foto de algo que te haga feliz ahora",
    ]

    private let videoDefaults: [String] = [
        "Graba un video de 10s diciendo 3 cosas que te gustan de mi",
        "Video bailando tu cancion favorita",
        "Graba un video imitando mi voz",
        "Video haciendo un saludo vergonzoso para mi",
        "Graba un lip sync de nuestra cancion",
        "Video cocinando algo rapido mientras me dedicas la receta",
        "Graba un mensaje sorpresa para mi futuro yo",
        "Video contando un secreto en camara lenta",
        "Graba un time-lapse de algo divertido que hagas",
        "Video de ti haciendo tu mejor pose de modelo",
        "Graba un mini tutorial de algo que sepas hacer",
        "Video soplando un beso a la camara",
    ]

    private let spicyDefaults: [String] = [
        "Besame de una forma que nunca hayamos hecho",
        "Susurrame algo prohibido al oido",
        "Quitame una prenda con los dientes",
        "Bailame una cancion sensual",
        "Pasame tu mano por debajo de mi ropa",
        "Lame mi cuello lentamente",
        "Dime lo que me haras esta noche en detalle",
        "Muerdeme el labio inferior suavemente",
        "Besa el lugar que mas te guste de mi",
        "Ponte detras de mi y abrazame por la cintura",
        "Haz el sonido que haces cuando sientes placer",
        "Susurra tu fantasia mas secreta",
        "Besa mi pecho lentamente",
    ]

    private let romanticDefaults: [String] = [
        "Que es lo que mas te gusta de mi?",
        "Describe tu dia perfecto conmigo",
        "Que fue lo primero que pensaste cuando me viste?",
        "Cual es tu recuerdo favorito de nosotros?",
        "Que es lo que mas te hace sentir amado/a?",
        "Cuando fue la ultima vez que sentiste mariposas?",
        "Que es lo que mas admiras de mi?",
        "Cual es tu promesa favorita que nos hemos hecho?",
        "Que cancion describe mejor nuestra relacion?",
        "Cual es el lugar mas romantico que has visitado conmigo?",
        "Que es lo que mas te gusta de como te trato?",
        "Cual fue el momento en el que mas te enamoraste de mi?",
    ]

    private let funnyDefaults: [String] = [
        "Haz la mejor imitacion de mi que puedas",
        "Cuenta el chiste mas malo que sepas",
        "Haz una voz graciosa y di algo bonito",
        "Baila como si nadie te estuviera viendo",
        "Inventa una historia ridicula sobre como nos conocimos",
        "Haz el sonido de tu animal favorito",
        "Cuenta tu recuerdo mas embarazoso de cuando eras nino",
        "Haz una pose de modelo bien exagerada",
        "Habla con acento extranjero por 30 segundos",
        "Canta una cancion inventada sobre nuestra relacion",
        "Haz mimica de una pelicula y adivina cual es",
        "Di un trabalenguas 3 veces seguidas",
        "Haz una cara graciosa y mantenla 10 segundos",
    ]

    private var defaultsMap: [String: [String]] {
        [
            "Verdad": truthDefaults,
            "Reto": dareDefaults,
            "Foto": photoDefaults,
            "Video": videoDefaults,
            "Picante": spicyDefaults,
            "Romanico": romanticDefaults,
            "Divertido": funnyDefaults,
            "Personalizado": [],
        ]
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 0) {
                    categoryTabs
                    cardArea
                    Spacer()
                    actionButtons
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Verdad o Reto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addCategory = categories[selectedTab]
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .onAppear { loadCustomEntries() }
            .sheet(isPresented: $showAddSheet) {
                AddDEView(category: $addCategory, onSave: { loadCustomEntries() })
            }
        }
    }

    private var categoryTabs: some View {
        TabView(selection: $selectedTab) {
            ForEach(categories.indices, id: \.self) { i in
                VStack {}.tabItem {
                    Image(systemName: tabIcon(for: categories[i]))
                    Text(categories[i])
                }.tag(i)
            }
        }
        .frame(height: 60)
        .onChange(of: selectedTab) { _, _ in
            withAnimation(.spring()) {
                currentCard = nil
                isRevealed = false
            }
        }
    }

    private var cardArea: some View {
        VStack(spacing: 16) {
            if let card = currentCard {
                VStack(spacing: 12) {
                    Text(isRevealed ? card : "? ? ?")
                        .appFont(size: 20, weight: .semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isRevealed ? theme.textPrimary : categoryColor(categories[selectedTab]))
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(categoryColor(categories[selectedTab]).opacity(0.3), lineWidth: 1)
                        )
                        .onTapGesture {
                            withAnimation(.spring()) { isRevealed = true }
                        }

                    if isRevealed {
                        HStack(spacing: 8) {
                            Text(categories[selectedTab])
                                .appFont(size: 12, weight: .bold)
                                .foregroundColor(categoryColor(categories[selectedTab]))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(categoryColor(categories[selectedTab]).opacity(0.12))
                                .clipShape(Capsule())

                            if let entry = findCurrentEntry(card) {
                                if entry.isCustom {
                                    Button {
                                        deleteEntry(entry)
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red.opacity(0.6))
                                            .padding(6)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: tabIcon(for: categories[selectedTab]))
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor(categories[selectedTab]).opacity(0.5))
                    Text("Toca para generar")
                        .appFont(size: 16, weight: .semibold)
                        .foregroundColor(theme.textSecondary)
                    Text(categories[selectedTab])
                        .appFont(size: 13, weight: .regular)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.vertical, 16)
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                generateCard()
            } label: {
                Label("Nueva carta", systemImage: "shuffle")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(categoryColor(categories[selectedTab]).opacity(0.2))
                    .foregroundColor(theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if currentCard != nil && isRevealed {
                Button {
                    generateCard()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(categoryColor(categories[selectedTab]))
                }
                .transition(.scale)
            }
        }
    }

    private func generateCard() {
        let cat = categories[selectedTab]
        let defaults = defaultsMap[cat] ?? []
        let customs = (customEntries[cat] ?? []).map(\.text)
        let all = defaults + customs

        guard !all.isEmpty else {
            currentCard = "No hay entradas en esta categoria"
            isRevealed = true
            return
        }

        var newCard: String
        repeat {
            newCard = all.randomElement() ?? ""
        } while newCard == currentCard && all.count > 1

        withAnimation(.spring()) {
            currentCard = newCard
            isRevealed = false
        }
    }

    private func findCurrentEntry(_ text: String) -> TDCustomEntry? {
        let cat = categories[selectedTab]
        return (customEntries[cat] ?? []).first { $0.text == text }
    }

    private func loadCustomEntries() {
        for cat in categories {
            guard cat != "Personalizado" else { continue }
            Task {
                let query = GameService.shared.streamTD(category: cat)
                let snapshot = try? await query.getDocuments()
                let entries = snapshot?.documents.compactMap { doc -> TDCustomEntry? in
                    guard let text = doc.data()["text"] as? String else { return nil }
                    return TDCustomEntry(id: doc.documentID, text: text, isCustom: true)
                } ?? []
                await MainActor.run {
                    customEntries[cat] = entries
                }
            }
        }
    }

    private func deleteEntry(_ entry: TDCustomEntry) {
        GameService.shared.deleteTD(entry.id)
        loadCustomEntries()
        if currentCard == entry.text {
            currentCard = nil
        }
        revealCount += 1
        GameService.shared.saveGameStats("verdad_reto", [
            "action": "deleted",
            "category": categories[selectedTab],
            "totalRevealed": revealCount,
        ])
    }

    private func tabIcon(for cat: String) -> String {
        switch cat {
        case "Verdad": return "text.bubble.fill"
        case "Reto": return "flame.fill"
        case "Foto": return "camera.fill"
        case "Video": return "video.fill"
        case "Picante": return "sparkles"
        case "Romanico": return "heart.fill"
        case "Divertido": return "face.smiling.fill"
        case "Personalizado": return "person.fill"
        default: return "questionmark"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Verdad": return Color.blue
        case "Reto": return Color.orange
        case "Foto": return Color.purple
        case "Video": return Color.pink
        case "Picante": return .red
        case "Romanico": return Color(red: 0.9, green: 0.2, blue: 0.4)
        case "Divertido": return Color.yellow
        case "Personalizado": return theme.primary
        default: return theme.primary
        }
    }
}

private struct TDCustomEntry {
    let id: String
    let text: String
    let isCustom: Bool
}

private struct AddDEView: View {
    @Binding var category: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var saving = false
    @ObservedObject private var theme = ThemeManager.shared

    private let categories = ["Verdad", "Reto", "Foto", "Video", "Picante", "Romanico", "Divertido"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Categoria", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Contenido:")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textSecondary)
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }

                Button {
                    saveEntry()
                } label: {
                    if saving {
                        ProgressView().tint(.white)
                    } else {
                        Label("Guardar", systemImage: "checkmark")
                            .appFont(size: 14, weight: .semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(text.trimmingCharacters(in: .whitespaces).isEmpty || saving ? Color.gray : theme.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || saving)
            }
            .padding(20)
            .navigationTitle("Nueva entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        saving = true
        GameService.shared.saveTD([
            "text": trimmed,
            "category": category,
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            saving = false
            onSave()
            dismiss()
        }
    }
}
