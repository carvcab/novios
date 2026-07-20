import SwiftUI

public struct CapsuleView: View {
    @State private var capsules: [CapsuleModel] = [
        CapsuleModel(title: "Para nuestro 1er Aniversario 🎂", message: "¡Feliz aniversario mi amor! Cuando abras esto habremos vivido experiencias increíbles juntos.", unlockDate: Date().addingTimeInterval(86400 * 30), authorId: "user_me"),
        CapsuleModel(title: "Recuerdo Secreto 💌", message: "Te escribí esto el día que nos conocimos.", unlockDate: Date().addingTimeInterval(-86400), authorId: "partner_123")
    ]
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(capsules) { capsule in
                    GlassCard {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(capsule.isUnlocked ? ThemeManager.shared.primaryPink.opacity(0.2) : Color.white.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: capsule.isUnlocked ? "lock.open.fill" : "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(capsule.isUnlocked ? ThemeManager.shared.primaryPink : .gray)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(capsule.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                if capsule.isUnlocked {
                                    Text(capsule.message)
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeManager.shared.textSecondary)
                                } else {
                                    Text("Se desbloqueará el \(capsule.unlockDate.formatted(date: .numeric, time: .omitted))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
