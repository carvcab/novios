import SwiftUI

public struct StatsView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var daysTogether = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView {
                    VStack(spacing: 20) {
                        daysCounter
                        statsGrid
                        relationshipMilestones
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Estadísticas 📊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } } }
            .onAppear { calculateDays() }
        }
    }

    private var daysCounter: some View {
        VStack(spacing: 4) {
            Text("\(daysTogether)")
                .appFont(size: 48, weight: .bold).foregroundColor(theme.primary)
            Text("días juntos 💞")
                .appFont(size: 16, weight: .medium).foregroundColor(theme.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2)))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(icon: "message.fill", value: "\(messageCount)", label: "Mensajes", color: .blue)
            statCard(icon: "photo.fill", value: "\(couple.recuerdos.count)", label: "Recuerdos", color: .purple)
            statCard(icon: "envelope.fill", value: "\(couple.cartas.count)", label: "Cartas", color: theme.primary)
            statCard(icon: "star.fill", value: "\(couple.logros.count)", label: "Metas cumplidas", color: .green)
            statCard(icon: "book.fill", value: "\(couple.diarioEntries.count)", label: "Diario", color: .orange)
            statCard(icon: "music.note", value: "\(couple.musica.count)", label: "Canciones", color: .yellow)
            statCard(icon: "heart.text.square", value: "\(couple.citas.count)", label: "Citas", color: .red)
            statCard(icon: "checklist", value: "\(couple.todoItems.count)", label: "Tareas", color: .indigo)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).appFont(size: 22).foregroundColor(color)
            Text(value).appFont(size: 20, weight: .bold).foregroundColor(.primary)
            Text(label).appFont(size: 11).foregroundColor(theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.2)))
    }

    private var relationshipMilestones: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Hitos de la Relación 🏆").appFont(size: 14, weight: .semibold)
                milestoneRow(emoji: "💌", text: "\(couple.cartas.count) cartas de amor escritas")
                milestoneRow(emoji: "📸", text: "\(couple.recuerdos.count) momentos capturados")
                milestoneRow(emoji: "🎯", text: "\(couple.logros.count) metas alcanzadas")
                milestoneRow(emoji: "📖", text: "\(couple.diarioEntries.count) días en el diario")
            }
        }
    }

    private func milestoneRow(emoji: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji).appFont(size: 16)
            Text(text).appFont(size: 13).foregroundColor(theme.textSecondary)
        }
    }

    private var messageCount: String {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: "chat_message_count")
        return "\(max(count, ChatService.shared.messages.count))"
    }

    private func calculateDays() {
        let defaults = UserDefaults.standard
        let dateStr = defaults.string(forKey: "anniversary_date") ?? defaults.string(forKey: "couple_anniversary_date") ?? ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let ref = df.date(from: dateStr) ?? Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()
        let comps = Calendar.current.dateComponents([.day], from: ref, to: Date())
        daysTogether = comps.day ?? 0
    }
}
