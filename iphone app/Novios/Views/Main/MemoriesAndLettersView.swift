import SwiftUI

public struct MemoriesAndLettersView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedSegment = 0 // 0: Cartas, 1: Recuerdos, 2: Diario
    @State private var showNewCarta = false
    @State private var showNewRecuerdo = false
    @State private var showNewDiario = false

    @State private var cartaTitulo = ""
    @State private var cartaContenido = ""

    @State private var recuerdoTitulo = ""
    @State private var recuerdoDesc = ""

    @State private var diarioTitulo = ""
    @State private var diarioContenido = ""
    @State private var diarioEmocion = "❤️"

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Segment Control
                Picker("Sección", selection: $selectedSegment) {
                    Text("Nuestras Cartas").tag(0)
                    Text("Nuestros Recuerdos").tag(1)
                    Text("Nuestro Diario").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 16) {
                        if selectedSegment == 0 {
                            cartasSection
                        } else if selectedSegment == 1 {
                            recuerdosSection
                        } else {
                            diarioSection
                        }
                    }
                    .padding()
                }
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Nuestra Historia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if selectedSegment == 0 { showNewCarta = true }
                        else if selectedSegment == 1 { showNewRecuerdo = true }
                        else { showNewDiario = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .appFont(size: 20)
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewCarta) { newCartaSheet }
            .sheet(isPresented: $showNewRecuerdo) { newRecuerdoSheet }
            .sheet(isPresented: $showNewDiario) { newDiarioSheet }
        }
    }

    // MARK: - Sections

    private var cartasSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if couple.cartas.isEmpty {
                emptyPlaceholder(icon: "envelope.fill", text: "No hay cartas guardadas aún.\nEscríbele una carta de amor a tu pareja.")
            } else {
                ForEach(couple.cartas) { carta in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(carta.titulo)
                                .appFont(size: 16, weight: .bold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(carta.deUid == CoupleService.diegoUid ? "De: Diego" : "De: Yosmari")
                                .appFont(size: 11)
                                .foregroundColor(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Text(carta.contenido)
                            .appFont(size: 14)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.primary.opacity(0.15)))
                }
            }
        }
    }

    private var recuerdosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if couple.recuerdos.isEmpty {
                emptyPlaceholder(icon: "photo.stack.fill", text: "No hay recuerdos guardados aún.\nAgrega momentos inolvidables.")
            } else {
                ForEach(couple.recuerdos) { rec in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rec.titulo)
                            .appFont(size: 16, weight: .bold)
                        Text(rec.descripcion)
                            .appFont(size: 14)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.pastelPeach.opacity(0.3)))
                }
            }
        }
    }

    private var diarioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if couple.diarioEntries.isEmpty {
                emptyPlaceholder(icon: "book.fill", text: "Tu diario compartido está vacío.\nEscribe tu primer pensamiento juntos.")
            } else {
                ForEach(couple.diarioEntries) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(item.emocion) \(item.titulo)")
                                .appFont(size: 16, weight: .bold)
                            Spacer()
                            Text(item.autorUid == CoupleService.diegoUid ? "Diego" : "Yosmari")
                                .appFont(size: 12)
                                .foregroundColor(theme.textSecondary)
                        }
                        Text(item.contenido)
                            .appFont(size: 14)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private func emptyPlaceholder(icon: String, text: String) -> some View {
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

    // MARK: - Sheets

    private var newCartaSheet: some View {
        NavigationStack {
            Form {
                Section("Escribir Carta") {
                    TextField("Título", text: $cartaTitulo)
                    TextEditor(text: $cartaContenido)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Nueva Carta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !cartaTitulo.isEmpty, !cartaContenido.isEmpty else { return }
                        Task {
                            await couple.addCarta(titulo: cartaTitulo, contenido: cartaContenido)
                            cartaTitulo = ""; cartaContenido = ""; showNewCarta = false
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewCarta = false }
                }
            }
        }
    }

    private var newRecuerdoSheet: some View {
        NavigationStack {
            Form {
                Section("Nuevo Recuerdo") {
                    TextField("Título del recuerdo", text: $recuerdoTitulo)
                    TextField("Descripción", text: $recuerdoDesc)
                }
            }
            .navigationTitle("Agregar Recuerdo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !recuerdoTitulo.isEmpty else { return }
                        Task {
                            await couple.addRecuerdo(titulo: recuerdoTitulo, descripcion: recuerdoDesc, fotoBase64: "")
                            recuerdoTitulo = ""; recuerdoDesc = ""; showNewRecuerdo = false
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewRecuerdo = false }
                }
            }
        }
    }

    private var newDiarioSheet: some View {
        NavigationStack {
            Form {
                Section("Entrada de Diario") {
                    TextField("Título", text: $diarioTitulo)
                    TextField("Emoción (Emoji)", text: $diarioEmocion)
                    TextEditor(text: $diarioContenido)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Escribir en el Diario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !diarioTitulo.isEmpty else { return }
                        Task {
                            await couple.addDiarioEntry(titulo: diarioTitulo, contenido: diarioContenido, emocion: diarioEmocion)
                            diarioTitulo = ""; diarioContenido = ""; showNewDiario = false
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewDiario = false }
                }
            }
        }
    }
}
