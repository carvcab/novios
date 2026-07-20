import SwiftUI

public struct JournalView: View {
    @State private var entries: [JournalModel] = [
        JournalModel(authorId: "user_me", content: "Hoy tuvimos una videollamada hermosa. Me encantó verte sonreír.", moodEmoji: "🥰", date: Date().addingTimeInterval(-86400)),
        JournalModel(authorId: "partner_123", content: "Contando los días para nuestro próximo viaje juntos. Te amo.", moodEmoji: "✈️", date: Date().addingTimeInterval(-172800))
    ]
    @State private var newEntryText = ""
    
    public var body: some View {
        VStack(spacing: 16) {
            // Nueva entrada
            GlassCard {
                HStack {
                    TextField("Escribe una entrada en el diario compartido...", text: $newEntryText)
                        .foregroundColor(.white)
                    
                    Button {
                        if !newEntryText.trimmingCharacters(in: .whitespaces).isEmpty {
                            entries.insert(JournalModel(authorId: "user_me", content: newEntryText), at: 0)
                            newEntryText = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(entries) { entry in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.moodEmoji)
                                        .font(.system(size: 20))
                                    
                                    Text(entry.authorId == "user_me" ? "Tú" : "Mi Pareja ❤️")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    
                                    Spacer()
                                    
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 11))
                                        .foregroundColor(ThemeManager.shared.textSecondary)
                                }
                                
                                Text(entry.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
