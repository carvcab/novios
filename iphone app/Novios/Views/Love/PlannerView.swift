import SwiftUI
import UIKit
import FirebaseFirestore

struct PlannerItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: String
    var doneTogether: Bool
    let dateAdded: Date
}

public struct PlannerView: View {
    @State private var items: [PlannerItem] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var showSurprise = false
    @State private var surpriseIdea: (title: String, desc: String)? = nil
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()
    private let tabs = ["movie", "series", "restaurant", "trip"]
    private let tabIcons = ["movie.fill", "tv.fill", "fork.knife", "airplane"]
    private let tabLabels = ["Películas", "Series", "Restaurantes", "Viajes"]

    private let dateIdeas: [(title: String, desc: String)] = [
        ("Cine bajo las Estrellas 🌌", "Preparen mantas en la terraza o jardín, usen un proyector o laptop, y vean su película romántica favorita acompañados de palomitas dulces y luces tenues."),
        ("Pícnic en la Sala 🧺", "Pongan un mantel de cuadros en el suelo de la sala, preparen aperitivos rápidos (quesos, uvas, sándwiches) y disfruten de música suave en segundo plano."),
        ("Cena Temática de Viaje ✈️", "Elijan un país al que les gustaría viajar juntos (Italia, Japón, México) y preparen o pidan comida típica de ese país mientras ven un documental del lugar."),
        ("Noche de Juegos de Mesa 🎲", "Reúnan sus juegos de mesa favoritos (o cartas) y jueguen rondas donde el perdedor tiene que hacerle un masaje al ganador o prepararle su postre favorito."),
        ("Maratón de Recuerdos 📸", "Junten todas las fotos y videos que se han tomado desde que se conocieron, preparen una bebida rica y dediquen la noche a recordar los momentos divertidos."),
        ("Sesión de Cocina Juntos 🧑‍🍳", "Elijan una receta dulce o plato complejo que nunca hayan preparado, pónganse música y diviértanse cocinándola desde cero en equipo."),
        ("Cápsula del Tiempo Romántica ⏳", "Escriban cartas contándose cómo se ven en 5 años, junten pequeños recuerdos de hoy y guárdenlos en una cajita especial para abrirla en una fecha futura pactada."),
        ("Paseo de Fotos por la Ciudad 🗺️", "Salgan a caminar por un barrio bonito de su ciudad con el único objetivo de tomarse fotos creativas u artísticas entre sí."),
        ("Noche de Preguntas Profundas 💬", "Busquen preguntas interesantes o usen tarjetas de conversación para conocerse aún más a fondo, hablando de sus mayores sueños, miedos y recuerdos tiernos."),
        ("Spa en Casa 🕯️", "Enciendan velas aromáticas, pongan música ambiental zen y preparen masajes relajantes mutuos con aceites perfumados y mascarillas faciales."),
    ]

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var plannerRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("planner")
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 0) {
                    customSegmentedPicker
                    filteredList
                }
            }
            .navigationTitle("Organizador de Planes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Organizador de Planes")
                        .appFont(size: 14, weight: .medium)
                        .foregroundColor(theme.textPrimary)
                        .tracking(3)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSurprise = true } label: {
                        Image(systemName: "lightbulb")
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.2))
                            .font(.system(size: 18))
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                fabButton
            }
            .sheet(isPresented: $showAddSheet) { addItemSheet }
            .sheet(isPresented: $showSurprise) { surpriseSheet }
            .onAppear { startListener() }
            .onDisappear { snapshotListener?.remove() }
        }
    }

    // MARK: - Custom Segmented Picker

    private var customSegmentedPicker: some View {
        HStack(spacing: 4) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tabIcons[i])
                            .font(.system(size: 17))
                        Text(tabLabels[i])
                            .appFont(size: 9, weight: .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == i ? .white : theme.textSecondary.opacity(0.6))
                    .background(selectedTab == i ? theme.primary : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Filtered List

    private var filteredList: some View {
        let type = tabs[selectedTab]
        let filtered = items.filter { $0.type == type }.sorted { $0.dateAdded > $1.dateAdded }
        return Group {
            if filtered.isEmpty {
                emptyState(for: type)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { item in
                            itemCard(item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private func emptyState(for type: String) -> some View {
        let icon: String
        switch type {
        case "movie": icon = "movie.fill"
        case "series": icon = "tv.fill"
        case "restaurant": icon = "fork.knife"
        case "trip": icon = "airplane"
        default: icon = "calendar"
        }
        return VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(theme.textSecondary.opacity(0.15))
            Text("No hay planes listados aún")
                .appFont(size: 14)
                .foregroundColor(theme.textSecondary.opacity(0.5))
            Spacer()
        }
    }

    // MARK: - Item Card

    private func itemCard(_ item: PlannerItem) -> some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 14) {
                typeIcon(item.type)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .appFont(size: 15, weight: .semibold)
                        .foregroundColor(item.doneTogether ? theme.textSecondary.opacity(0.5) : theme.textPrimary)
                        .strikethrough(item.doneTogether)
                    if !item.description.isEmpty {
                        Text(item.description)
                            .appFont(size: 12)
                            .foregroundColor(item.doneTogether ? theme.textSecondary.opacity(0.3) : theme.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                checkCircle(item)
            }
        }
    }

    private func typeIcon(_ type: String) -> some View {
        let icon: String
        let color: Color
        switch type {
        case "movie":
            icon = "movie.fill"
            color = Color(red: 0.31, green: 0.76, blue: 0.97)
        case "series":
            icon = "tv.fill"
            color = Color(red: 1.0, green: 0.72, blue: 0.30)
        case "restaurant":
            icon = "fork.knife"
            color = Color(red: 1.0, green: 0.50, blue: 0.50)
        case "trip":
            icon = "airplane"
            color = Color(red: 0.49, green: 0.51, blue: 1.0)
        default:
            icon = "calendar"
            color = theme.primary
        }
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
        }
    }

    private func checkCircle(_ item: PlannerItem) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            toggleDone(item)
        } label: {
            ZStack {
                Circle()
                    .stroke(item.doneTogether ? Color.green : theme.textSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(item.doneTogether ? Color.green.opacity(0.15) : Color.clear)
                    )
                if item.doneTogether {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(theme.primary)
                .clipShape(Circle())
                .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Add Item Sheet

    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var newType = "movie"
    @State private var newDoneTogether = false

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título", text: $newTitle)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Título")
                }
                Section {
                    TextField("Descripción / Notas", text: $newDescription)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Descripción")
                }
                Section {
                    Picker("Tipo", selection: $newType) {
                        Label("Película", systemImage: "movie.fill").tag("movie")
                        Label("Serie", systemImage: "tv.fill").tag("series")
                        Label("Restaurante", systemImage: "fork.knife").tag("restaurant")
                        Label("Viaje", systemImage: "airplane").tag("trip")
                    }
                }
                Section {
                    Toggle(isOn: $newDoneTogether) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(theme.primary)
                            Text("Hecho juntos")
                        }
                    }
                }
            }
            .navigationTitle("Agregar Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveNewItem() }
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveNewItem() {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        let id = "\(Date().timeIntervalSince1970 * 1000)"
        let item = PlannerItem(
            id: id,
            title: trimmedTitle,
            description: newDescription.trimmingCharacters(in: .whitespaces),
            type: newType,
            doneTogether: newDoneTogether,
            dateAdded: Date()
        )
        savePlannerItem(item)
        newTitle = ""
        newDescription = ""
        newType = "movie"
        newDoneTogether = false
        showAddSheet = false
    }

    // MARK: - Surprise Sheet

    private var surpriseSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "lightbulb")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.2))
                Text("Idea Sorpresa de Cita 💡")
                    .appFont(size: 20, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                if let idea = surpriseIdea {
                    GlassCard(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(idea.title)
                                .appFont(size: 17, weight: .bold)
                                .foregroundColor(theme.primary)
                            Text(idea.desc)
                                .appFont(size: 13)
                                .foregroundColor(theme.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        refreshSurpriseIdea()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("Otra idea")
                                .appFont(size: 14, weight: .medium)
                        }
                        .foregroundColor(Color.cyan)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        saveSurpriseIdea()
                    } label: {
                        HStack(spacing: 6) {
                            Text("¡Hagámoslo! 💖")
                                .appFont(size: 14, weight: .semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { showSurprise = false }
                }
            }
            .onAppear { refreshSurpriseIdea() }
        }
        .presentationDetents([.height(480)])
    }

    private func refreshSurpriseIdea() {
        guard let idea = dateIdeas.randomElement() else { return }
        surpriseIdea = idea
    }

    private func saveSurpriseIdea() {
        guard let idea = surpriseIdea else { return }
        let id = "\(Date().timeIntervalSince1970 * 1000)"
        let item = PlannerItem(
            id: id,
            title: idea.title,
            description: idea.desc,
            type: "trip",
            doneTogether: false,
            dateAdded: Date()
        )
        savePlannerItem(item)
        showSurprise = false
    }

    // MARK: - Firestore

    private func startListener() {
        snapshotListener?.remove()
        snapshotListener = plannerRef.addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let parsed = docs.compactMap { doc -> PlannerItem? in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let type = data["type"] as? String else { return nil }
                let id = doc.documentID
                let description = data["description"] as? String ?? ""
                let doneTogether = data["doneTogether"] as? Bool ?? false
                let dateAdded: Date
                if let ts = data["dateAdded"] as? Timestamp {
                    dateAdded = ts.dateValue()
                } else if let iso = data["dateAdded"] as? String {
                    dateAdded = ISO8601DateFormatter().date(from: iso) ?? Date()
                } else {
                    dateAdded = Date()
                }
                return PlannerItem(id: id, title: title, description: description, type: type, doneTogether: doneTogether, dateAdded: dateAdded)
            }
            DispatchQueue.main.async {
                self.items = parsed
            }
        }
    }

    private func savePlannerItem(_ item: PlannerItem) {
        var data: [String: Any] = [
            "id": item.id,
            "title": item.title,
            "type": item.type,
            "doneTogether": item.doneTogether,
            "dateAdded": Timestamp(date: item.dateAdded),
        ]
        if !item.description.isEmpty {
            data["description"] = item.description
        }
        plannerRef.document(item.id).setData(data, merge: true)
    }

    private func toggleDone(_ item: PlannerItem) {
        var updated = item
        updated.doneTogether.toggle()
        savePlannerItem(updated)
    }

    private func deleteItem(_ item: PlannerItem) {
        plannerRef.document(item.id).delete()
    }
}
