import SwiftUI

public struct TodoView: View {
    @StateObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var taskInput = ""
    @State private var assigneeInput = "Ambos"

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if couple.todoItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.todoItems) { item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.completada ? "checkmark.circle.fill" : "circle")
                                        .appFont(size: 22).foregroundColor(item.completada ? .green : ThemeManager.shared.primary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.tarea).appFont(size: 15, weight: .semibold).strikethrough(item.completada)
                                        Text("Asignado a: \(item.asignadoA)").appFont(size: 11).foregroundColor(.secondary)
                                    }
                                    Spacer()
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
            .navigationTitle("Lista de Pendientes ✅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newTodoSheet }
            .task { await couple.fetchTodo() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Sin pendientes").appFont(size: 18, weight: .semibold)
            Text("Agreguen tareas compartidas 📋").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newTodoSheet: some View {
        NavigationStack {
            Form {
                Section("Nueva Tarea") {
                    TextField("Descripción de la tarea", text: $taskInput)
                    Picker("Asignado a", selection: $assigneeInput) {
                        Text("Ambos").tag("Ambos")
                        Text("Diego").tag(CoupleService.diegoUid)
                        Text("Yosmari").tag(CoupleService.yosmariUid)
                    }
                }
            }
            .navigationTitle("Agregar Tarea 📝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addTodoItem(tarea: taskInput, asignadoA: assigneeInput)
                            taskInput = ""; showNew = false
                        }
                    }
                    .disabled(taskInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
