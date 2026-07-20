import SwiftUI

public struct OnThisDayView: View {
    private let memories: [(date: String, description: String, icon: String)] = [
        ("14 Feb 2025", "Nuestra primera cita", "heart.fill"),
        ("14 Feb 2024", "Nos conocimos", "star.fill")
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                if memories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 56))
                            .foregroundColor(ThemeManager.shared.textSecondary)

                        Text("Hoy no hay recuerdos")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Los recuerdos de este día aparecerán aquí")
                            .font(.system(size: 14))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18))
                                    .foregroundColor(ThemeManager.shared.primaryPink)

                                Text("Revive los momentos de esta fecha")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                            ForEach(memories, id: \.date) { memory in
                                GlassCard {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                                                .frame(width: 56, height: 56)

                                            Image(systemName: memory.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(memory.date)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(ThemeManager.shared.primaryPink)

                                            Text(memory.description)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)

                                            Text("Tal día como hoy")
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Tal día como hoy")
        }
    }
}
