import SwiftUI

struct ImportantDate: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let date: String
}

public struct ProfileView: View {
    @State private var name: String = "Diego"
    @State private var isOnline: Bool = true
    @State private var streakDays: Int = 15
    @State private var bestStreak: Int = 42
    @State private var weekStatus: [Bool] = [true, true, true, false, true, true, false]
    @State private var dates: [ImportantDate] = [
        ImportantDate(icon: "\u{1F491}", title: "Nos conocimos", date: "10 Dic 2024"),
        ImportantDate(icon: "\u{1F48D}", title: "Aniversario", date: "14 Feb 2025"),
        ImportantDate(icon: "\u{2708}\u{FE0F}", title: "Primer viaje", date: "01 Jun 2025")
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        streakSection
                        importantDatesSection
                        quickAccessGrid
                        photoGallery
                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Button {
                    // mock change photo
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.7))
                        .overlay(
                            Circle()
                                .stroke(ThemeManager.shared.primaryPurple.opacity(0.3), lineWidth: 3)
                        )
                }

                Button {
                    // edit profile
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .background(Circle().fill(.white).frame(width: 26, height: 26))
                }
                .offset(x: -4, y: -4)
            }

            Text(name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Button {
                isOnline.toggle()
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isOnline ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(isOnline ? "En l\u{00ED}nea" : "Ausente")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    Text("\u{1F525}\(streakDays) d\u{00ED}as seguidos")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text("Mejor racha: \(bestStreak) d\u{00ED}as")
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.5))

                HStack(spacing: 10) {
                    ForEach(Array(weekStatus.enumerated()), id: \.offset) { index, filled in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(filled ? ThemeManager.shared.primaryPink : Color.gray.opacity(0.3))
                                .frame(width: 14, height: 14)
                            Text(dayLabel(for: index))
                                .font(.system(size: 10))
                                .foregroundColor(.primary.opacity(0.4))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    private func dayLabel(for index: Int) -> String {
        let days = ["Lun", "Mar", "Mi\u{00E9}", "Jue", "Vie", "S\u{00E1}b", "Dom"]
        return days[index]
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Fechas Importantes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            ForEach(dates) { date in
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 22))
                            .foregroundColor(ThemeManager.shared.primaryPink)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(date.icon) \(date.title)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(date.date)
                                .font(.system(size: 13))
                                .foregroundColor(.primary.opacity(0.5))
                        }

                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        dates.removeAll { $0.id == date.id }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }

            Button {
                // add date
            } label: {
                GlassCard {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                        Text("Agregar fecha")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Access Grid

    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Accesos r\u{00E1}pidos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                quickAccessItem(icon: "person.2", title: "Mi Pareja")
                quickAccessItem(icon: "heart", title: "Favoritos")
                quickAccessItem(icon: "gearshape", title: "Ajustes")
                quickAccessItem(icon: "questionmark.circle", title: "Ayuda")
                quickAccessItem(icon: "arrow.right.square", title: "Cerrar sesi\u{00F3}n")
                quickAccessItem(icon: "trash", title: "Eliminar cuenta")
            }
        }
        .padding(.horizontal, 16)
    }

    private func quickAccessItem(icon: String, title: String) -> some View {
        Button {
            // handle tap
        } label: {
            GlassCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Gallery

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Mis Fotos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<6) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(photoColor(for: index))
                            .frame(width: 120, height: 160)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private func photoColor(for index: Int) -> Color {
        let colors: [Color] = [
            ThemeManager.shared.primaryPink.opacity(0.3),
            ThemeManager.shared.primaryPurple.opacity(0.3),
            .orange.opacity(0.3),
            .blue.opacity(0.3),
            .green.opacity(0.3),
            .yellow.opacity(0.3)
        ]
        return colors[index % colors.count]
    }
}
