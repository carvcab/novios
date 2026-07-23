import SwiftUI
import FirebaseFirestore

public struct WishlistView: View {
    @State private var items: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var editingIndex: Int? = nil
    @State private var editingItemData: [String: Any] = [:]
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private let categories: [String: (name: String, color: Color)] = [
        "adventure": ("Aventura 🧗", Color(red: 0.67, green: 0.28, blue: 0.74)),
        "food": ("Cena/Comida 🍕", Color(red: 1, green: 0.72, blue: 0.30)),
        "movie": ("Cine/Serie 🎬", Color(red: 0.31, green: 0.76, blue: 0.97)),
        "trip": ("Viajar ✈️", Color(red: 0.49, green: 0.51, blue: 1)),
        "home": ("En Casa 🏠", Color(red: 0.4, green: 0.73, blue: 0.42)),
        "other": ("Otro 🌟", Color(red: 0.55, green: 0.57, blue: 0.67)),
    ]

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var listsDoc: DocumentReference {
        db.collection("couples").document(coupleId).collection("lists").document("wishlist")
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if items.isEmpty {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationTitle("Lista de Deseos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primaryPink)
                    }
                }
            }
            .onAppear { startListening() }
            .onDisappear { snapshotListener?.remove() }
            .sheet(isPresented: $showAddSheet) {
                WishlistFormView(onSave: addItem)
            }
            .sheet(isPresented: $showEditSheet) {
                WishlistFormView(existing: editingItemData, onSave: { updated in
                    if let idx = editingIndex {
                        updateItem(at: idx, with: updated)
                    }
                })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryPink.opacity(0.5))
            Text("Lista vacía")
                .appFont(size: 18, weight: .semibold)
            Text("¿Qué quieren hacer juntos? 💫")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private var mainContent: some View {
        let pending = items.filter { ($0["done"] as? Bool) != true }
        let completed = items.filter { ($0["done"] as? Bool) == true }
        let progress = items.isEmpty ? 0.0 : Double(completed.count) / Double(items.count)

        return ScrollView {
            VStack(spacing: 0) {
                GlassCard(cornerRadius: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(theme.primaryPink.opacity(0.15), lineWidth: 5)
                                .frame(width: 60, height: 60)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(colors: [theme.primaryPink, theme.secondary],
                                                   startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: progress)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22))
                                .foregroundColor(theme.primaryPink)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progreso de Deseos")
                                .appFont(size: 15, weight: .bold)
                            Text("¡Llevan \(completed.count) de \(items.count) deseos cumplidos juntos! 🎉")
                                .appFont(size: 12)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                if !pending.isEmpty {
                    sectionHeader(icon: "star.fill", color: Color(red: 0.83, green: 0.69, blue: 0.22),
                                  title: "Pendientes (\(pending.count))")
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    LazyVStack(spacing: 10) {
                        ForEach(items.indices, id: \.self) { i in
                            let item = items[i]
                            if (item["done"] as? Bool) != true {
                                wishItemView(item, index: i)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !completed.isEmpty {
                    sectionHeader(icon: "checkmark.circle.fill", color: .green,
                                  title: "Cumplidos (\(completed.count))")
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    LazyVStack(spacing: 10) {
                        ForEach(items.indices, id: \.self) { i in
                            let item = items[i]
                            if (item["done"] as? Bool) == true {
                                wishItemView(item, index: i)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Color.clear.frame(height: 80)
            }
        }
    }

    private func sectionHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(title)
                .appFont(size: 15, weight: .bold)
            Spacer()
        }
    }

    private func wishItemView(_ item: [String: Any], index: Int) -> some View {
        let done = (item["done"] as? Bool) ?? false
        let title = item["title"] as? String ?? ""
        let desc = item["desc"] as? String ?? ""
        let date = item["date"] as? String ?? ""
        let catKey = item["category"] as? String ?? "other"
        let proposedBy = item["proposedBy"] as? String ?? "both"
        let cat = categories[catKey] ?? categories["other"]!

        let proposerText: String = {
            switch proposedBy {
            case "me": return "Propuesto por Mí 🙋"
            case "partner": return "Propuesto por Pareja 👩‍❤️‍👨"
            default: return "Ambos 💑"
            }
        }()

        return GlassCard(cornerRadius: 16) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    toggleItem(at: index)
                } label: {
                    ZStack {
                        Circle()
                            .stroke(done ? Color.green : theme.primaryPink.opacity(0.5), lineWidth: 2)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(done ? Color.green.opacity(0.15) : theme.primaryPink.opacity(0.08))
                            )
                        if done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .appFont(size: 15, weight: .semibold)
                        .strikethrough(done)
                        .foregroundColor(done ? .secondary : .primary)

                    if !desc.isEmpty {
                        Text(desc)
                            .appFont(size: 12)
                            .foregroundColor(done ? .secondary.opacity(0.6) : .secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        Text(cat.name)
                            .appFont(size: 9, weight: .bold)
                            .foregroundColor(cat.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(cat.color.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(cat.color.opacity(0.3), lineWidth: 0.5))

                        Text(proposerText)
                            .appFont(size: 9)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())

                        Spacer()

                        if !date.isEmpty {
                            Text(date)
                                .appFont(size: 10)
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteItem(at: index)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
            .onLongPressGesture {
                editingIndex = index
                editingItemData = item
                showEditSheet = true
            }
        }
    }
}

// MARK: - Firestore Operations

extension WishlistView {
    private func startListening() {
        snapshotListener = listsDoc.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let items = data["items"] as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                self.items = items
            }
        }
    }

    private func saveToFirestore(_ items: [[String: Any]]) {
        try? listsDoc.setData(["items": items, "updatedAt": FieldValue.serverTimestamp()])
    }

    private func addItem(_ dict: [String: Any]) {
        items.append(dict)
        saveToFirestore(items)
        showAddSheet = false
    }

    private func updateItem(at index: Int, with dict: [String: Any]) {
        guard index < items.count else { return }
        items[index] = dict
        saveToFirestore(items)
        editingIndex = nil
        showEditSheet = false
    }

    private func toggleItem(at index: Int) {
        guard index < items.count else { return }
        var item = items[index]
        let wasDone = (item["done"] as? Bool) ?? false
        item["done"] = !wasDone
        items[index] = item
        saveToFirestore(items)
    }

    private func deleteItem(at index: Int) {
        items.remove(at: index)
        saveToFirestore(items)
    }
}

// MARK: - Add / Edit Form

private struct WishlistFormView: View {
    let existing: [String: Any]?
    let onSave: ([String: Any]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var selectedCategory: String = "other"
    @State private var proposedBy: String = "both"

    private let categories: [String: String] = [
        "adventure": "Aventura 🧗",
        "food": "Cena/Comida 🍕",
        "movie": "Cine/Serie 🎬",
        "trip": "Viajar ✈️",
        "home": "En Casa 🏠",
        "other": "Otro 🌟",
    ]

    init(existing: [String: Any]? = nil, onSave: @escaping ([String: Any]) -> Void) {
        self.existing = existing
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("¿Qué quieren hacer?") {
                    TextField("Título", text: $title)
                }
                Section("Detalles / Notas (opcional)") {
                    TextField("Descripción", text: $desc)
                }
                Section("Categoría") {
                    Picker("Categoría", selection: $selectedCategory) {
                        ForEach(Array(categories.keys.sorted()), id: \.self) { key in
                            Text(categories[key] ?? key).tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Propuesto por") {
                    Picker("Propuesto por", selection: $proposedBy) {
                        Text("Ambos 💑").tag("both")
                        Text("Yo 🙋").tag("me")
                        Text("Pareja 👩‍❤️‍👨").tag("partner")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(existing != nil ? "Editar Deseo" : "Nuevo Deseo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing != nil ? "Guardar" : "Agregar") {
                        let now = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "d/M/yyyy"
                        let dict: [String: Any] = [
                            "id": existing?["id"] ?? "\(Int(now.timeIntervalSince1970 * 1000))",
                            "title": title.trimmingCharacters(in: .whitespaces),
                            "desc": desc.trimmingCharacters(in: .whitespaces),
                            "done": existing?["done"] ?? false,
                            "category": selectedCategory,
                            "proposedBy": proposedBy,
                            "date": existing?["date"] ?? dateFormatter.string(from: now),
                        ]
                        onSave(dict)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = existing {
                    title = e["title"] as? String ?? ""
                    desc = e["desc"] as? String ?? ""
                    selectedCategory = e["category"] as? String ?? "other"
                    proposedBy = e["proposedBy"] as? String ?? "both"
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
