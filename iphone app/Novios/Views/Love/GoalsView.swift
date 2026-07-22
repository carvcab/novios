import SwiftUI

public struct GoalsView: View {
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
                if couple.logros.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.logros) { goal in
                                HStack(spacing: 14) {
                                    Button {
                                        Task { await couple.toggleLogro(id: goal.id, completado: goal.completado) }
                                    } label: {
                                        Image(systemName: goal.completado ? "checkmark.circle.fill" : "circle")
                                            .appFont(size: 24).foregroundColor(goal.completado ? .green : ThemeManager.shared.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(goal.titulo).appFont(size: 15, weight: .semibold).strikethrough(goal.completado)
                                        if !goal.descripcion.isEmpty {
                                            Text(goal.descripcion).appFont(size: 12).foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if goal.completado {
                                        Image(systemName: "star.fill").foregroundColor(.yellow).appFont(size: 14)
                                    }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(goal.completado ? Color.green.opacity(0.3) : Color.white.opacity(0.15)))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Metas y Logros 🎯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newGoalSheet }
            .task { await couple.fetchLogros() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Sin metas aún").appFont(size: 18, weight: .semibold)
            Text("Agreguen sueños por cumplir juntos ✨").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newGoalSheet: some View {
        NavigationStack {
            Form {
                Section("Nueva Meta") {
                    TextField("Título de la meta", text: $titleInput)
                    TextField("Descripción", text: $descInput)
                }
            }
            .navigationTitle("Agregar Meta 🌟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addLogro(titulo: titleInput, descripcion: descInput)
                            titleInput = ""; descInput = ""; showNew = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
