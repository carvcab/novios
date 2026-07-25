import SwiftUI
import FirebaseFirestore

private struct DiceModel: Identifiable {
    let id: String
    let name: String
    let faces: [String]
}

private let standardOptions = [6, 8, 10, 20]

public struct DiceView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customDice: [DiceModel] = []
    @State private var selectedDice: DiceModel?
    @State private var useStandard = true
    @State private var standardFaces = 6
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

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    modePicker
                    diceDisplay
                    if showResult {
                        resultCard
                    }
                    Spacer()
                    rollButton
                }
                .padding()
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
            }
            .sheet(isPresented: $showAddSheet) { addDiceSheet }
            .onAppear { setupListener() }
            .onDisappear { listener?.remove() }
        }
    }

    private var modePicker: some View {
        Picker("Tipo", selection: $useStandard) {
            Text("Estandar").tag(true)
            Text("Personalizado").tag(false)
        }
        .pickerStyle(.segmented)
        .onChange(of: useStandard) { _ in
            resetResult()
        }
    }

    private var diceDisplay: some View {
        VStack(spacing: 8) {
            if !useStandard {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customDice) { d in
                            Button {
                                selectedDice = d
                                resetResult()
                            } label: {
                                Text(d.name)
                                    .appFont(size: 12, weight: .semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedDice?.id == d.id ? theme.primary : .ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(selectedDice?.id == d.id ? .white : theme.textPrimary)
                            }
                        }
                    }
                }
            }
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
            if useStandard {
                Picker("Caras", selection: $standardFaces) {
                    ForEach(standardOptions, id: \.self) { n in
                        Text("\(n) caras").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: standardFaces) { _ in resetResult() }
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
        .disabled(isRolling)
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
                Section("Tus dados") {
                    ForEach(customDice) { d in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(d.name).appFont(size: 14, weight: .semibold).foregroundColor(theme.textPrimary)
                                Text("\(d.faces.count) caras").appFont(size: 11).foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Button("Editar") {
                                editName = d.name
                                editFaces = d.faces
                                editingDiceId = d.id
                            }
                            .appFont(size: 12).foregroundColor(theme.primary)
                        }
                    }
                    .onDelete(perform: deleteDice)
                }
            }
            .navigationTitle("Nuevo dado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveDice() }.disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty || editFaces.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showAddSheet = false }
                }
            }
        }
    }

    private func rollDice() {
        isRolling = true
        showResult = false
        resultText = ""
        rollCount = 0
        let cycles = 20
        let faces: [String]
        if useStandard {
            faces = (1...standardFaces).map(String.init)
        } else if let d = selectedDice, !d.faces.isEmpty {
            faces = d.faces
        } else {
            faces = (1...6).map(String.init)
        }
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

    private func resetResult() {
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
            if !useStandard, selectedDice == nil, let first = customDice.first {
                selectedDice = first
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
        editName = ""
        editFaces = []
        editNewFace = ""
        editingDiceId = nil
        showAddSheet = false
    }

    private func deleteDice(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deleteDice(customDice[idx].id)
        }
    }
}
