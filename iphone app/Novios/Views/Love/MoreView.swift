import SwiftUI
import FirebaseFirestore

struct MoreFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let action: MoreAction
}

enum MoreAction: Hashable {
    case navigate(MoreNavDest)
    case comingSoon
    case download
}

enum MoreNavDest: Hashable {
    case music, loveAI, dates, planner
}

public struct MoreView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var navPath = NavigationPath()
    @State private var showComingSoon = false
    @State private var comingSoonTitle = ""
    @State private var showDownloadAlert = false
    @State private var showBackupSuccess = false

    private let features: [MoreFeature] = [
        MoreFeature(icon: "music.note.list", title: "Música Favorita", subtitle: "Canción, playlist, fondo", action: .navigate(.music)),
        MoreFeature(icon: "brain.head.profile", title: "Asistente Amor IA", subtitle: "Cartas, poemas, citas offline", action: .navigate(.loveAI)),
        MoreFeature(icon: "calendar", title: "Próxima Cita", subtitle: "Cuenta regresiva, cumpleaños", action: .navigate(.dates)),
        MoreFeature(icon: "list.bullet.clipboard", title: "Planificador", subtitle: "Películas, series, restaurantes", action: .navigate(.planner)),
        MoreFeature(icon: "gift", title: "Regalos Virtuales", subtitle: "Flores, chocolates, corazones", action: .comingSoon),
        MoreFeature(icon: "person.2", title: "Compatibilidad", subtitle: "Cuestionario de pareja", action: .comingSoon),
        MoreFeature(icon: "moon.stars", title: "Constelación", subtitle: "El cielo del día que se conocieron", action: .comingSoon),
        MoreFeature(icon: "clock.arrow.circlepath", title: "Hace un Año", subtitle: "Qué pasaba en esta fecha", action: .comingSoon),
        MoreFeature(icon: "mic", title: "Buzón de Voz", subtitle: "Audios para el futuro", action: .comingSoon),
        MoreFeature(icon: "book", title: "Libro Relación", subtitle: "Nuestra historia en TXT", action: .comingSoon),
        MoreFeature(icon: "giftcard", title: "GIFs Favoritos", subtitle: "Tus GIFs de pareja", action: .comingSoon),
        MoreFeature(icon: "lock.shield", title: "Mensajes Cifrados", subtitle: "Cifrado seguro SHA-256+XOR", action: .comingSoon),
        MoreFeature(icon: "square.and.arrow.down", title: "Descargar", subtitle: "Guardar fotos y contenido", action: .download),
    ]

    public init() {}

    public var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                LiquidBackgroundView()

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(features) { feature in
                            featureCard(feature)
                        }
                    }
                    .padding(12)
                }
            }
            .navigationTitle("Más Funciones")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: MoreNavDest.self) { dest in
                switch dest {
                case .music: MusicView()
                case .loveAI: LoveAIView()
                case .dates: DatesView()
                case .planner: PlannerView()
                }
            }
            .alert(comingSoonTitle, isPresented: $showComingSoon) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Esta función estará disponible próximamente.")
            }
            .alert("Descargar Contenido", isPresented: $showDownloadAlert) {
                Button("OK", role: .cancel) { }
                Button("Exportar Backup") { exportBackup() }
            } message: {
                Text("Puedes descargar todas tus fotos y recuerdos desde la sección de Recuerdos. Toca \"Compartir\" en cualquier foto para guardarla.")
            }
            .alert("Backup Exportado", isPresented: $showBackupSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("El backup se ha guardado correctamente en los documentos de la app.")
            }
        }
    }

    private func featureCard(_ feature: MoreFeature) -> some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: feature.icon)
                        .font(.system(size: 22))
                        .foregroundColor(theme.primary)
                }

                Text(feature.title)
                    .appFont(size: 12, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Text(feature.subtitle)
                    .appFont(size: 9)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            switch feature.action {
            case .navigate(let dest):
                navPath.append(dest)
            case .comingSoon:
                comingSoonTitle = feature.title
                showComingSoon = true
            case .download:
                showDownloadAlert = true
            }
        }
    }

    private func exportBackup() {
        Task {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())

            let backup: [String: Any] = [
                "app": "Novios",
                "exportedAt": ISO8601DateFormatter().string(from: Date()),
                "version": "1.0"
            ]

            do {
                let data = try JSONSerialization.data(withJSONObject: backup, options: .prettyPrinted)
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsPath.appendingPathComponent("novios_backup_\(timestamp).json")
                try data.write(to: fileURL)

                await MainActor.run {
                    showDownloadAlert = false
                    showBackupSuccess = true
                }
            } catch {
                print("Backup failed: \(error)")
            }
        }
    }
}
