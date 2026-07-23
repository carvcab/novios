import SwiftUI
import UIKit

struct MoreFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let action: MoreAction
}

enum MoreAction {
    case navigate(MoreNavDest)
    case comingSoon
    case download
}

enum MoreNavDest {
    case music, loveAI, dates, planner, gifts, compatibility, constellation, onThisDay, voiceMailbox, relationshipBook, gifs, encryption
}

public struct MoreView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var showComingSoon = false
    @State private var comingSoonTitle = ""
    @State private var showDownloadAlert = false
    @State private var showBackupSuccess = false
    @State private var showMusic = false
    @State private var showLoveAI = false
    @State private var showDates = false
    @State private var showPlanner = false
    @State private var showGifts = false
    @State private var showCompatibility = false
    @State private var showConstellation = false
    @State private var showOnThisDay = false
    @State private var showVoiceMailbox = false
    @State private var showRelationshipBook = false
    @State private var showGIFs = false
    @State private var showEncryption = false

    private let features: [MoreFeature] = [
        MoreFeature(icon: "music.note.list", title: "Música Favorita", subtitle: "Canción, playlist, fondo", action: .navigate(.music)),
        MoreFeature(icon: "brain.head.profile", title: "Asistente Amor IA", subtitle: "Cartas, poemas, citas offline", action: .navigate(.loveAI)),
        MoreFeature(icon: "calendar", title: "Próxima Cita", subtitle: "Cuenta regresiva, cumpleaños", action: .navigate(.dates)),
        MoreFeature(icon: "list.bullet.clipboard", title: "Planificador", subtitle: "Películas, series, restaurantes", action: .navigate(.planner)),
        MoreFeature(icon: "gift", title: "Regalos Virtuales", subtitle: "Flores, chocolates, corazones", action: .navigate(.gifts)),
        MoreFeature(icon: "person.2", title: "Compatibilidad", subtitle: "Cuestionario de pareja", action: .navigate(.compatibility)),
        MoreFeature(icon: "moon.stars", title: "Constelación", subtitle: "El cielo del día que se conocieron", action: .navigate(.constellation)),
        MoreFeature(icon: "clock.arrow.circlepath", title: "Hace un Año", subtitle: "Qué pasaba en esta fecha", action: .navigate(.onThisDay)),
        MoreFeature(icon: "mic", title: "Buzón de Voz", subtitle: "Audios para el futuro", action: .navigate(.voiceMailbox)),
        MoreFeature(icon: "book", title: "Libro Relación", subtitle: "Nuestra historia en TXT", action: .navigate(.relationshipBook)),
        MoreFeature(icon: "giftcard", title: "GIFs Favoritos", subtitle: "Tus GIFs de pareja", action: .navigate(.gifs)),
        MoreFeature(icon: "lock.shield", title: "Mensajes Cifrados", subtitle: "Cifrado seguro SHA-256+XOR", action: .navigate(.encryption)),
        MoreFeature(icon: "square.and.arrow.down", title: "Descargar", subtitle: "Guardar fotos y contenido", action: .download),
    ]

    public init() {}

    public var body: some View {
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
        .sheet(isPresented: $showMusic) { MusicView() }
        .sheet(isPresented: $showLoveAI) { LoveAIView() }
        .sheet(isPresented: $showDates) { DatesView() }
        .sheet(isPresented: $showPlanner) { PlannerView() }
        .sheet(isPresented: $showGifts) { GiftsScreen() }
        .sheet(isPresented: $showCompatibility) { CompatibilityScreen() }
        .sheet(isPresented: $showConstellation) { ConstellationScreen() }
        .sheet(isPresented: $showOnThisDay) { OnThisDayScreen() }
        .sheet(isPresented: $showVoiceMailbox) { VoiceMailboxScreen() }
        .sheet(isPresented: $showRelationshipBook) { RelationshipBookScreen() }
        .sheet(isPresented: $showGIFs) { FavoriteGIFsScreen() }
        .sheet(isPresented: $showEncryption) { EncryptionScreen() }
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
                switch dest {
                case .music: showMusic = true
                case .loveAI: showLoveAI = true
                case .dates: showDates = true
                case .planner: showPlanner = true
                case .gifts: showGifts = true
                case .compatibility: showCompatibility = true
                case .constellation: showConstellation = true
                case .onThisDay: showOnThisDay = true
                case .voiceMailbox: showVoiceMailbox = true
                case .relationshipBook: showRelationshipBook = true
                case .gifs: showGIFs = true
                case .encryption: showEncryption = true
                }
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
