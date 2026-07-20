import SwiftUI

public struct AICoupleAssistantView: View {
    @State private var selectedMode = "Carta 💌"

    @State private var tone = "Romántico"
    @State private var keywords = ""

    @State private var style = "Clásico"
    @State private var topic = ""

    @State private var dateType = "Cena"
    @State private var budget = ""

    @State private var occasion = "Cumpleaños"

    @State private var genre = "Pop"
    @State private var details = ""

    @State private var storyTitle = ""
    @State private var storyDetails = ""

    @State private var chatQuestion = ""

    @State private var result = ""
    @State private var showResult = false
    @State private var showCopyAlert = false
    @State private var showSentAlert = false

    @State private var isDownloading = false
    @State private var downloadProgressValue: Double = 0

    private let modes = ["Carta 💌", "Poema 🌹", "Cita 🍕", "Regalo 🎁", "Canción 🎵", "Historia 📖", "Chat IA 🤖"]
    private let aiService = AIService.shared

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(modes, id: \.self) { mode in
                                Button {
                                    selectedMode = mode
                                    showResult = false
                                    result = ""
                                } label: {
                                    Text(mode)
                                        .font(.system(size: 13, weight: selectedMode == mode ? .bold : .regular))
                                        .foregroundColor(selectedMode == mode ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedMode == mode
                                            ? ThemeManager.shared.neonGlowGradient
                                            : GlassCard(cornerRadius: 20, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                                                Color.clear
                                            }
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)

                        if showResult {
                            resultCard
                        }

                        switch selectedMode {
                        case "Carta 💌":
                            letterView
                        case "Poema 🌹":
                            poemView
                        case "Cita 🍕":
                            dateView
                        case "Regalo 🎁":
                            giftView
                        case "Canción 🎵":
                            songView
                        case "Historia 📖":
                            storyView
                        case "Chat IA 🤖":
                            chatView
                        default:
                            EmptyView()
                        }

                        modelStatusBar
                    }
                    .padding(.vertical)
                }
            }
            .alert("Copiado", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Texto copiado al portapapeles")
            }
            .alert("Enviado al Chat", isPresented: $showSentAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("El contenido fue enviado al chat.")
            }
            .navigationTitle("Asistente IA")
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Resultado")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(result)
                    .font(.body)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = result
                        showCopyAlert = true
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(GlassCard(cornerRadius: 16, opacity: 0.1, borderColor: Color.white.opacity(0.15)) {
                                Color.clear
                            })
                            .cornerRadius(16)
                    }

                    Button {
                        showSentAlert = true
                    } label: {
                        Label("Enviar al Chat", systemImage: "paperplane")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ThemeManager.shared.neonGlowGradient)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var letterView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generar Carta")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("Tono", selection: $tone) {
                    ForEach(["Romántico", "Apasionado", "Dulce", "Divertido"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                TextField("Palabras clave (ej. eterno, besos)", text: $keywords)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.generateLetter(tone: tone, keywords: keywords.isEmpty ? "amor" : keywords)
                    showResult = true
                } label: {
                    Text("Generar Carta")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var poemView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generar Poema")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("Estilo", selection: $style) {
                    ForEach(["Clásico", "Moderno", "Libre", "Rima"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                TextField("Tema (ej. luna, pasión)", text: $topic)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.generatePoem(style: style, topic: topic.isEmpty ? "amor" : topic)
                    showResult = true
                } label: {
                    Text("Generar Poema")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var dateView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sugerir Cita")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("Tipo", selection: $dateType) {
                    ForEach(["Cena", "Aventura", "Relax", "Cultura"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                TextField("Presupuesto (ej. 50€, sin límite)", text: $budget)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.suggestDate(type: dateType, budget: budget.isEmpty ? "moderado" : budget)
                    showResult = true
                } label: {
                    Text("Sugerir Cita")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var giftView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sugerir Regalo")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("Ocasión", selection: $occasion) {
                    ForEach(["Cumpleaños", "Aniversario", "San Valentín", "Sin motivo"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                Button {
                    result = aiService.suggestGift(occasion: occasion)
                    showResult = true
                } label: {
                    Text("Sugerir Regalo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var songView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generar Canción")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("Género", selection: $genre) {
                    ForEach(["Pop", "Romántica", "Bachata", "Reggaeton"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                TextField("Detalles (ej. nuestra historia)", text: $details)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.generateSong(genre: genre, details: details.isEmpty ? "nuestro amor" : details)
                    showResult = true
                } label: {
                    Text("Generar Canción")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var storyView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generar Historia")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Título del recuerdo", text: $storyTitle)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                TextField("Detalles (ej. se conocieron en...)", text: $storyDetails)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.generateStory(title: storyTitle.isEmpty ? "Nuestra Historia" : storyTitle, details: storyDetails.isEmpty ? "se amaban profundamente" : storyDetails)
                    showResult = true
                } label: {
                    Text("Generar Historia")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var chatView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Chat IA")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Pregunta sobre tu relación...", text: $chatQuestion)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(GlassCard(cornerRadius: 12, opacity: 0.1, borderColor: Color.white.opacity(0.1)) {
                        Color.clear
                    })
                    .cornerRadius(12)

                Button {
                    result = aiService.answerRelationshipQuestion(question: chatQuestion.isEmpty ? "¿Cómo mejorar?" : chatQuestion)
                    showResult = true
                } label: {
                    Text("Preguntar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var modelStatusBar: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Modo: DeepSeek API (En línea)")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(aiService.localModelDownloaded ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Modelo Local: \(aiService.localModelDownloaded ? "Descargado" : "No descargado")")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()

                    if !aiService.localModelDownloaded {
                        Button {
                            isDownloading = true
                            downloadProgressValue = 0
                            aiService.downloadLocalModel()
                            simulateDownload()
                        } label: {
                            Text(isDownloading ? "\(Int(downloadProgressValue * 100))%" : "Descargar")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ThemeManager.shared.neonGlowGradient)
                                .cornerRadius(12)
                        }
                        .disabled(isDownloading)
                    }
                }

                if isDownloading {
                    ProgressView(value: downloadProgressValue)
                        .progressViewStyle(.linear)
                        .tint(ThemeManager.shared.primaryPink)
                }
            }
        }
        .padding(.horizontal)
    }

    private func simulateDownload() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if downloadProgressValue >= 1.0 {
                timer.invalidate()
                isDownloading = false
                aiService.localModelDownloaded = true
                aiService.downloadProgress = 1.0
            } else {
                downloadProgressValue += 0.05
                aiService.downloadProgress = downloadProgressValue
            }
        }
    }
}
