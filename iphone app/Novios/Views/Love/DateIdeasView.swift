import SwiftUI

public struct DateIdeasView: View {
    @StateObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var titleInput = ""
    @State private var descInput = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if couple.citas.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.citas) { cita in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(ThemeManager.shared.primary.opacity(0.12)).frame(width: 44, height: 44)
                                        Image(systemName: cita.realizada ? "checkmark" : "heart.text.square.fill")
                                            .foregroundColor(cita.realizada ? .green : ThemeManager.shared.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cita.titulo).appFont(size: 15, weight: .semibold)
                                        if !cita.descripcion.isEmpty {
                                            Text(cita.descripcion).appFont(size: 12).foregroundColor(.secondary).lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    if cita.realizada {
                                        Image(systemName: "checkmark.seal.fill").foregroundColor(.green).appFont(size: 16)
                                    }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(cita.realizada ? Color.green.opacity(0.3) : Color.white.opacity(0.15)))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Ideas de Citas 🌹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newDateSheet }
            .task { await couple.fetchCitas() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Sin ideas aún").appFont(size: 18, weight: .semibold)
            Text("Agreguen planes para su próxima cita 💑").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newDateSheet: some View {
        NavigationStack {
            Form {
                Section("Nueva Idea de Cita") {
                    TextField("Título del plan", text: $titleInput)
                    TextField("Descripción", text: $descInput)
                }
            }
            .navigationTitle("Agregar Plan 🌟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addCita(titulo: titleInput, descripcion: descInput)
                            titleInput = ""; descInput = ""; showNew = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
