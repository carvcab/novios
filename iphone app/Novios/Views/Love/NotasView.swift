import SwiftUI
import FirebaseFirestore

public struct NotasView: View {
    @State private var notes: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var showAddSheet = false
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private let noteColors: [UInt] = [0xFFFFEA7F, 0xFFFF8F7F, 0xFF7C83FF, 0xFF81C784, 0xFFFFB74D, 0xFFE1BEE7]

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var notesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("notes")
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if notes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(Array(notes.enumerated()), id: \.offset) { i, note in
                                noteCard(note, index: i)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Muro de Notas 📌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primaryPink)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addNoteSheet
            }
            .onAppear { startListening() }
            .onDisappear { snapshotListener?.remove() }
        }
    }

    private func startListening() {
        snapshotListener?.remove()
        snapshotListener = notesRef.addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self, let docs = snapshot?.documents else { return }
            let list = docs.map { $0.data() }.sorted { a, b in
                let idA = a["id"] as? String ?? ""
                let idB = b["id"] as? String ?? ""
                return idA > idB
            }
            notes = list
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(theme.textSecondary.opacity(0.24))
            Text("Tablero Vacío")
                .appFont(size: 18, weight: .bold)
                .foregroundColor(theme.textSecondary)
            Text("Deja un post-it virtual para tu pareja 💖")
                .appFont(size: 13)
                .foregroundColor(theme.textSecondary.opacity(0.6))
        }
    }

    private func noteCard(_ note: [String: Any], index: Int) -> some View {
        let noteId = note["id"] as? String ?? "\(index)"
        let colorHex = note["color"] as? String ?? "FFFFEA7F"
        let cardColor = parseColor(colorHex)
        let angle = getRotationAngle(noteId)

        return SwipeToDelete(
            noteId: noteId,
            onDelete: { notesRef.document(noteId).delete() }
        ) {
            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(note["title"] as? String ?? "")
                            .appFont(size: 16, weight: .bold)
                            .foregroundColor(.black.opacity(0.87))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(note["from"] as? String ?? "")
                            .appFont(size: 8, weight: .bold)
                            .foregroundColor(.black.opacity(0.54))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.08))
                            .cornerRadius(4)
                    }

                    Divider().background(Color.black.opacity(0.12))

                    Text(note["content"] as? String ?? "")
                        .appFont(size: 14)
                        .foregroundColor(.black.opacity(0.87))
                        .lineLimit(5)

                    Spacer()

                    HStack {
                        Spacer()
                        Text(note["date"] as? String ?? "")
                            .appFont(size: 8)
                            .foregroundColor(.black.opacity(0.38))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 10)

                VStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.red, Color.red.opacity(0.5)], center: .center, startRadius: 0, endRadius: 10))
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.45), radius: 4, x: 1, y: 3)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(cardColor)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.35), radius: 8, x: 2, y: 5)
            .rotationEffect(.degrees(angle))
        }
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean = String(clean.dropFirst()) }
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return Color(red: 1, green: 0.92, blue: 0.5) }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255,
            opacity: Double((val >> 24) & 0xFF) / 255
        )
    }

    private func getRotationAngle(_ id: String) -> Double {
        let digits = id.filter { $0.isNumber }
        let num = Int(digits) ?? 0
        return Double((num % 8) - 4)
    }

    private var addNoteSheet: some View {
        AddNoteView(
            colors: noteColors,
            onSave: { title, content, colorIdx in
                let now = Date()
                let df = DateFormatter()
                df.dateFormat = "d/M/yyyy"
                let dateStr = df.string(from: now)
                let noteId = "\(Int(now.timeIntervalSince1970 * 1000))"
                let hexStr = String(noteColors[colorIdx], radix: 16).uppercased()
                notesRef.document(noteId).setData([
                    "id": noteId,
                    "title": title,
                    "content": content,
                    "color": hexStr,
                    "date": dateStr,
                    "from": CoupleService.shared.currentName
                ])
                showAddSheet = false
            },
            onCancel: { showAddSheet = false }
        )
    }
}

private struct SwipeToDelete<Content: View>: View {
    let noteId: String
    let onDelete: () -> Void
    let content: Content
    @State private var offset: CGFloat = 0

    init(noteId: String, onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.noteId = noteId
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                Image(systemName: "trash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
            }
            .padding(.trailing, 16)
            .background(Color.red.opacity(0.25))
            .cornerRadius(4)

            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -120)
                            }
                        }
                        .onEnded { value in
                            if offset < -60 {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    offset = -500
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    onDelete()
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
        }
        .clipped()
    }
}

private struct AddNoteView: View {
    let colors: [UInt]
    let onSave: (String, String, Int) -> Void
    let onCancel: () -> Void
    @State private var title = ""
    @State private var content = ""
    @State private var selectedColorIdx = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Título") {
                    TextField("Título de la nota", text: $title)
                }
                Section("Mensaje") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                Section("Color de la nota") {
                    HStack(spacing: 10) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { i, c in
                            let color = parseColor(String(c, radix: 16).uppercased())
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColorIdx == i ? Color.white : Color.white.opacity(0.1), lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.26), radius: 4, x: 0, y: 2)
                                .onTapGesture { selectedColorIdx = i }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nueva Nota 📝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Colgar Nota") {
                        onSave(title.trimmingCharacters(in: .whitespaces), content.trimmingCharacters(in: .whitespaces), selectedColorIdx)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean = String(clean.dropFirst()) }
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return Color(red: 1, green: 0.92, blue: 0.5) }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255,
            opacity: Double((val >> 24) & 0xFF) / 255
        )
    }
}
