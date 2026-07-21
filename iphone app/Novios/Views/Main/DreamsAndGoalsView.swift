import SwiftUI

public struct DreamsAndGoalsView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedTab = 0 // 0: Metas, 1: Eventos, 2: Citas, 3: Tareas, 4: Cápsula
    @State private var showAddModal = false

    @State private var itemTitle = ""
    @State private var itemDesc = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chipButton(title: "Metas", tag: 0)
                        chipButton(title: "Eventos", tag: 1)
                        chipButton(title: "Citas", tag: 2)
                        chipButton(title: "Tareas", tag: 3)
                        chipButton(title: "Cápsula", tag: 4)
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            metasContent
                        } else if selectedTab == 1 {
                            eventosContent
                        } else if selectedTab == 2 {
                            citasContent
                        } else if selectedTab == 3 {
                            todoContent
                        } else {
                            capsulaContent
                        }
                    }
                    .padding()
                }
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Nuestros Sueños")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddModal = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .appFont(size: 20)
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddModal) { addModalSheet }
        }
    }

    private func chipButton(title: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            Text(title)
                .appFont(size: 13, weight: selectedTab == tag ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == tag ? theme.primary : Color.gray.opacity(0.15))
                .foregroundColor(selectedTab == tag ? .white : .primary)
                .cornerRadius(20)
        }
    }

    // MARK: - Sections

    private var metasContent: some View {
        VStack(spacing: 12) {
            if couple.logros.isEmpty {
                emptyView(icon: "star.fill", text: "No hay metas registradas aún.\nAgrega un sueño que quieran cumplir juntos.")
            } else {
                ForEach(couple.logros) { logro in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(logro.titulo)
                                .appFont(size: 15, weight: .bold)
                                .strikethrough(logro.completado)
                            if !logro.descripcion.isEmpty {
                                Text(logro.descripcion)
                                    .appFont(size: 13)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        Spacer()
                        Button {
                            Task { await couple.toggleLogro(id: logro.id, completado: logro.completado) }
                        } label: {
                            Image(systemName: logro.completado ? "checkmark.circle.fill" : "circle")
                                .appFont(size: 24)
                                .foregroundColor(logro.completado ? .green : theme.primary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var eventosContent: some View {
        VStack(spacing: 12) {
            if couple.eventos.isEmpty {
                emptyView(icon: "calendar", text: "No hay eventos próximos.\nPlaneen su siguiente fecha especial.")
            } else {
                ForEach(couple.eventos) { ev in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ev.titulo)
                                .appFont(size: 15, weight: .bold)
                            Text(ev.categoria)
                                .appFont(size: 12)
                                .foregroundColor(theme.primary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var citasContent: some View {
        VStack(spacing: 12) {
            if couple.citas.isEmpty {
                emptyView(icon: "heart.square.fill", text: "Agreguen ideas para su próxima cita romántica.")
            } else {
                ForEach(couple.citas) { cita in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cita.titulo)
                            .appFont(size: 15, weight: .bold)
                        if !cita.descripcion.isEmpty {
                            Text(cita.descripcion)
                                .appFont(size: 13)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var todoContent: some View {
        VStack(spacing: 12) {
            if couple.todoItems.isEmpty {
                emptyView(icon: "checklist", text: "Lista de pendientes vacía.")
            } else {
                ForEach(couple.todoItems) { item in
                    HStack {
                        Text(item.tarea)
                            .appFont(size: 14)
                        Spacer()
                        Text(item.asignadoA)
                            .appFont(size: 11)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var capsulaContent: some View {
        VStack(spacing: 12) {
            if couple.capsulas.isEmpty {
                emptyView(icon: "lock.shield.fill", text: "Crea una cápsula del tiempo para abrir en el futuro.")
            } else {
                ForEach(couple.capsulas) { cap in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(cap.titulo)
                            .appFont(size: 15, weight: .bold)
                        Text(cap.mensaje)
                            .appFont(size: 13)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
            }
        }
    }

    private func emptyView(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 30)
            Image(systemName: icon)
                .appFont(size: 40)
                .foregroundColor(theme.primary.opacity(0.5))
            Text(text)
                .appFont(size: 14)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    private var addModalSheet: some View {
        NavigationStack {
            Form {
                Section("Agregar nuevo elemento") {
                    TextField("Título", text: $itemTitle)
                    TextField("Descripción / Detalle", text: $itemDesc)
                }
            }
            .navigationTitle("Agregar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !itemTitle.isEmpty else { return }
                        Task {
                            if selectedTab == 0 {
                                await couple.addLogro(titulo: itemTitle, descripcion: itemDesc)
                            } else if selectedTab == 1 {
                                await couple.addEvento(titulo: itemTitle, categoria: "Especial", descripcion: itemDesc)
                            } else if selectedTab == 2 {
                                await couple.addCita(titulo: itemTitle, descripcion: itemDesc)
                            } else if selectedTab == 3 {
                                await couple.addTodoItem(tarea: itemTitle, asignadoA: "Ambos")
                            } else {
                                await couple.addCapsula(titulo: itemTitle, mensaje: itemDesc, fechaApertura: Date().addingTimeInterval(86400 * 30))
                            }
                            itemTitle = ""; itemDesc = ""; showAddModal = false
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAddModal = false }
                }
            }
        }
    }
}
