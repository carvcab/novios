import SwiftUI

public struct AICoupleAssistantView: View {
    @StateObject private var aiService = AIService.shared
    @State private var inputPrompt = ""
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(aiService.aiConversation) { msg in
                                HStack {
                                    if msg.isUser { Spacer() }
                                    
                                    VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .padding(14)
                                            .background(
                                                msg.isUser
                                                ? ThemeManager.shared.neonGlowGradient
                                                : LinearGradient(colors: [ThemeManager.shared.cardBackground, ThemeManager.shared.cardBackground], startPoint: .top, endPoint: .bottom)
                                            )
                                            .cornerRadius(18)
                                    }
                                    
                                    if !msg.isUser { Spacer() }
                                }
                                .padding(.horizontal, 16)
                                .id(msg.id)
                            }
                            
                            if aiService.isGenerating {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.shared.primaryPink))
                                    Text("Gemini AI está pensando...")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeManager.shared.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                
                // Input Bar
                HStack(spacing: 10) {
                    TextField("Pregúntale algo a la IA...", text: $inputPrompt)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(ThemeManager.shared.cardBackground)
                        .cornerRadius(20)
                    
                    Button {
                        let query = inputPrompt.trimmingCharacters(in: .whitespaces)
                        if !query.isEmpty {
                            inputPrompt = ""
                            Task {
                                await aiService.sendQuery(query)
                            }
                        }
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
            }
        }
        .navigationTitle("Asistente de IA Gemini")
    }
}
