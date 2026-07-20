import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var enablePin = false
    @State private var pinCode = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Card
                        GlassCard {
                            HStack(spacing: 16) {
                                Circle().fill(ThemeManager.shared.primaryPink.opacity(0.2)).frame(width: 60, height: 60)
                                    .overlay(Image(systemName: "person.fill").font(.system(size: 30)).foregroundColor(ThemeManager.shared.primaryPink))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authService.currentUser?.displayName ?? "Usuario").font(.system(size: 18, weight: .bold)).foregroundColor(.primary)
                                    Text("@\(authService.currentUser?.username ?? "usuario")").font(.system(size: 13)).foregroundColor(ThemeManager.shared.primaryPink)
                                }
                                Spacer()
                            }
                        }.padding(.horizontal, 20)

                        // Important Dates
                        NavigationLink(destination: ImportantDatesView()) {
                            GlassCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "calendar").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                                        .padding(10).background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Fechas Importantes").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                        Text("Aniversarios, cumpleaños y más").font(.system(size: 11)).foregroundColor(ThemeManager.shared.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.primary.opacity(0.3))
                                }
                            }
                        }.buttonStyle(.plain).padding(.horizontal, 20)

                        // Partner Info
                        GlassCard {
                            HStack(spacing: 14) {
                                Image(systemName: "person.2.fill").font(.system(size: 22)).foregroundColor(Color(red: 0.49, green: 0.51, blue: 1.0))
                                    .padding(10).background(Color(red: 0.49, green: 0.51, blue: 1.0).opacity(0.12)).cornerRadius(12)
                                VStack(alignment: .leading, spacing: 2) {
                                    let name = UserDefaults.standard.string(forKey: "partner_name") ?? "Sin pareja"
                                    Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                    Text(authService.hasPartner ? "Pareja vinculada" : "Sin pareja vinculada").font(.system(size: 11)).foregroundColor(ThemeManager.shared.textSecondary)
                                }
                                Spacer()
                            }
                        }.padding(.horizontal, 20)

                        // Security
                        GlassCard {
                            VStack(spacing: 16) {
                                Toggle(isOn: $themeManager.pinLockEnabled) {
                                    Label("Bloqueo de App con PIN / Face ID", systemImage: "lock.shield.fill").foregroundColor(.primary)
                                }.tint(ThemeManager.shared.primaryPink)

                                Toggle(isOn: $themeManager.enableHaptics) {
                                    Label("Vibración Háptica", systemImage: "waveform").foregroundColor(.primary)
                                }.tint(ThemeManager.shared.primaryPink)
                            }
                        }.padding(.horizontal, 20)

                        // Account Info
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "info.circle.fill").foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("CUENTA").font(.system(size: 11, weight: .bold)).foregroundColor(.primary)
                                }
                                HStack {
                                    Text("Correo").font(.system(size: 13)).foregroundColor(ThemeManager.shared.textSecondary)
                                    Spacer()
                                    Text(authService.currentUser?.email ?? "").font(.system(size: 13)).foregroundColor(.primary)
                                }
                            }
                        }.padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
