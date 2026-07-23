import SwiftUI
import FirebaseFirestore

public struct VoiceMailboxScreen: View {
    @State private var messages: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var showAdd = false
    @State private var newNote = ""
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var listsDoc: DocumentReference { db.collection("couples").document(coupleId).collection("lists").document("voice_mailbox") }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mic.fill").font(.system(size: 48)).foregroundColor(theme.primary.opacity(0.5))
                    Text("Buzón vacío").appFont(size: 18, weight: .semibold)
                    Text("Deja mensajes de voz o notas para tu pareja 💕").appFont(size: 13).foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { i, msg in
                            GlassCard(cornerRadius: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: msg["type"] as? String == "audio" ? "mic.circle.fill" : "note.text")
                                        .font(.system(size: 28)).foregroundColor(theme.primary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(msg["title"] as? String ?? "").appFont(size: 14, weight: .semibold).foregroundColor(theme.textPrimary)
                                        Text(msg["date"] as? String ?? "").appFont(size: 10).foregroundColor(theme.textSecondary)
                                        if let note = msg["note"] as? String, !note.isEmpty {
                                            Text(note).appFont(size: 11).foregroundColor(theme.textSecondary).lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Button { deleteMessage(i) } label: {
                                        Image(systemName: "trash").foregroundColor(.red.opacity(0.6))
                                    }
                                }.padding(12)
                            }
                        }
                    }.padding(16)
                }
            }
        }
        .navigationTitle("Buzón de Voz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").foregroundColor(theme.primary) }
            }
        }
        .onAppear { startListening() }
        .onDisappear { snapshotListener?.remove() }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    Section("Mensaje de texto") {
                        TextField("Escribe un mensaje...", text: $newNote)
                    }
                }
                .navigationTitle("Nuevo Mensaje")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showAdd = false; newNote = "" } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Enviar") {
                            let df = DateFormatter(); df.dateFormat = "d/M/yyyy"
                            messages.insert([
                                "title": "Mensaje de \(CoupleService.shared.currentName)",
                                "date": df.string(from: Date()),
                                "note": newNote.trimmingCharacters(in: .whitespaces),
                                "type": "text",
                                "addedBy": CoupleService.shared.currentName,
                            ], at: 0)
                            save()
                            showAdd = false; newNote = ""
                        }.disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }.presentationDetents([.medium])
        }
    }

    private func startListening() {
        snapshotListener = listsDoc.addSnapshotListener { snap, _ in
            guard let data = snap?.data(), let items = data["items"] as? [[String: Any]] else { return }
            messages = items
        }
    }

    private func save() { try? listsDoc.setData(["items": messages, "updatedAt": FieldValue.serverTimestamp()]) }
    private func deleteMessage(_ i: Int) { messages.remove(at: i); save() }
}
