import SwiftUI

public struct CapsulesView: View {
    @StateObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var titleInput = ""
    @State private var messageInput = ""
    @State private var openDate = Date().addingTimeInterval(86400 * 30)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if couple.capsulas.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.capsulas) { cap in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: cap.revelada ? "envelope.open.fill" : "lock.shield.fill")
                                            .foregroundColor(cap.revelada ? .green : ThemeManager.shared.primary)
                                        Text(cap.titulo).appFont(size: 16, weight: .bold)
                                        Spacer()
                                        Image(systemName: cap.revelada ? "checkmark.seal.fill" : "clock.fill")
                                            .foregroundColor(cap.revelada ? .green : .orange).appFont(size: 14)
                                    }
                                    Text(cap.mensaje).appFont(size: 13).foregroundColor(.secondary).lineLimit(3)
                                    Text("📅 \(cap.fechaApertura.formatted(date: .long, time: .omitted))")
                                        .appFont(size: 11).foregroundColor(ThemeManager.shared.textSecondary)
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15)))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Cápsula del Tiempo ⏳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newCapsuleSheet }
            .task { await couple.fetchCapsulas() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Sin cápsulas").appFont(size: 18, weight: .semibold)
            Text("Guarden mensajes para el futuro 📦").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newCapsuleSheet: some View {
        NavigationStack {
            Form {
                Section("Cápsula del Tiempo") {
                    TextField("Título", text: $titleInput)
                    TextField("Mensaje", text: $messageInput)
                    DatePicker("Fecha de apertura", selection: $openDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Nueva Cápsula 🎁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addCapsula(titulo: titleInput, mensaje: messageInput, fechaApertura: openDate)
                            titleInput = ""; messageInput = ""; showNew = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
