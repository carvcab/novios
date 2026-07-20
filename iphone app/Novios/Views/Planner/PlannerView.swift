import SwiftUI

public struct PlannerView: View {
    @State private var events: [EventModel] = [
        EventModel(title: "Cita de San Valentín 🍷", notes: "Reservar en el restaurante italiano", eventDate: Date().addingTimeInterval(86400 * 5), location: "Restaurante Bella Italia", createdBy: "user_me", category: "Cita"),
        EventModel(title: "Cine y Palomitas 🍿", notes: "Ver la película de estreno", eventDate: Date().addingTimeInterval(86400 * 12), location: "Cine Center", createdBy: "partner_123", category: "Paseo")
    ]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Próxima Cita
                        if let first = events.first {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("PRÓXIMA CITA DE PAREJA")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                        Spacer()
                                        Text(first.category)
                                            .font(.system(size: 11, weight: .semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(ThemeManager.shared.primaryPink.opacity(0.2))
                                            .cornerRadius(8)
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                    }
                                    
                                    Text(first.title)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if let loc = first.location {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin.and.ellipse")
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                            Text(loc)
                                                .font(.system(size: 13))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }
                                    }
                                    
                                    Text("Fecha: \(first.eventDate.formatted(date: .long, time: .shortened))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Todas las Citas y Eventos")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ForEach(events) { ev in
                                GlassCard {
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "calendar.badge.clock")
                                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(ev.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            Text(ev.eventDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Agenda de Citas")
        }
    }
}
