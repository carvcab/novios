import SwiftUI

public struct LoveView: View {
    @State private var events: [(id: String, emoji: String, title: String, description: String, date: Date)] = []
    @State private var lovePoints: Int = 0
    @State private var totalLovePoints: Int = 1000
    @State private var currentLevel: Int = 1
    @State private var messagesSent: Int = 0
    @State private var photosShared: Int = 0
    @State private var goalsCompleted: Int = 0
    @State private var showAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventEmoji = "\u{1F491}"
    @State private var newEventDescription = ""

    private let anniversaryDate: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 10
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var yearsTogether: Int { totalDays / 365 }
    private var monthsTogether: Int { (totalDays % 365) / 30 }
    private var remDays: Int { totalDays % 30 }
    private var totalDays: Int { Calendar.current.dateComponents([.day], from: anniversaryDate, to: Date()).day ?? 0 }

    private var nextAnniversaryDays: Int {
        let calendar = Calendar.current
        var next = calendar.date(bySetting: .month, value: calendar.component(.month, from: anniversaryDate), of: Date())!
        next = calendar.date(bySetting: .day, value: calendar.component(.day, from: anniversaryDate), of: next)!
        if next < Date() { next = calendar.date(byAdding: .year, value: 1, to: next)! }
        return calendar.dateComponents([.day], from: Date(), to: next).day ?? 0
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        anniversaryHeroSection
                        statsSection
                        timelineSection
                        lovePointsSection
                        compatibilitySection
                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Amor \u{2764}\u{FE0F}")
            .task { await loadFromFirestore() }
            .alert("Nuevo evento", isPresented: $showAddEvent) {
                TextField("T\u{00ED}tulo", text: $newEventTitle)
                TextField("Emoji", text: $newEventEmoji)
                TextField("Descripci\u{00F3}n", text: $newEventDescription)
                Button("Cancelar", role: .cancel) { resetNewEventFields() }
                Button("Guardar") { addTimelineEvent() }
            }
        }
    }

    private func loadFromFirestore() async {
        let items = await FirestoreSyncService.shared.loadTimelineEvents()
        var loaded: [(id: String, emoji: String, title: String, description: String, date: Date)] = []
        for item in items {
            let id = item["id"] as? String ?? ""
            let emoji = item["emoji"] as? String ?? "\u{1F491}"
            let title = item["title"] as? String ?? ""
            let desc = item["description"] as? String ?? ""
            let date = item["date"] as? Date ?? Date()
            loaded.append((id: id, emoji: emoji, title: title, description: desc, date: date))
        }
        events = loaded
    }

    private func addTimelineEvent() {
        let title = newEventTitle
        let emoji = newEventEmoji
        let desc = newEventDescription
        Task {
            await FirestoreSyncService.shared.saveTimelineEvent(title: title, description: desc, date: Date(), emoji: emoji)
            resetNewEventFields()
            await loadFromFirestore()
        }
    }

    private func deleteTimelineEvent(at id: String) {
        Task {
            await FirestoreSyncService.shared.deleteTimelineEvent(id: id)
            await loadFromFirestore()
        }
    }

    private func resetNewEventFields() {
        newEventTitle = ""
        newEventEmoji = "\u{1F491}"
        newEventDescription = ""
    }

    private var anniversaryHeroSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.neonGlowGradient)
                        .frame(width: 72, height: 72)
                        .shadow(color: ThemeManager.shared.primaryPink.opacity(0.4), radius: 20)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.primary)
                }

                Text("Nuestro Aniversario")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(yearsTogether) a\u{00F1}os  \(monthsTogether) meses  \(remDays) d\u{00ED}as")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text(nextAnniversaryDays == 0
                     ? "\u{1F389} \u{00A1}Hoy es nuestro aniversario!"
                     : "Pr\u{00F3}ximo aniversario: \(nextAnniversaryDays) d\u{00ED}as")
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.6))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(value: "\(totalDays)", label: "D\u{00ED}as juntos", icon: "calendar", color: ThemeManager.shared.primaryPink)
            StatCardView(value: "\(messagesSent)", label: "Mensajes enviados", icon: "message.fill", color: Color(red: 0.49, green: 0.51, blue: 1.0))
            StatCardView(value: "\(photosShared)", label: "Fotos compartidas", icon: "photo.fill", color: Color(red: 1.0, green: 0.72, blue: 0.3))
            StatCardView(value: "\(goalsCompleted)", label: "Metas cumplidas", icon: "checkmark.seal.fill", color: Color.green)
        }
        .padding(.horizontal, 16)
    }

    private var timelineSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "timeline.selection")
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Nuestra Historia")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Text(event.emoji)
                                    .font(.system(size: 20))
                                    .frame(width: 36, height: 36)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.1))
                                    .clipShape(Circle())
                                if index < events.count - 1 {
                                    Rectangle()
                                        .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                                        .frame(width: 2)
                                        .frame(height: 40)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(event.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary.opacity(0.65))
                            }

                            Spacer()
                        }
                        .padding(.bottom, index < events.count - 1 ? 4 : 0)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTimelineEvent(at: event.id)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        showAddEvent = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Agregar evento")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(ThemeManager.shared.primaryPink.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var lovePointsSection: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Puntos de Amor")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(lovePoints) / \(totalLovePoints)")
                            .font(.system(size: 13))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Nivel \(currentLevel)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\u{1F495}")
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ThemeManager.shared.primaryPink.opacity(0.12))
                    .clipShape(Capsule())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ThemeManager.shared.neonGlowGradient)
                            .frame(width: geo.size.width * CGFloat(lovePoints) / CGFloat(totalLovePoints), height: 14)
                            .animation(.easeInOut(duration: 0.5), value: lovePoints)
                    }
                }
                .frame(height: 14)

                Text("Sube de nivel")
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
    }

    private var compatibilitySection: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Compatibilidad")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                ZStack {
                    Circle()
                        .stroke(ThemeManager.shared.primaryPink.opacity(0.15), lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: 0)
                        .stroke(ThemeManager.shared.neonGlowGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Text("--%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }

                NavigationLink(destination: CompatibilityView()) {
                    HStack(spacing: 6) {
                        Text("Test de compatibilidad")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(ThemeManager.shared.primaryPink)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(ThemeManager.shared.primaryPink.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

public struct StatCardView: View {
    public let value: String
    public let label: String
    public let icon: String
    public let color: Color

    public var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.primary.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
    }
}
