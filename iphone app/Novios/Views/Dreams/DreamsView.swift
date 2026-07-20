import SwiftUI

public struct DreamsView: View {
    @State private var selectedFilter: DreamFilter = .todos

    private let allDreams: [(String, String, String, String)] = [
        ("\u{1F3E0}", "Casa propia", "Tener nuestra casa con jardín", "Cumplido"),
        ("\u{2708}\u{FE0F}", "Viajar a Japón", "Conocer Tokyo juntos", "Pendiente"),
        ("\u{1F415}", "Tener un perro", "Adoptar un golden retriever", "Pendiente"),
        ("\u{1F393}", "Graduarnos", "Terminar nuestros estudios", "Cumplido")
    ]

    private var filteredDreams: [(String, String, String, String)] {
        switch selectedFilter {
        case .todos:
            return allDreams
        case .pendientes:
            return allDreams.filter { $0.3 == "Pendiente" }
        case .cumplidos:
            return allDreams.filter { $0.3 == "Cumplido" }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Sueños Compartidos")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Agregar sueño")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(ThemeManager.shared.primaryPink)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 8) {
                            ForEach(DreamFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedFilter == filter ? .white : ThemeManager.shared.textSecondary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? ThemeManager.shared.primaryPink : Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(Array(filteredDreams.enumerated()), id: \.offset) { _, dream in
                                GlassCard(cornerRadius: 20) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(dream.0)
                                            .font(.system(size: 36))

                                        Text(dream.1)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(dream.2)
                                            .font(.system(size: 12))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                            .lineLimit(2)

                                        HStack(spacing: 4) {
                                            Text(dream.3 == "Cumplido" ? "\u{2705}" : "\u{23F3}")
                                                .font(.system(size: 12))
                                            Text(dream.3)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(dream.3 == "Cumplido" ? .green : .orange)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Sueños")
        }
    }
}

private enum DreamFilter: String, CaseIterable {
    case todos = "Todos"
    case pendientes = "Pendientes"
    case cumplidos = "Cumplidos"
}
