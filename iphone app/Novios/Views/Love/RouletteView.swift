import SwiftUI
import FirebaseFirestore

public struct RouletteView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var items: [String] = []
    @State private var newItem = ""
    @State private var showAddField = false
    @State private var isSpinning = false
    @State private var rotation: Double = 0
    @State private var selectedResult: String?
    @State private var showResult = false
    @State private var editMode: EditMode = .inactive

    private let defaultsKey = "roulette_items"
    private let defaultItems = ["Beso", "Abrazo", "Masaje", "Cumplido", "Baile", "Sorpresa", "Confesion", "Selfie"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    if editMode == .inactive {
                        wheelSection
                        if let result = selectedResult {
                            resultCard(result)
                        }
                        Spacer()
                        spinButton
                    } else {
                        editSection
                    }
                }
                .padding()
            }
            .navigationTitle("Ruleta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode == .inactive ? "Editar" : "Listo") {
                        withAnimation { editMode = editMode == .inactive ? .active : .inactive }
                    }
                }
            }
            .onAppear { loadItems() }
        }
    }

    private var wheelSection: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let angle = 360.0 / Double(items.count) * Double(index)
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
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        let angle = 360.0 / Double(items.count) * Double(index)
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
                Text("TOCA")
                    .appFont(size: 8, weight: .bold)
                    .foregroundColor(theme.primary)
            }
            .offset(y: -150)
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
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
        .disabled(isSpinning || items.isEmpty)
    }

    private var editSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Nueva opcion...", text: $newItem)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button {
                    addItem()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(theme.primary)
                }
                .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            List {
                ForEach(items, id: \.self) { item in
                    Text(item).appFont(size: 14).foregroundColor(theme.textPrimary)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .listStyle(.plain)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func spin() {
        guard !items.isEmpty else { return }
        isSpinning = true
        selectedResult = nil
        withAnimation(.showResult) { showResult = false }

        let fullSpins = 5.0 + Double.random(in: 0...1)
        let segmentAngle = 360.0 / Double(items.count)
        let randomIndex = Int.random(in: 0..<items.count)
        let targetAngle = 360.0 * fullSpins + Double(randomIndex) * segmentAngle

        withAnimation(.easeOut(duration: 3.0)) {
            rotation += targetAngle
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            selectedResult = items[randomIndex]
            isSpinning = false
            withAnimation { showResult = true }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            items.append(trimmed)
            newItem = ""
        }
        saveItems()
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }

    private func segmentColor(index: Int) -> Color {
        let colors: [Color] = [theme.primary, theme.secondary, Color.orange, Color.blue.opacity(0.5), Color.green.opacity(0.5), Color.purple.opacity(0.5), Color.pink, Color.teal]
        return colors[index % colors.count]
    }

    private func loadItems() {
        if let saved = UserDefaults.standard.array(forKey: defaultsKey) as? [String], !saved.isEmpty {
            items = saved
        } else {
            items = defaultItems
        }
    }

    private func saveItems() {
        UserDefaults.standard.set(items, forKey: defaultsKey)
    }
}

extension Animation {
    static var showResult: Animation { .spring(response: 0.4, dampingFraction: 0.7) }
}
