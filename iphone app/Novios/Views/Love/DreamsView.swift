import SwiftUI
import FirebaseFirestore

public struct DreamsView: View {
    @State private var dreams: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var editingIndex: Int?
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private let dreamIcons: [String: String] = [
        "home": "house.fill", "flight": "airplane", "pets": "pawprint.fill",
        "school": "book.fill", "work": "briefcase.fill", "child": "figure.2.and.child.holdinghands",
        "car": "car.fill", "ring": "diamond.fill", "star": "star.fill", "heart": "heart.fill"
    ]

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var listsDoc: DocumentReference {
        db.collection("couples").document(coupleId).collection("lists").document("dreams_list")
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                VStack(spacing: 0) {
                    if !dreams.isEmpty {
                        progressHeader
                    }

                    if dreams.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(Array(dreams.enumerated()), id: \.offset) { index, dream in
                                    dreamCard(index: index, dream: dream)
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationTitle("Nuestros Sueños")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primary)
                            .appFont(size: 22)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .appFont(size: 20, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(theme.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(20)
            }
            .onAppear { startListening() }
            .onDisappear { stopListening() }
            .sheet(isPresented: $showAddSheet) {
                addDreamSheet(mode: .add, dream: nil)
            }
            .sheet(isPresented: $showEditSheet) {
                if let idx = editingIndex, idx < dreams.count {
                    addDreamSheet(mode: .edit, dream: dreams[idx])
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        let completed = dreams.filter { ($0["done"] as? Bool) == true }.count
        let total = dreams.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0.0

        return GlassCard(cornerRadius: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(theme.primary.opacity(0.15), lineWidth: 5)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "sparkles")
                        .appFont(size: 22)
                        .foregroundColor(theme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sueños en Común")
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(theme.textPrimary)
                    Text("¡Llevan \(completed) de \(total) metas soñadas cumplidas! 🌌")
                        .appFont(size: 12)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.primary.opacity(0.25))
            Text("Muro de Sueños Vacío")
                .appFont(size: 18, weight: .bold)
                .foregroundColor(theme.textPrimary.opacity(0.7))
            Text("¿Cuáles son sus metas en común?")
                .appFont(size: 13)
                .foregroundColor(theme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Dream Card

    private func dreamCard(index: Int, dream: [String: Any]) -> some View {
        let done = (dream["done"] as? Bool) == true
        let iconKey = dream["icon"] as? String ?? "star"
        let iconName = dreamIcons[iconKey] ?? "star.fill"
        let title = dream["title"] as? String ?? ""
        let desc = dream["desc"] as? String ?? ""
        let proposedBy = dream["proposedBy"] as? String ?? "both"

        let proposerText: String
        switch proposedBy {
        case "me": proposerText = "Yo"
        case "partner": proposerText = "Pareja"
        default: proposerText = "Ambos"
        }

        return Button {
            toggleDream(at: index)
        } label: {
            GlassCard(cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(done ? Color.green.opacity(0.15) : theme.primary.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: iconName)
                                .appFont(size: 16)
                                .foregroundColor(done ? .green : theme.primary)
                        }

                        Spacer()

                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .appFont(size: 18)
                            .foregroundColor(done ? .green : theme.textSecondary.opacity(0.25))
                    }

                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(done ? theme.textPrimary.opacity(0.38) : theme.textPrimary)
                            .strikethrough(done)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if !desc.isEmpty {
                            Text(desc)
                                .appFont(size: 11)
                                .foregroundColor(done ? theme.textPrimary.opacity(0.3) : theme.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Text("Por: \(proposerText)")
                            .appFont(size: 8)
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.textSecondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Spacer()

                        if done {
                            Text("¡Cumplido! 🎉")
                                .appFont(size: 8, weight: .bold)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(done ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: done ? Color.green.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    editingIndex = index
                    showEditSheet = true
                }
        )
    }

    // MARK: - Firestore

    private func startListening() {
        snapshotListener?.remove()
        snapshotListener = listsDoc.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let items = data["items"] as? [[String: Any]] ?? []
            DispatchQueue.main.async {
                self.dreams = items
            }
        }
    }

    private func stopListening() {
        snapshotListener?.remove()
        snapshotListener = nil
    }

    private func saveDreams() {
        Task {
            try? await listsDoc.setData(["items": dreams, "updatedAt": FieldValue.serverTimestamp()])
        }
    }

    private func toggleDream(at index: Int) {
        guard index < dreams.count else { return }
        let current = (dreams[index]["done"] as? Bool) ?? false
        dreams[index]["done"] = !current
        saveDreams()
    }

    private func deleteDream(at index: Int) {
        guard index < dreams.count else { return }
        dreams.remove(at: index)
        saveDreams()
    }

    // MARK: - Add/Edit Sheet

    @ViewBuilder
    private func addDreamSheet(mode: DreamFormMode, dream: [String: Any]?) -> some View {
        let titleInit = dream?["title"] as? String ?? ""
        let descInit = dream?["desc"] as? String ?? ""
        let iconInit = dream?["icon"] as? String ?? "star"
        let proposedInit = dream?["proposedBy"] as? String ?? "both"

        DreamFormView(
            mode: mode,
            titleInput: titleInit,
            descInput: descInit,
            selectedIcon: iconInit,
            proposedBy: proposedInit,
            dreamIcons: dreamIcons,
            onSave: { title, desc, icon, proposer in
                if mode == .add {
                    self.dreams.insert([
                        "id": "\(Date().timeIntervalSince1970 * 1000)",
                        "title": title,
                        "desc": desc,
                        "icon": icon,
                        "proposedBy": proposer,
                        "done": false
                    ], at: 0)
                } else if let idx = editingIndex, idx < self.dreams.count {
                    var updated = self.dreams[idx]
                    updated["title"] = title
                    updated["desc"] = desc
                    updated["icon"] = icon
                    updated["proposedBy"] = proposer
                    self.dreams[idx] = updated
                }
                self.saveDreams()
                self.showAddSheet = false
                self.showEditSheet = false
            },
            onDelete: mode == .edit ? {
                if let idx = editingIndex {
                    self.deleteDream(at: idx)
                }
                self.showEditSheet = false
            } : nil
        )
    }
}

// MARK: - Dream Form Mode

private enum DreamFormMode {
    case add
    case edit
}

// MARK: - Dream Form View

private struct DreamFormView: View {
    let mode: DreamFormMode
    @State var titleInput: String
    @State var descInput: String
    @State var selectedIcon: String
    @State var proposedBy: String
    let dreamIcons: [String: String]
    let onSave: (String, String, String, String) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared

    private let iconKeys: [String] = ["home", "flight", "pets", "school", "work", "child", "car", "ring", "star", "heart"]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Título")
                                .appFont(size: 13, weight: .semibold)
                                .foregroundColor(theme.textSecondary)
                            TextField("¿Cuál es el sueño?", text: $titleInput)
                                .appFont(size: 15)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(theme.cardBackground.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Descripción")
                                .appFont(size: 13, weight: .semibold)
                                .foregroundColor(theme.textSecondary)
                            TextField("Detalles / Notas (opcional)", text: $descInput)
                                .appFont(size: 15)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(theme.cardBackground.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icono representativo:")
                                .appFont(size: 12, weight: .bold)
                                .foregroundColor(theme.textSecondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                                ForEach(iconKeys, id: \.self) { key in
                                    let isSel = selectedIcon == key
                                    let icon = dreamIcons[key] ?? "star.fill"
                                    Button {
                                        selectedIcon = key
                                    } label: {
                                        Image(systemName: icon)
                                            .appFont(size: 18)
                                            .foregroundColor(isSel ? theme.primary : theme.textSecondary.opacity(0.5))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSel ? theme.primary.opacity(0.15) : theme.cardBackground.opacity(0.4))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(isSel ? theme.primary : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Propuesto por:")
                                .appFont(size: 12, weight: .bold)
                                .foregroundColor(theme.textSecondary)

                            Picker("Propuesto por", selection: $proposedBy) {
                                Text("Ambos").tag("both")
                                Text("Yo").tag("me")
                                Text("Pareja").tag("partner")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(mode == .add ? "Nuevo Sueño" : "Editar Sueño")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                if mode == .edit, let onDelete = onDelete {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Text("Eliminar")
                                .foregroundColor(.red)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .add ? "Agregar" : "Guardar") {
                        let trimmedTitle = titleInput.trimmingCharacters(in: .whitespaces)
                        guard !trimmedTitle.isEmpty else { return }
                        onSave(trimmedTitle, descInput.trimmingCharacters(in: .whitespaces), selectedIcon, proposedBy)
                        dismiss()
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
