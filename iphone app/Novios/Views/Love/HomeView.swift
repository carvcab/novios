import SwiftUI
import PhotosUI

public struct HomeView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var location = LocationService.shared
    @ObservedObject private var status = StatusService.shared
    @StateObject private var vm = HomeViewModel()
    @Namespace private var heartNamespace

    public init() {}

    public var body: some View {
        NavigationStack(path: $vm.navPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heartSection
                    coupleNamesSection
                    statusCardsSection
                    quoteSection
                    coverPhotoSection
                    infoStripSection
                    featureGridSection
                    moodSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EverUs")
                        .appFont(size: 14, weight: .medium)
                        .foregroundColor(theme.primary)
                        .tracking(3)
                }
            }
            .navigationDestination(for: HomeNavDest.self) { dest in
                switch dest {
                case .letters: LettersView()
                case .memories: MemoriesView()
                case .games: GamesView()
                case .music: MusicView()
                case .notifications: NotificationsView()
                }
            }
            .sheet(isPresented: $vm.showPhotoPicker) {
                PhotoPicker(completion: { path in vm.setCoverPhoto(path: path) })
            }
            .onAppear { vm.onAppear() }
        }
    }

    // MARK: - Heart & Particles
    private var heartSection: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(vm.particles) { p in
                    Image(systemName: "heart.fill")
                        .font(.system(size: p.size))
                        .foregroundColor(theme.primary.opacity(p.opacity))
                        .offset(x: p.x, y: p.y)
                        .opacity(p.opacity)
                }
                Circle()
                    .fill(theme.primary.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(theme.primary)
                    )
                    .scaleEffect(vm.heartScale)
            }
            .frame(height: 110)
            .contentShape(Rectangle())
            .onTapGesture { vm.tapHeart(theme: theme) }
        }
        .padding(.top, 8)
    }

    // MARK: - Couple Names + Time Together
    private var coupleNamesSection: some View {
        VStack(spacing: 4) {
            Text("\(vm.myName)  \(HeartSymbol)  \(vm.partnerName)")
                .appFont(size: 20, weight: .semibold)
                .foregroundColor(theme.textPrimary)
                .tracking(1)
            Text(vm.timeTogether)
                .appFont(size: 26, weight: .light)
                .foregroundColor(theme.primary)
                .tracking(1)
        }
        .padding(.bottom, 20)
    }

    private var HeartSymbol: String { "💞" }

    // MARK: - Status Cards (Noti + En Vivo)
    private var statusCardsSection: some View {
        HStack(spacing: 12) {
            statusCard(
                icon: "bell.fill",
                title: "Noti",
                subtitle: "Actividad",
                color: theme.primary
            )
            .onTapGesture { vm.navPath.append(HomeNavDest.notifications) }

            statusCard(
                icon: location.partnerOnline ? "heart.fill" : "heart",
                title: "En Vivo",
                subtitle: location.partnerOnline ? (status.partnerStatus["currentScreen"] as? String ?? "En línea") : "Offline",
                color: location.partnerOnline ? .green : theme.textSecondary
            )
            .onTapGesture { vm.showComingSoon("En Vivo") }
        }
        .padding(.bottom, 16)
    }

    private func statusCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                Text(title)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                Text(subtitle)
                    .appFont(size: 10)
                    .foregroundColor(color == .green ? .green : theme.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Daily Quote
    private var quoteSection: some View {
        GlassCard(cornerRadius: 18) {
            HStack(spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 18))
                    .foregroundColor(theme.primary.opacity(0.3))
                Text("\"\(vm.dailyQuote)\"")
                    .appFont(size: 14)
                    .foregroundColor(theme.textPrimary)
                    .lineSpacing(4)
                    .italic()
                Spacer()
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Cover Photo
    private var coverPhotoSection: some View {
        ZStack {
            if let path = vm.coverPhotoPath, let uiimg = UIImage(contentsOfFile: path) {
                Image(uiImage: uiimg)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(colors: [
                            theme.primary.opacity(0.15),
                            theme.secondary.opacity(0.1)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(theme.primary.opacity(0.4))
                            Text("Toca para poner tu foto aquí")
                                .appFont(size: 14)
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                        }
                    )
            }
        }
        .shadow(color: theme.primary.opacity(0.08), radius: 20, x: 0, y: 8)
        .contentShape(Rectangle())
        .onTapGesture { vm.pickPhoto() }
        .contextMenu {
            if vm.coverPhotoPath != nil {
                Button(role: .destructive) { vm.removeCoverPhoto() } label: {
                    Label("Eliminar", systemImage: "trash")
                }
                Button { vm.pickPhoto() } label: {
                    Label("Cambiar", systemImage: "photo")
                }
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Info Strip (Distance + Countdown)
    private var infoStripSection: some View {
        HStack(spacing: 10) {
            infoCard(
                icon: "location.fill",
                iconColor: Color(red: 0.49, green: 0.51, blue: 1.0),
                value: vm.distanceText,
                label: vm.distanceSubtitle
            )
            infoCard(
                icon: "hourglass.bottomhalf.fill",
                iconColor: Color(red: 0.94, green: 0.33, blue: 0.31),
                value: vm.countdownText,
                label: vm.countdownLabel
            )
        }
        .padding(.bottom, 20)
    }

    private func infoCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    Text(label)
                        .appFont(size: 10)
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Feature Grid (4x3)
    private var featureGridSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(vm.features) { feature in
                featureCard(feature)
            }
        }
        .padding(.bottom, 20)
    }

    private func featureCard(_ f: HomeFeature) -> some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(f.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: f.icon)
                        .font(.system(size: 22))
                        .foregroundColor(f.color)
                }
                Text(f.label)
                    .appFont(size: 12, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            f.action()
        }
    }

    // MARK: - Mood & Weather
    private var moodSection: some View {
        HStack(spacing: 10) {
            GlassCard(cornerRadius: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.primary)
                    Text("Feliz")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textPrimary)
                    Text("Hoy")
                        .appFont(size: 11)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            GlassCard(cornerRadius: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.primary)
                    Text("Soleado")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textPrimary)
                    Text("Relación")
                        .appFont(size: 11)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
}

enum HomeNavDest: Hashable {
    case letters, memories, games, music, notifications
}

struct HomeFeature: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

struct HeartParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var heartScale: CGFloat = 1.0
    @Published var timeTogether: String = ""
    @Published var particles: [HeartParticle] = []
    @Published var coverPhotoPath: String? {
        didSet { UserDefaults.standard.set(coverPhotoPath, forKey: "home_cover_photo") }
    }
    @Published var showPhotoPicker = false
    @Published var dailyQuote: String = ""
    @Published var navPath = NavigationPath()

    let myName: String
    let partnerName: String

    private let allQuotes: [String]
    private var heartPulseTimer: Timer?
    private var timeTimer: Timer?

    init() {
        let isDiego = AuthService.shared.currentUser?.id == CoupleService.diegoUid
        myName = isDiego ? "Diego" : "Yosmari"
        partnerName = isDiego ? "Yosmari" : "Diego"
        allQuotes = Self.loadQuotes()
        dailyQuote = allQuotes[Calendar.current.component(.day, from: Date()) % allQuotes.count]
        coverPhotoPath = UserDefaults.standard.string(forKey: "home_cover_photo")
    }

    func onAppear() {
        startHeartPulse()
        startTimeUpdates()
    }

    func tapHeart(theme: ThemeManager) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        spawnParticles()
        let quote = allQuotes.randomElement() ?? dailyQuote
        showQuoteAlert(quote)
    }

    func pickPhoto() {
        showPhotoPicker = true
    }

    func setCoverPhoto(path: String) {
        coverPhotoPath = path
    }

    func removeCoverPhoto() {
        if let path = coverPhotoPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        coverPhotoPath = nil
    }

    func showComingSoon(_ name: String) {
        let alert = UIAlertController(title: name, message: "Próximamente disponible", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC()?.present(alert, animated: true)
    }

    // MARK: - Computed Properties

    var distanceText: String {
        if let d = LocationService.shared.distanceToPartner {
            return String(format: "%.1f km", d)
        }
        return "Sin datos"
    }

    var distanceSubtitle: String {
        if let d = LocationService.shared.distanceToPartner, d < 0.2 {
            return "¡Juntos! ❤️"
        }
        return "Distancia"
    }

    var countdownText: String {
        guard let days = daysUntilNextEvent else { return "Configura" }
        return days == 0 ? "¡HOY! 🎉" : "\(days) días"
    }

    var countdownLabel: String {
        daysUntilNextEvent == nil ? "Tu fecha" : (isMesiversaryNext ? "Mesiversario" : "Aniversario")
    }

    private var daysUntilNextEvent: Int? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let ann = anniversaryDate else { return nil }
        guard let nextAnn = nextAnniversary(after: today, from: ann),
              let nextMon = nextMesiversary(after: today, from: ann) else { return nil }
        return min(
            Calendar.current.dateComponents([.day], from: today, to: nextAnn).day ?? 365,
            Calendar.current.dateComponents([.day], from: today, to: nextMon).day ?? 365
        )
    }

    private var isMesiversaryNext: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        guard let ann = anniversaryDate else { return false }
        guard let nextAnn = nextAnniversary(after: today, from: ann),
              let nextMon = nextMesiversary(after: today, from: ann) else { return false }
        return Calendar.current.dateComponents([.day], from: today, to: nextMon).day ?? 365
             < Calendar.current.dateComponents([.day], from: today, to: nextAnn).day ?? 365
    }

    private var anniversaryDate: Date? {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.locale = Locale(identifier: "en_US_POSIX")
        let str = UserDefaults.standard.string(forKey: "couple_anniversary_date")
            ?? UserDefaults.standard.string(forKey: "anniversary_date")
        guard let s = str else { return nil }
        return ISO8601DateFormatter().date(from: s) ?? df.date(from: s)
    }

    private func nextAnniversary(after today: Date, from start: Date) -> Date? {
        let comps = Calendar.current.dateComponents([.month, .day], from: start)
        guard let m = comps.month, let d = comps.day else { return nil }
        let thisYear = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: today), month: m, day: d))!
        if thisYear < today {
            return Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: today) + 1, month: m, day: d))!
        }
        return thisYear
    }

    private func nextMesiversary(after today: Date, from start: Date) -> Date? {
        let comps = Calendar.current.dateComponents([.day], from: start)
        guard let d = comps.day else { return nil }
        let thisMonth = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: today), month: Calendar.current.component(.month, from: today), day: d))!
        if thisMonth < today {
            var nextM = Calendar.current.component(.month, from: today) + 1
            var nextY = Calendar.current.component(.year, from: today)
            if nextM > 12 { nextM = 1; nextY += 1 }
            let lastDay = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: DateComponents(year: nextY, month: nextM))!)!.count
            return Calendar.current.date(from: DateComponents(year: nextY, month: nextM, day: min(d, lastDay)))!
        }
        return thisMonth
    }

    // MARK: - Features
    lazy var features: [HomeFeature] = [
        HomeFeature(icon: "square.and.arrow.up", label: "Pantalla", color: Color(red: 0, green: 0.75, blue: 0.65)) { [weak self] in self?.showComingSoon("Pantalla") },
        HomeFeature(icon: "envelope.fill", label: "Cartas", color: Color(red: 1, green: 0.5, blue: 0.5)) { [weak self] in self?.navPath.append(HomeNavDest.letters) },
        HomeFeature(icon: "sticky.filler", label: "Notas", color: Color(red: 0.91, green: 0.28, blue: 0.49)) { [weak self] in self?.showComingSoon("Notas") },
        HomeFeature(icon: "face.smiling", label: "Amor IA", color: Color(red: 0.31, green: 0.76, blue: 0.97)) { [weak self] in self?.showComingSoon("Amor IA") },
        HomeFeature(icon: "photo.on.rectangle", label: "Recuerdos", color: Color(red: 0.49, green: 0.51, blue: 1.0)) { [weak self] in self?.navPath.append(HomeNavDest.memories) },
        HomeFeature(icon: "gamecontroller.fill", label: "Juegos", color: Color(red: 1, green: 0.72, blue: 0.30)) { [weak self] in self?.navPath.append(HomeNavDest.games) },
        HomeFeature(icon: "sparkles", label: "Deseos", color: Color(red: 0.67, green: 0.28, blue: 0.74)) { [weak self] in self?.showComingSoon("Deseos") },
        HomeFeature(icon: "moon.stars.fill", label: "Sueños", color: Color(red: 0.36, green: 0.42, blue: 0.75)) { [weak self] in self?.showComingSoon("Sueños") },
        HomeFeature(icon: "list.bullet.clipboard", label: "Planner", color: Color(red: 0.4, green: 0.73, blue: 0.42)) { [weak self] in self?.showComingSoon("Planner") },
        HomeFeature(icon: "music.note.list", label: "Música", color: Color(red: 0.15, green: 0.65, blue: 0.60)) { [weak self] in self?.navPath.append(HomeNavDest.music) },
        HomeFeature(icon: "calendar", label: "Fechas", color: Color(red: 0.94, green: 0.33, blue: 0.31)) { [weak self] in self?.showComingSoon("Fechas") },
        HomeFeature(icon: "square.grid.2x2", label: "Más", color: Color(red: 0.47, green: 0.56, blue: 0.61)) { [weak self] in self?.showComingSoon("Más") },
    ]

    // MARK: - Heart Pulse
    private func startHeartPulse() {
        heartPulseTimer?.invalidate()
        heartPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.heartScale = sin(Date().timeIntervalSince1970 * 2.1) * 0.04 + 1.0
            }
        }
    }

    // MARK: - Particles
    private func spawnParticles() {
        for _ in 0..<6 {
            particles.append(HeartParticle(
                x: CGFloat.random(in: -60...60),
                y: CGFloat.random(in: -80...(-40)),
                size: CGFloat.random(in: 6...16),
                opacity: Double.random(in: 0.4...0.8)
            ))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.particles.removeAll()
        }
    }

    // MARK: - Quote Alert
    private func showQuoteAlert(_ quote: String) {
        let alert = UIAlertController(title: nil, message: quote, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "❤️", style: .default))
        topVC()?.present(alert, animated: true)
    }

    // MARK: - Time Updates
    private func startTimeUpdates() {
        updateTimeTogether()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeTogether()
        }
    }

    private func updateTimeTogether() {
        guard let ann = anniversaryDate else {
            timeTogether = "0 días"
            return
        }
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: ann, to: Date())
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        var parts: [String] = []
        if y > 0 { parts.append("\(y) a") }
        if m > 0 { parts.append("\(m) m") }
        if d > 0 { parts.append("\(d) d") }
        timeTogether = parts.isEmpty ? "0 días" : parts.joined(separator: " ")
    }

    // MARK: - Helpers

    private static func loadQuotes() -> [String] {
        [
            "El mejor lugar del mundo eres tú.",
            "Te amo no solo por lo que eres, sino por lo que soy cuando estoy contigo.",
            "Eres mi momento favorito del día.",
            "En un beso, sabrás todo lo que he callado.",
            "Si sé lo que es el amor, es por ti.",
            "Eres la casualidad más hermosa de mi vida.",
            "Juntos es mi lugar favorito para estar.",
            "Te elegiría a ti cien veces, en cien mundos.",
            "Amar no es mirarse el uno al otro; es mirar juntos en la misma dirección.",
            "Eres la canción que hace latir mi corazón.",
        ]
    }

    private func topVC() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let window = scenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        var vc = window?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }

    deinit {
        heartPulseTimer?.invalidate()
        timeTimer?.invalidate()
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    let completion: (String) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (String) -> Void
        init(completion: @escaping (String) -> Void) { self.completion = completion }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first, result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard let uiImage = image as? UIImage, error == nil else { return }
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let folder = docs.appendingPathComponent("cover_photos", isDirectory: true)
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let fileURL = folder.appendingPathComponent("cover_\(Date().timeIntervalSince1970).jpg")
                if let data = uiImage.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: fileURL)
                    DispatchQueue.main.async { self.completion(fileURL.path) }
                }
            }
        }
    }
}

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
