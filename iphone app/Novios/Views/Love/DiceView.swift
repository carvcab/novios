import SwiftUI
import FirebaseFirestore

private struct DiceModel: Identifiable {
    let id: String
    let name: String
    let faces: [String]
}

public struct DiceView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customDice: [DiceModel] = []
    @State private var selectedDice: DiceModel?
    @State private var isRolling = false
    @State private var displayText = "?"
    @State private var resultText = ""
    @State private var showResult = false
    @State private var rollCount = 0
    @State private var spinRotation: Double = 0
    @State private var showAddSheet = false
    @State private var editName = ""
    @State private var editFaces: [String] = []
    @State private var editNewFace = ""
    @State private var editingDiceId: String?
    @State private var listener: ListenerRegistration?
    @State private var editMode = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if editMode {
                    diceList
                } else {
                    VStack(spacing: 16) {
                        diceSelector
                        diceDisplay
                        if showResult {
                            resultCard
                        }
                        Spacer()
                        rollButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Dados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode ? "Listo" : "Editar") { editMode.toggle() }
                        .foregroundColor(theme.primary)
                }
            }
            .sheet(isPresented: $showAddSheet) { addDiceSheet }
            .onAppear { setupListener() }
            .onDisappear { listener?.remove() }
        }
    }

    private var diceList: some View {
        List {
            ForEach(customDice) { d in
                Button {
                    editName = d.name
                    editFaces = d.faces
                    editingDiceId = d.id
                    showAddSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.name).appFont(size: 14, weight: .semibold).foregroundColor(theme.textPrimary)
                            Text("\(d.faces.count) caras").appFont(size: 11).foregroundColor(theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "pencil.circle.fill").foregroundColor(theme.primary)
                    }
                }
            }
            .onDelete(perform: deleteDice)
        }
        .scrollContentBackground(.hidden)
    }

    private var diceSelector: some View {
        Group {
            if !customDice.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customDice) { d in
                            Button {
                                selectDice(d)
                            } label: {
                                Text(d.name)
                                    .appFont(size: 12, weight: .semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                     .background(selectedDice?.id == d.id ? theme.primary : Color.clear)
                                     .background(selectedDice?.id == d.id ? Color.clear : .ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(selectedDice?.id == d.id ? .white : theme.textPrimary)
                            }
                        }
                    }
                }
            } else {
                Text("Agrega un dado con el boton +")
                    .appFont(size: 14)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }

    private var diceDisplay: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.1) : .white)
                    .shadow(color: theme.primary.opacity(0.15), radius: 12)
                    .frame(width: 160, height: 160)
                Text(displayText)
                    .appFont(size: isRolling ? 28 : 44, weight: .bold)
                    .foregroundColor(theme.primary)
                    .rotationEffect(.degrees(spinRotation))
                    .scaleEffect(isRolling ? 0.8 : 1.0)
                    .animation(.interpolatingSpring(stiffness: 150, damping: 8), value: displayText)
            }
        }
    }

    private var resultCard: some View {
        HStack {
            Image(systemName: "star.fill").foregroundColor(theme.primary)
            Text(resultText).appFont(size: 18, weight: .bold).foregroundColor(theme.textPrimary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.scale.combined(with: .opacity))
    }

    private var rollButton: some View {
        Button {
            rollDice()
        } label: {
            Label(isRolling ? "Lanzando..." : "Lanzar Dado", systemImage: "dice.fill")
                .appFont(size: 16, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isRolling ? Color.gray : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .foregroundColor(.white)
        }
        .disabled(isRolling || selectedDice == nil)
    }

    private var addDiceSheet: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre del dado", text: $editName)
                }
                Section("Caras") {
                    HStack {
                        TextField("Nueva cara", text: $editNewFace)
                        Button {
                            let t = editNewFace.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            editFaces.append(t)
                            editNewFace = ""
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(theme.primary)
                        }
                    }
                    ForEach(editFaces, id: \.self) { face in
                        Text(face).appFont(size: 14).foregroundColor(theme.textPrimary)
                    }
                    .onDelete { editFaces.remove(atOffsets: $0) }
                }
            }
            .navigationTitle(editingDiceId != nil ? "Editar dado" : "Nuevo dado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveDice() }.disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty || editFaces.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetDiceFields()
                        showAddSheet = false
                    }
                }
            }
        }
    }

    private func rollDice() {
        guard let d = selectedDice, !d.faces.isEmpty else { return }
        isRolling = true
        showResult = false
        resultText = ""
        rollCount = 0
        let cycles = 20
        let faces = d.faces
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            rollCount += 1
            displayText = faces.randomElement() ?? "?"
            spinRotation += 30
            if rollCount >= cycles {
                timer.invalidate()
                let finalResult = faces.randomElement() ?? "1"
                displayText = finalResult
                resultText = "Resultado: \(finalResult)"
                isRolling = false
                withAnimation { showResult = true }
                GameService.shared.saveGameStats("dice", ["result": finalResult, "faces": faces.count])
            }
        }
    }

    private func selectDice(_ d: DiceModel) {
        selectedDice = d
        showResult = false
        resultText = ""
        displayText = "?"
        spinRotation = 0
    }

    private func setupListener() {
        listener = GameService.shared.streamDice().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            customDice = docs.compactMap { doc in
                let d = doc.data()
                guard let name = d["name"] as? String, let faces = d["faces"] as? [String] else { return nil }
                return DiceModel(id: doc.documentID, name: name, faces: faces)
            }
            if let sel = selectedDice, !customDice.contains(where: { $0.id == sel.id }) {
                selectedDice = nil
            }
            if selectedDice == nil, let first = customDice.first {
                selectDice(first)
            }
        }
    }

    private func saveDice() {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !editFaces.isEmpty else { return }
        if let id = editingDiceId {
            GameService.shared.saveDice(["name": name, "faces": editFaces], id: id)
        } else {
            GameService.shared.saveDice(["name": name, "faces": editFaces])
        }
        resetDiceFields()
        showAddSheet = false
    }

    private func deleteDice(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deleteDice(customDice[idx].id)
        }
    }

    private func resetDiceFields() {
        editName = ""
        editFaces = []
        editNewFace = ""
        editingDiceId = nil
    }
}
