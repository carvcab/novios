import SwiftUI

public struct PartnerInfoView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var statusService = StatusService.shared
    @State private var showUnlinkAlert = false
    @State private var showAddPartner = false

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if authService.hasPartner {
                            // Partner avatar
                            ZStack {
                                Circle().fill(LinearGradient(colors: [ThemeManager.shared.primaryPink, ThemeManager.shared.primaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "heart.fill").font(.system(size: 40)).foregroundColor(.white)
                            }
                            .overlay(
                                Circle().stroke(statusService.isOnline ? Color.green : Color.gray, lineWidth: 3)
                                    .frame(width: 106, height: 106)
                            )

                            let partnerName = UserDefaults.standard.string(forKey: "partner_name") ?? "Pareja"
                            Text(partnerName).font(.system(size: 24, weight: .bold)).foregroundColor(.primary)
                            Text(statusService.isOnline ? "🟢 En línea" : "🔴 Desconectado").font(.system(size: 14)).foregroundColor(.primary.opacity(0.6))

                            // Partner details from Firestore
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    let status = statusService.partnerStatus
                                    let battery = status["batteryLevel"] as? Int ?? -1
                                    let isCharging = status["isCharging"] as? Bool ?? false
                                    let currentScreen = status["currentScreen"] as? String ?? ""

                                    detailRow(icon: "battery.100", title: "Batería", value: battery >= 0 ? "\(battery)%\(isCharging ? " ⚡" : "")" : "Desconocido")
                                    if !currentScreen.isEmpty {
                                        detailRow(icon: "eye.fill", title: "Pantalla actual", value: currentScreen)
                                    }
                                    detailRow(icon: "heart.fill", title: "Estado", value: "\(authService.currentUser?.mood ?? "Feliz")")
                                }.padding(8)
                            }.padding(.horizontal, 20)

                            // Unlink button
                            Button(role: .destructive) {
                                showUnlinkAlert = true
                            } label: {
                                Text("Desvincular Pareja").font(.system(size: 16, weight: .bold)).foregroundColor(.red)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(.red.opacity(0.12)).cornerRadius(14)
                            }.padding(.horizontal, 20)
                            .alert("¿Desvincular pareja?", isPresented: $showUnlinkAlert) {
                                Button("Cancelar", role: .cancel) {}
                                Button("Desvincular", role: .destructive) {
                                    unlinkPartner()
                                }
                            } message: {
                                Text("Se eliminará la vinculación con tu pareja actual.")
                            }

                        } else {
                            // No partner
                            Image(systemName: "person.2.slash").font(.system(size: 64)).foregroundColor(.primary.opacity(0.3))
                            Text("Sin pareja vinculada").font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                            Text("Vincula tu cuenta con tu pareja para compartir momentos").font(.system(size: 14)).foregroundColor(.primary.opacity(0.5)).multilineTextAlignment(.center)

                            Button {
                                showAddPartner = true
                            } label: {
                                Text("Vincular Pareja 💖").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                                    .background(ThemeManager.shared.primaryPink).cornerRadius(16)
                            }.padding(.horizontal, 40)
                            .sheet(isPresented: $showAddPartner) {
                                AddPartnerView()
                            }
                        }
                    }
                    .padding(.vertical, 30)
                }
            }
            .navigationTitle("Mi Pareja")
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(ThemeManager.shared.primaryPink).frame(width: 24)
            Text(title).font(.system(size: 14)).foregroundColor(.primary.opacity(0.6))
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
        }
    }

    private func unlinkPartner() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "partner_uid")
        defaults.removeObject(forKey: "partner_name")
        authService.hasPartner = false
        authService.partnerSkipped = false
        // Also try to remove from Firestore
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "partnerUid": "", "partnerName": ""
            ])
        }
    }
}
