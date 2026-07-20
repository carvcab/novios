import Foundation
import SwiftUI
import PhotosUI

public struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    @State private var isOnline: Bool = true
    @State private var streakDays: Int = 0
    @State private var bestStreak: Int = 0
    @State private var lastActiveDate: Date? = nil
    @State private var showAddDate = false
    @State private var newDateTitle = ""
    @State private var newDatePicker = Date()
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var importantDates: [ImportantDate2] = []

    private let streakKey = "streak_days"
    private let bestStreakKey = "best_streak"
    private let lastActiveKey = "last_active_date"

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        streakSection
                        importantDatesSection
                        quickAccessGrid
                        photoGallery
                        Color.clear.frame(height: 24)
                    }.padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadStreak(); checkAndUpdateStreak(); Task { await loadDates() } }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .alert("Agregar fecha importante", isPresented: $showAddDate) {
                TextField("Título", text: $newDateTitle)
                DatePicker("Fecha", selection: $newDatePicker, displayedComponents: .date)
                Button("Cancelar", role: .cancel) { newDateTitle = "" }
                Button("Guardar") {
                    if !newDateTitle.isEmpty {
                        Task { await saveImportantDate(title: newDateTitle, date: newDatePicker) }
                        newDateTitle = ""
                    }
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Button {
                    showPhotoPicker = true
                } label: {
                    if let photo = authService.currentUser?.avatarUrl {
                        AsyncImage(url: URL(string: photo)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill").font(.system(size: 100))
                        }
                        .frame(width: 100, height: 100).clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill").font(.system(size: 100))
                            .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.7))
                    }
                }
                Button {
                    showPhotoPicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill").font(.system(size: 28))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .background(Circle().fill(.white).frame(width: 26, height: 26))
                }.offset(x: -4, y: -4)
            }
            Text(authService.currentUser?.displayName ?? "Usuario")
                .font(.system(size: 22, weight: .bold)).foregroundColor(.primary)
            Button {
                isOnline.toggle()
                userService.updateMood(emoji: isOnline ? "🥰" : "😴", message: isOnline ? "En línea" : "Ausente")
            } label: {
                HStack(spacing: 6) {
                    Circle().fill(isOnline ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text(isOnline ? "En línea" : "Ausente").font(.system(size: 14, weight: .medium)).foregroundColor(.primary.opacity(0.6))
                }
            }
        }
    }

    private var streakSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill").font(.system(size: 28)).foregroundColor(.orange)
                    Text("🔥 \(streakDays) días seguidos").font(.system(size: 18, weight: .semibold)).foregroundColor(.primary)
                }
                Text("Mejor racha: \(bestStreak) días").font(.system(size: 14)).foregroundColor(.primary.opacity(0.5))
                HStack(spacing: 10) {
                    ForEach(0..<7) { i in
                        let day = Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
                        let filled = Calendar.current.isDateInToday(day) || (lastActiveDate != nil && day <= lastActiveDate!)
                        VStack(spacing: 4) {
                            Circle().fill(filled ? ThemeManager.shared.primaryPink : Color.gray.opacity(0.3)).frame(width: 14, height: 14)
                            Text(["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"][Calendar.current.component(.weekday, from: day) - 1])
                                .font(.system(size: 10)).foregroundColor(.primary.opacity(0.4))
                        }
                    }
                }
            }.frame(maxWidth: .infinity)
        }.padding(.horizontal, 16)
    }

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar").foregroundColor(ThemeManager.shared.primaryPink)
                Text("Fechas Importantes").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                Spacer()
            }
            ForEach(importantDates) { d in
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                            Text(formatDate(d.date)).font(.system(size: 13)).foregroundColor(.primary.opacity(0.5))
                            Text(countdownText(d.date)).font(.system(size: 11)).foregroundColor(ThemeManager.shared.primaryPink)
                        }
                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { Task { await deleteImportantDate(d) } } label: { Label("Eliminar", systemImage: "trash") }
                }
            }
            Button {
                showAddDate = true
            } label: {
                GlassCard {
                    HStack {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(ThemeManager.shared.primaryPink)
                        Text("Agregar fecha").font(.system(size: 14, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                        Spacer()
                    }
                }
            }
        }.padding(.horizontal, 16)
    }

    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2").foregroundColor(ThemeManager.shared.primaryPink)
                Text("Accesos rápidos").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                Spacer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                quickItem(icon: "person.2", title: "Mi Pareja", dest: AnyView(PartnerInfoView()))
                quickItem(icon: "heart", title: "Favoritos", dest: AnyView(FavoriteGifsView()))
                quickItem(icon: "gearshape", title: "Ajustes", dest: AnyView(SettingsView()))
                quickItem(icon: "lock.shield", title: "Bloqueo", dest: AnyView(LockScreenView()))
                quickItem(icon: "bell.badge", title: "Notificaciones", dest: AnyView(NotificationsView()))
            }
        }.padding(.horizontal, 16)
    }

    private func quickItem(icon: String, title: String, dest: AnyView) -> some View {
        NavigationLink(destination: dest) {
            GlassCard {
                VStack(spacing: 8) {
                    Image(systemName: icon).font(.system(size: 24)).foregroundColor(ThemeManager.shared.primaryPink)
                    Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.primary)
                }.frame(maxWidth: .infinity).padding(.vertical, 12)
            }
        }.buttonStyle(.plain)
    }

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled").foregroundColor(ThemeManager.shared.primaryPink)
                Text("Mis Fotos").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<6) { i in
                        RoundedRectangle(cornerRadius: 16)
                            .fill([ThemeManager.shared.primaryPink, ThemeManager.shared.primaryPurple, .orange, .blue, .green, .yellow][i % 6].opacity(0.3))
                            .frame(width: 120, height: 160)
                            .overlay(Image(systemName: "photo.fill").font(.system(size: 32)).foregroundColor(.white.opacity(0.6)))
                    }
                }.padding(.horizontal, 4)
            }
        }.padding(.horizontal, 16)
    }

    // MARK: - Streak Logic
    private func loadStreak() {
        let defaults = UserDefaults.standard
        streakDays = defaults.integer(forKey: streakKey)
        bestStreak = defaults.integer(forKey: bestStreakKey)
        if let saved = defaults.object(forKey: lastActiveKey) as? Date {
            lastActiveDate = saved
        }
    }

    private func saveStreak() {
        let defaults = UserDefaults.standard
        defaults.set(streakDays, forKey: streakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        defaults.set(lastActiveDate, forKey: lastActiveKey)
    }

    private func checkAndUpdateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastActiveDate {
            let diff = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            if diff == 0 { return }
            if diff == 1 {
                streakDays += 1
                if streakDays > bestStreak { bestStreak = streakDays }
            } else {
                streakDays = 0
            }
        } else {
            streakDays = 1
            if streakDays > bestStreak { bestStreak = streakDays }
        }
        lastActiveDate = today
        saveStreak()
    }

    // MARK: - Important Dates Persistence
    private func loadDates() async {
        let items = await FirestoreSyncService.shared.loadImportantDates()
        importantDates = items.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let title = dict["title"] as? String,
                  let date = dict["date"] as? Date else { return nil }
            let icon = dict["icon"] as? String ?? "calendar.badge.clock"
            return ImportantDate2(id: id, title: title, date: date, icon: icon)
        }
    }

    private func saveImportantDate(title: String, date: Date) async {
        await FirestoreSyncService.shared.saveImportantDate(title: title, date: date, icon: "calendar.badge.clock")
        await loadDates()
    }

    private func deleteImportantDate(_ d: ImportantDate2) async {
        await FirestoreSyncService.shared.deleteImportantDate(id: d.id)
        await loadDates()
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long; f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }

    private func countdownText(_ date: Date) -> String {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if diff > 0 { return "Faltan \(diff) días" }
        if diff == 0 { return "¡Hoy! 🎉" }
        return "Hace \(-diff) días"
    }
}

private struct ImportantDate2: Identifiable {
    let id: String
    let title: String
    let date: Date
    let icon: String
}

private struct PartnerInfoView: View {
    var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill").font(.system(size: 80)).foregroundColor(ThemeManager.shared.primaryPink)
                Text(AuthService.shared.currentUser?.partnerUid != nil ? "Pareja vinculada 💕" : "Sin pareja vinculada")
                    .font(.title2).foregroundColor(.primary)
            }
        }.navigationTitle("Mi Pareja")
    }
}
