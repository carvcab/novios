import SwiftUI
import FirebaseFirestore

private struct RouletteModel: Identifiable {
    let id: String
    let name: String
    let items: [String]
    let colorHex: String
}

private let defaultItems = ["Beso", "Abrazo", "Masaje", "Cumplido", "Baile", "Sorpresa", "Confesion", "Selfie"]

public struct RouletteView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customRoulettes: [RouletteModel] = []
    @State private var selectedRoulette: RouletteModel?
    @State private var useClassic = true
    @State private var currentItems: [String] = defaultItems
    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var selectedResult: String?
    @State private var showResult = false
    @State private var showAddSheet = false
    @State private var editName = ""
    @State private var editItems: [String] = []
    @State private var editNewItem = ""
    @State private var editColor = "#FF69B4"
    @State private var editingRouletteId: String?
    @State private var listener: ListenerRegistration?

    private let colors: [Color] = [.pink, .purple, .orange, .blue, .green, .red, .teal, .yellow]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 12) {
                    modePicker
                    wheelSection
                    if let result = selectedResult {
                        resultCard(result)
                    }
                    Spacer()
                    spinButton
                }
                .padding()
            }
            .navigationTitle("Ruleta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addRouletteSheet }
            .onAppear { setupListener() }
            .onDisappear { listener?.remove() }
        }
    }

    private var modePicker: some View {
        Picker("Modo", selection: $useClassic) {
            Text("Clasico").tag(true)
            Text("Personalizado").tag(false)
        }
        .pickerStyle(.segmented)
        .onChange(of: useClassic) { _ in
            if useClassic {
                currentItems = defaultItems
                selectedRoulette = nil
            } else if let first = customRoulettes.first {
                selectRoulette(first)
            } else {
                currentItems = []
            }
            selectedResult = nil
            rotation = 0
            showResult = false
        }
    }

    private var wheelSection: some View {
        VStack(spacing: 0) {
            if !useClassic && !customRoulettes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customRoulettes) { r in
                            Button {
                                selectRoulette(r)
                            } label: {
                                Text(r.name)
                                    .appFont(size: 12, weight: .semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedRoulette?.id == r.id ? theme.primary : .ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(selectedRoulette?.id == r.id ? .white : theme.textPrimary)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            ZStack {
                ForEach(Array(currentItems.enumerated()), id: \.offset) { index, item in
                    let angle = 360.0 / Double(currentItems.count) * Double(index)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(segmentColor(index: index))
                        .frame(width: 4, height: 120)
                        .offset(y: -60)
                        .rotationEffect(.degrees(angle))
                }
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                    .frame(width: 160, height: 160)
                Circle()
                    .stroke(theme.primary.opacity(0.15), lineWidth: 1)
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(rotation))
                    .overlay(
                        ForEach(Array(currentItems.enumerated()), id: \.offset) { index, item in
                            let angle = 360.0 / Double(currentItems.count) * Double(index)
                            Text(item.prefix(3))
                                .appFont(size: 9, weight: .bold)
                                .foregroundColor(theme.textPrimary)
                                .rotationEffect(.degrees(-rotation))
                                .offset(y: -100)
                                .rotationEffect(.degrees(angle))
                        }
                    )
                VStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.primary)
                }
                .offset(y: -150)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
        }
    }

    private func resultCard(_ result: String) -> some View {
        HStack {
            Image(systemName: "heart.fill").foregroundColor(theme.primary)
            Text(result).appFont(size: 20, weight: .bold).foregroundColor(theme.textPrimary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.scale.combined(with: .opacity))
    }

    private var spinButton: some View {
        Button {
            spin()
        } label: {
            Label(isSpinning ? "Girando..." : "Girar", systemImage: "arrow.triangle.2.circlepath")
                .appFont(size: 16, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isSpinning ? Color.gray : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .foregroundColor(.white)
        }
        .disabled(isSpinning || currentItems.isEmpty)
    }

    private var addRouletteSheet: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre de la ruleta", text: $editName)
                }
                Section("Opciones") {
                    HStack {
                        TextField("Nueva opcion", text: $editNewItem)
                        Button {
                            let t = editNewItem.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            editItems.append(t)
                            editNewItem = ""
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(theme.primary)
                        }
                    }
                    ForEach(editItems, id: \.self) { item in
                        Text(item).appFont(size: 14).foregroundColor(theme.textPrimary)
                    }
                    .onDelete { editItems.remove(atOffsets: $0) }
                }
                Section("Tus ruletas") {
                    ForEach(customRoulettes) { r in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(r.name).appFont(size: 14, weight: .semibold).foregroundColor(theme.textPrimary)
                                Text("\(r.items.count) opciones").appFont(size: 11).foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Button("Editar") {
                                editName = r.name
                                editItems = r.items
                                editingRouletteId = r.id
                            }
                            .appFont(size: 12).foregroundColor(theme.primary)
                        }
                    }
                    .onDelete(perform: deleteRoulette)
                }
            }
            .navigationTitle("Nueva ruleta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveRoulette() }.disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty || editItems.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showAddSheet = false }
                }
            }
        }
    }

    private func spin() {
        guard !currentItems.isEmpty else { return }
        isSpinning = true
        selectedResult = nil
        showResult = false
        let fullSpins = 5.0 + Double.random(in: 0...1)
        let segmentAngle = 360.0 / Double(currentItems.count)
        let randomIndex = Int.random(in: 0..<currentItems.count)
        let targetAngle = 360.0 * fullSpins + Double(randomIndex) * segmentAngle
        withAnimation(.easeOut(duration: 3.0)) {
            rotation += targetAngle
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            selectedResult = currentItems[randomIndex]
            isSpinning = false
            withAnimation { showResult = true }
            GameService.shared.saveGameStats("roulette", ["result": selectedResult ?? ""])
        }
    }

    private func selectRoulette(_ r: RouletteModel) {
        selectedRoulette = r
        currentItems = r.items
        selectedResult = nil
        rotation = 0
        showResult = false
    }

    private func segmentColor(index: Int) -> Color {
        colors[index % colors.count]
    }

    private func setupListener() {
        listener = GameService.shared.streamRoulettes().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            customRoulettes = docs.compactMap { doc in
                let d = doc.data()
                guard let name = d["name"] as? String, let items = d["items"] as? [String] else { return nil }
                return RouletteModel(id: doc.documentID, name: name, items: items, colorHex: d["color"] as? String ?? "#FF69B4")
            }
            if !useClassic, selectedRoulette == nil, let first = customRoulettes.first {
                selectRoulette(first)
            }
        }
    }

    private func saveRoulette() {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !editItems.isEmpty else { return }
        if let id = editingRouletteId {
            GameService.shared.saveRoulette(["name": name, "items": editItems, "color": editColor], id: id)
        } else {
            GameService.shared.saveRoulette(["name": name, "items": editItems, "color": editColor])
        }
        editName = ""
        editItems = []
        editNewItem = ""
        editingRouletteId = nil
        showAddSheet = false
    }

    private func deleteRoulette(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deleteRoulette(customRoulettes[idx].id)
        }
    }
}
