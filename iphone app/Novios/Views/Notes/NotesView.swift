import SwiftUI

public struct NotesView: View {
    @State private var notes: [(String, String, String, String)] = [
        ("\u{1F4DD}", "Lista de la compra", "Pan, leche, huevos...", "Hace 2h"),
        ("\u{2764}\u{FE0F}", "Cosas que me gustan", "Tu sonrisa, tu forma de mirar...", "Ayer"),
        ("\u{1F3AC}", "Películas para ver", "Interestelar, Up, Inside Out", "Hace 3 días")
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Notas Compartidas")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                            }
                        }
                        .padding(.horizontal, 20)

                        ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                            GlassCard {
                                HStack(spacing: 14) {
                                    Text(note.0)
                                        .font(.system(size: 32))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.1)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(note.2)
                                            .font(.system(size: 13))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                            .lineLimit(2)

                                        Text(note.3)
                                            .font(.system(size: 11))
                                            .foregroundColor(ThemeManager.shared.textSecondary.opacity(0.6))
                                    }

                                    Spacer()
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    notes.remove(at: index)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    notes.remove(at: index)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Notas")
        }
    }
}
