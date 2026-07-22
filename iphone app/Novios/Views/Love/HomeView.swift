import SwiftUI

public struct HomeView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var location = LocationService.shared
    @State private var timeTogether: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusSection
                    quickGrid
                    statsSection
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { updateTime() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(couple.coupleName)
                .appFont(size: 26, weight: .bold)
                .foregroundColor(theme.primary)
            HStack(spacing: 6) {
                Circle().fill(location.partnerOnline ? Color.green : Color.gray).frame(width: 8, height: 8)
                Text(location.partnerOnline ? "En línea" : "Sin conexión")
                    .appFont(size: 12).foregroundColor(theme.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2)))
    }

    private var statusSection: some View {
        HStack(spacing: 16) {
            statCard(icon: "heart.fill", value: timeTogether, label: "Juntos", color: theme.primary)
            if let dist = location.distanceToPartner {
                statCard(icon: "ruler", value: String(format: "%.1f km", dist), label: "Distancia", color: .blue)
            }
            statCard(icon: "message.fill", value: "\(couple.chatCount)", label: "Mensajes", color: .orange)
            statCard(icon: "photo.fill", value: "\(couple.recuerdos.count)", label: "Recuerdos", color: .purple)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).appFont(size: 18).foregroundColor(color)
            Text(value).appFont(size: 14, weight: .bold).foregroundColor(.primary).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).appFont(size: 10).foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2)))
    }

    private var quickGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickItem(icon: "envelope.fill", title: "Cartas", color: theme.primary)
            quickItem(icon: "photo.on.rectangle.angled", title: "Recuerdos", color: .purple)
            quickItem(icon: "gamecontroller.fill", title: "Juegos", color: .orange)
            quickItem(icon: "book.closed.fill", title: "Diario", color: .blue)
            quickItem(icon: "music.note.list", title: "Música", color: .yellow)
            quickItem(icon: "star.fill", title: "Metas", color: .green)
            quickItem(icon: "heart.text.square.fill", title: "Citas", color: .red)
            quickItem(icon: "checkmark.square.fill", title: "Tareas", color: .indigo)
            quickItem(icon: "hourglass", title: "Cápsula", color: .mint)
        }
    }

    private func quickItem(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).appFont(size: 22).foregroundColor(color)
            Text(title).appFont(size: 11, weight: .semibold).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.15)))
    }

    private var statsSection: some View {
        GlassCard {
            VStack(spacing: 10) {
                Text("Nuestra Relación en Números")
                    .appFont(size: 14, weight: .semibold)
                HStack(spacing: 16) {
                    miniStat("\(couple.cartas.count)", "Cartas")
                    miniStat("\(couple.logros.count)", "Metas")
                    miniStat("\(couple.eventos.count)", "Eventos")
                    miniStat("\(couple.citas.count)", "Citas")
                }
            }
        }
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).appFont(size: 16, weight: .bold).foregroundColor(theme.primary)
            Text(label).appFont(size: 10).foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func updateTime() {
        let df = DateFormatter()
        df.dateFormat = "d 'de' MMMM 'de' yyyy"
        let ref = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()
        let comps = Calendar.current.dateComponents([.day], from: ref, to: Date())
        if let days = comps.day {
            timeTogether = "\(days) días"
        }
    }
}

private extension CoupleService {
    var chatCount: Int { UserDefaults.standard.integer(forKey: "chat_message_count") }
}
