import SwiftUI
import FirebaseFirestore

public struct LettersView: View {
    @State private var letters: [LetterItem] = []
    @State private var showNew = false
    @State private var readLetter: LetterItem?
    @State private var snapshotListener: ListenerRegistration?
    @State private var editLetter: LetterItem?

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared

    private let letterColors: [Color] = [
        Color(red: 1, green: 0.5, blue: 0.5), Color(red: 0.6, green: 0.8, blue: 1),
        Color(red: 1, green: 0.85, blue: 0.6), Color(red: 0.7, green: 0.9, blue: 0.7),
    ]
    private let letterStickers = ["💌", "❤️", "🌸", "🧸", "🍫", "💍", "🌟", "🧁", "🍷"]
    private let letterFonts: [(String, String)] = [("Sans", "Normal"), ("Serif", "Elegante"), ("Cursive", "Manuscrita")]

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var lettersDocRef: DocumentReference {
        db.collection("couples").document(coupleId).collection("lists").document("letters")
    }

    private var myId: String { AuthService.shared.currentUser?.id ?? "" }
    private var partnerId: String { myId == CoupleService.diegoUid ? CoupleService.yosmariUid : CoupleService.diegoUid }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if letters.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(letters.enumerated()), id: \.offset) { i, letter in
                            letterRow(letter, index: i)
                                .contextMenu {
                                    Button { startEdit(letter) } label: { Label("Editar", systemImage: "pencil") }
                                    Button(role: .destructive) { deleteLetter(letter) } label: { Label("Eliminar", systemImage: "trash") }
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Cartas de Amor 💌")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNew = true } label: {
                    Image(systemName: "square.and.pencil").foregroundColor(theme.primaryPink)
                }
            }
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
        .sheet(isPresented: $showNew) { letterForm(nil) }
        .sheet(item: $editLetter) { letter in letterForm(letter) }
        .sheet(item: $readLetter) { letter in readerView(letter) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open.fill").font(.system(size: 48)).foregroundColor(theme.primaryPink.opacity(0.6))
            Text("No hay cartas aún").appFont(size: 18, weight: .semibold)
            Text("Escríbele una hermosa carta a tu pareja 💖").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private func letterRow(_ letter: LetterItem, index: Int) -> some View {
        let isMine = letter.authorId == myId
        let color = colorFromHex(letter.color) ?? letterColors[0]
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 44, height: 44)
                Text(letter.sticker).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(letter.title).appFont(size: 15, weight: .semibold).foregroundColor(.primary)
                HStack(spacing: 6) {
                    Text(isMine ? "Para mi pareja" : "De mi pareja").appFont(size: 11).foregroundColor(.secondary)
                    if !letter.opened && !isMine {
                        Circle().fill(theme.primary).frame(width: 6, height: 6)
                        Text("Sin leer").appFont(size: 10).foregroundColor(theme.primary)
                    } else if isMine {
                        Text(letter.opened ? "Leída" : "Sin leer").appFont(size: 10).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Text(letter.date).appFont(size: 11).foregroundColor(.secondary)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .onTapGesture {
            markAsRead(letter)
            readLetter = letter
        }
    }

    private func readerView(_ letter: LetterItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(letter.sticker).font(.system(size: 48))
                    Text(letter.title).appFont(size: 24, weight: .bold).multilineTextAlignment(.center)
                    Text(letter.date).appFont(size: 13).foregroundColor(.secondary)
                    Divider()
                    Text(letter.message).appFont(size: 16).lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 16).fill(colorFromHex(letter.color) ?? .white).opacity(0.3))
            }
            .background(LiquidBackgroundView())
            .navigationTitle("💌 Carta de Amor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { readLetter = nil } } }
        }
    }

    private func letterForm(_ existing: LetterItem?) -> some View {
        LetterFormView(
            existing: existing,
            myId: myId,
            partnerId: partnerId,
            colors: letterColors,
            stickers: letterStickers,
            fonts: letterFonts,
            onSave: { item in
                if existing != nil {
                    updateLetter(item)
                } else {
                    addLetter(item)
                }
            },
            onCancel: {
                if existing != nil { editLetter = nil } else { showNew = false }
            }
        )
    }

    private func startEdit(_ letter: LetterItem) { editLetter = letter }
}

// MARK: - Letter Form

private struct LetterFormView: View {
    let existing: LetterItem?
    let myId: String
    let partnerId: String
    let colors: [Color]
    let stickers: [String]
    let fonts: [(String, String)]
    let onSave: (LetterItem) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var message = ""
    @State private var selectedColor = Color(red: 1, green: 0.5, blue: 0.5)
    @State private var selectedSticker = "💌"
    @State private var selectedFont = "Sans"

    var body: some View {
        NavigationStack {
            Form {
                Section("Título") { TextField("Escribe un título...", text: $title) }
                Section("Mensaje") { TextEditor(text: $message).frame(minHeight: 150) }
                Section("Color de la carta") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(colors.enumerated()), id: \.offset) { _, c in
                                Circle().fill(c).frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(hexFromColor(selectedColor) == hexFromColor(c) ? Color.primary : Color.gray.opacity(0.3), lineWidth: 2))
                                    .onTapGesture { selectedColor = c }
                            }
                        }
                    }
                }
                Section("Sticker") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(stickers, id: \.self) { s in
                                Text(s).font(.system(size: 28))
                                    .padding(6)
                                    .background(selectedSticker == s ? Color.primary.opacity(0.15) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { selectedSticker = s }
                            }
                        }
                    }
                }
                Section("Estilo de letra") {
                    Picker("Fuente", selection: $selectedFont) {
                        ForEach(fonts, id: \.0) { f in
                            Text(f.1).tag(f.0)
                        }
                    }
                }
            }
            .navigationTitle(existing != nil ? "Editar Carta" : "Nueva Carta 💌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing != nil ? "Guardar" : "Enviar") {
                        let item = LetterItem(
                            id: existing?.id ?? "\(Date().timeIntervalSince1970 * 1000)",
                            title: title.trimmingCharacters(in: .whitespaces),
                            date: existing?.date ?? Self.todayFormatted(),
                            opened: existing?.opened ?? false,
                            color: hexFromColor(selectedColor),
                            message: message.trimmingCharacters(in: .whitespaces),
                            font: selectedFont,
                            sticker: selectedSticker,
                            authorId: existing?.authorId ?? myId
                        )
                        onSave(item)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || message.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            if let e = existing {
                title = e.title; message = e.message; selectedFont = e.font; selectedSticker = e.sticker
                if let c = colorFromHex(e.color) { selectedColor = c }
            }
        }
    }

    static func todayFormatted() -> String {
        let f = DateFormatter(); f.dateFormat = "d MMM yyyy"; f.locale = Locale(identifier: "es")
        return f.string(from: Date())
    }
}

// MARK: - Firestore Operations

extension LettersView {
    private func startListening() {
        snapshotListener = lettersDocRef.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let items = data["items"] as? [[String: Any]] else { return }
            let parsed = items.compactMap { dict -> LetterItem? in
                guard let id = dict["id"] as? String, let title = dict["title"] as? String else { return nil }
                return LetterItem(
                    id: id, title: title, date: dict["date"] as? String ?? "",
                    opened: dict["opened"] as? Bool ?? false,
                    color: dict["color"] as? String ?? "#FF7F7F",
                    message: dict["message"] as? String ?? "",
                    font: dict["font"] as? String ?? "Sans",
                    sticker: dict["sticker"] as? String ?? "💌",
                    authorId: dict["authorId"] as? String ?? ""
                )
            }
            DispatchQueue.main.async { self.letters = parsed }
        }
    }

    private func stopListening() { snapshotListener?.remove(); snapshotListener = nil }

    private func saveToFirestore(_ items: [[String: Any]]) {
        try? lettersDocRef.setData(["items": items, "updatedAt": FieldValue.serverTimestamp()])
    }

    private func allItems() -> [[String: Any]] {
        letters.map { $0.toDict() }
    }

    private func addLetter(_ letter: LetterItem) {
        var updated = [letter.toDict()] + letters.map { $0.toDict() }
        saveToFirestore(updated)
        showNew = false
    }

    private func updateLetter(_ letter: LetterItem) {
        if let idx = letters.firstIndex(where: { $0.id == letter.id }) {
            var updated = letters
            updated[idx] = letter
            saveToFirestore(updated.map { $0.toDict() })
            editLetter = nil
        }
    }

    private func deleteLetter(_ letter: LetterItem) {
        let updated = letters.filter { $0.id != letter.id }
        saveToFirestore(updated.map { $0.toDict() })
    }

    private func markAsRead(_ letter: LetterItem) {
        guard !letter.opened && letter.authorId != myId else { return }
        if let idx = letters.firstIndex(where: { $0.id == letter.id }) {
            var updated = letters
            updated[idx].opened = true
            saveToFirestore(updated.map { $0.toDict() })
        }
    }
}

// MARK: - Data Types

private struct LetterItem: Identifiable {
    let id: String
    var title: String
    var date: String
    var opened: Bool
    var color: String
    var message: String
    var font: String
    var sticker: String
    var authorId: String

    func toDict() -> [String: Any] {
        ["id": id, "title": title, "date": date, "opened": opened,
         "color": color, "message": message, "font": font,
         "sticker": sticker, "authorId": authorId]
    }
}

// MARK: - Color Helpers

private func colorFromHex(_ hex: String) -> Color? {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    guard let v = UInt64(h, radix: 16) else { return nil }
    let r = Double((v >> 16) & 0xFF) / 255
    let g = Double((v >> 8) & 0xFF) / 255
    let b = Double(v & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}

private func hexFromColor(_ color: Color) -> String {
    let ui = UIColor(color)
    var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
    ui.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
}
