import SwiftUI
import UIKit

public struct LoveAIView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var aiService = AIService.shared

    @State private var activeTab = "letter"
    @State private var generating = false
    @State private var resultText = ""
    @State private var showCopied = false

    // Form fields
    @State private var keywords = ""
    @State private var topic = ""
    @State private var details = ""
    @State private var question = ""
    @State private var storyTitle = ""

    // Dropdowns
    @State private var letterTone = "Romántico"
    @State private var dateType = "Aventura"
    @State private var dateBudget = "Medio"
    @State private var giftOccasion = "Aniversario"
    @State private var poemStyle = "Romántico"
    @State private var songGenre = "Balada"

    private let letterTones = ["Romántico", "Apasionado", "Dulce", "Divertido", "Nostálgico"]
    private let dateTypes = ["Aventura", "Romántica", "Cultural", "Gastronómica", "Sorpresa"]
    private let budgets = ["Bajo", "Medio", "Alto"]
    private let occasions = ["Aniversario", "Cumpleaños", "San Valentín", "Navidad", "Sorpresa", "Pedida de mano", "Aniversario de bodas"]
    private let poemStyles = ["Romántico", "Clásico", "Moderno", "Libre", "Rima"]
    private let songGenres = ["Balada", "Pop", "Reggaetón", "Bachata", "Rock", "Salsa", "Mariachi"]

    private let tabs: [(id: String, icon: String, label: String)] = [
        ("letter", "envelope.fill", "Carta"),
        ("poem", "doc.text.fill", "Poema"),
        ("date", "heart.fill", "Cita"),
        ("gift", "gift.fill", "Regalo"),
        ("song", "music.note.list", "Canción"),
        ("story", "book.fill", "Historia"),
        ("chat", "message.fill", "Chat IA"),
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView {
                VStack(spacing: 16) {
                    warningBanner
                    tabGrid
                    formSection
                    generateButton
                    resultSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Asistente de Amor IA")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Warning Banner

    @ViewBuilder
    private var warningBanner: some View {
        if aiService.currentMode == .deepseek && !aiService.hasApiKey {
            GlassCard(cornerRadius: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text("No hay API key configurada. Ve a Ajustes > IA para configurarla o cambia a modo Local.")
                        .appFont(size: 12)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                    Spacer()
                }
            }
            .padding(.top, 4)
        } else if aiService.currentMode == .local {
            GlassCard(cornerRadius: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(theme.pastelMint)
                    Text("Modo Local activo — sin necesidad de internet ni API key.")
                        .appFont(size: 12)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                    Spacer()
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Tab Grid

    private var tabGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(tabs, id: \.id) { tab in
                tabButton(tab)
            }
        }
    }

    private func tabButton(_ tab: (id: String, icon: String, label: String)) -> some View {
        let isActive = activeTab == tab.id
        return GlassCard(cornerRadius: 14) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .white : theme.primary)
                Text(tab.label)
                    .appFont(size: 10, weight: isActive ? .bold : .medium)
                    .foregroundColor(isActive ? .white : theme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? AnyView(theme.primaryGradient) : AnyView(Color.clear))
            .cornerRadius(14)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                activeTab = tab.id
                resultText = ""
            }
        }
    }

    // MARK: - Form Section

    @ViewBuilder
    private var formSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 16) {
                switch activeTab {
                case "letter": letterForm
                case "poem": poemForm
                case "date": dateForm
                case "gift": giftForm
                case "song": songForm
                case "story": storyForm
                case "chat": chatForm
                default: EmptyView()
                }
            }
        }
    }

    // MARK: - Carta

    private var letterForm: some View {
        VStack(spacing: 14) {
            dropdownField(label: "Tono", selection: $letterTone, options: letterTones)
            textField(label: "Palabras clave", text: $keywords, placeholder: "amor, eternidad, felicidad...")
        }
    }

    // MARK: - Poema

    private var poemForm: some View {
        VStack(spacing: 14) {
            dropdownField(label: "Estilo", selection: $poemStyle, options: poemStyles)
            textField(label: "Tema", text: $topic, placeholder: "ej. nuestro amor, la luna, el mar...")
        }
    }

    // MARK: - Cita

    private var dateForm: some View {
        VStack(spacing: 14) {
            dropdownField(label: "Tipo", selection: $dateType, options: dateTypes)
            dropdownField(label: "Presupuesto", selection: $dateBudget, options: budgets)
        }
    }

    // MARK: - Regalo

    private var giftForm: some View {
        dropdownField(label: "Ocasión", selection: $giftOccasion, options: occasions)
    }

    // MARK: - Canción

    private var songForm: some View {
        VStack(spacing: 14) {
            dropdownField(label: "Género", selection: $songGenre, options: songGenres)
            textField(label: "Detalles", text: $details, placeholder: "tema, artista, ocasión...")
        }
    }

    // MARK: - Historia

    private var storyForm: some View {
        VStack(spacing: 14) {
            textField(label: "Título", text: $storyTitle, placeholder: "ej. Nuestra primera cita")
            textField(label: "Detalles", text: $details, placeholder: "describe lo que quieres incluir...")
        }
    }

    // MARK: - Chat IA

    private var chatForm: some View {
        textField(label: "Pregunta", text: $question, placeholder: "ej. ¿Qué puedo hacer para sorprender a mi pareja?")
    }

    // MARK: - Dropdown

    private func dropdownField(label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .appFont(size: 13, weight: .semibold)
                .foregroundColor(theme.textSecondary)
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                        .appFont(size: 14)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(theme.surfaceBackground)
            .cornerRadius(10)
        }
    }

    // MARK: - Text Field

    private func textField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .appFont(size: 13, weight: .semibold)
                .foregroundColor(theme.textSecondary)
            TextField(placeholder, text: text)
                .appFont(size: 14)
                .foregroundColor(theme.textPrimary)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(theme.surfaceBackground)
                .cornerRadius(10)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            generate()
        } label: {
            HStack(spacing: 8) {
                if generating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .appFont(size: 17, weight: .bold)
                    Text("Generar con IA")
                        .appFont(size: 16, weight: .bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(theme.primaryGradient)
            .cornerRadius(18)
            .shadow(color: theme.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            .opacity(generating || !canGenerate ? 0.6 : 1)
        }
        .disabled(generating || !canGenerate)
    }

    private var canGenerate: Bool {
        guard aiService.canGenerate else { return false }
        switch activeTab {
        case "letter": return !keywords.trimmingCharacters(in: .whitespaces).isEmpty
        case "poem": return !topic.trimmingCharacters(in: .whitespaces).isEmpty
        case "date": return true
        case "gift": return true
        case "song": return !details.trimmingCharacters(in: .whitespaces).isEmpty
        case "story": return !storyTitle.trimmingCharacters(in: .whitespaces).isEmpty
        case "chat": return !question.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    // MARK: - Result Section

    @ViewBuilder
    private var resultSection: some View {
        if !resultText.isEmpty {
            GlassCard(cornerRadius: 18) {
                VStack(spacing: 12) {
                    ScrollView {
                        Text(resultText)
                            .appFont(size: 14)
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .lineSpacing(6)
                    }
                    .frame(maxHeight: 300)

                    Divider()
                        .background(theme.primary.opacity(0.2))

                    HStack(spacing: 12) {
                        actionButton(
                            icon: showCopied ? "checkmark" : "doc.on.doc",
                            title: showCopied ? "Copiado" : "Copiar",
                            color: theme.primary
                        ) {
                            UIPasteboard.general.string = resultText
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopied = false }
                            }
                        }

                        actionButton(
                            icon: "paperplane.fill",
                            title: "Enviar al Chat",
                            color: Color(red: 0.31, green: 0.76, blue: 0.97)
                        ) {
                            ChatService.shared.sendMessage(text: resultText)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.primaryGradient, lineWidth: 1.5)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .appFont(size: 13, weight: .semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color)
            .cornerRadius(12)
        }
    }

    // MARK: - Generate Logic

    private func generate() {
        generating = true
        resultText = ""

        Task {
            do {
                let result: String
                switch activeTab {
                case "letter":
                    result = try await aiService.generateLetter(tone: letterTone, keywords: keywords)
                case "poem":
                    result = try await aiService.generatePoem(style: poemStyle, topic: topic)
                case "date":
                    result = try await aiService.suggestDate(type: dateType, budget: dateBudget)
                case "gift":
                    result = try await aiService.suggestGift(occasion: giftOccasion)
                case "song":
                    result = try await aiService.chat(prompt: "Escribe la letra de una canción de amor en género \(songGenre) sobre \(details). Incluye título y letra completa.")
                case "story":
                    result = try await aiService.chat(prompt: "Escribe una historia de amor corta titulada \"\(storyTitle)\" con los siguientes detalles: \(details). Sé creativo y emotivo.")
                case "chat":
                    result = try await aiService.chat(prompt: question)
                default:
                    result = ""
                }

                await MainActor.run {
                    withAnimation {
                        resultText = result
                        generating = false
                    }
                }
            } catch {
                await MainActor.run {
                    resultText = "Error: \(error.localizedDescription)"
                    generating = false
                }
            }
        }
    }
}
