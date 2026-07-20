import SwiftUI

public struct MemoryDetailView: View {
    private let frameStyles = ["Standard", "Polaroid", "Romántico", "Vintage", "Ticket", "Hearts", "Stars", "Floral", "Glow"]
    private let stickerOptions = ["❤️", "💍", "🌸", "🌹", "✨", "💑", "🎵", "🌺", "💋", "💕", "🎀", "🌈", "🌟", "🦋", "💫"]
    private let pastelColors: [(name: String, color: Color)] = [
        ("Blanco", .white),
        ("Rosa", Color(red: 1.0, green: 0.85, blue: 0.9)),
        ("Durazno", Color(red: 1.0, green: 0.89, blue: 0.77)),
        ("Lavanda", Color(red: 0.85, green: 0.82, blue: 0.96)),
        ("Menta", Color(red: 0.82, green: 0.94, blue: 0.85)),
        ("Azul cielo", Color(red: 0.82, green: 0.9, blue: 0.98))
    ]

    @State private var selectedFrame = "Standard"
    @State private var selectedColor = Color.white
    @State private var selectedStickers: [String] = []
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var showSavedAlert = false

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedColor)
                                .frame(height: 220)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ThemeManager.shared.primaryPink.opacity(0.2), lineWidth: 1)
                                )

                            VStack(spacing: 12) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.5))

                                Text("Toque para añadir foto")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }

                            if !selectedStickers.isEmpty {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 4) {
                                            ForEach(selectedStickers.prefix(3), id: \.self) { s in
                                                Text(s).font(.system(size: 20))
                                            }
                                            if selectedStickers.count > 3 {
                                                Text("+\(selectedStickers.count - 3)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                            }
                                        }
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Marco")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(frameStyles, id: \.self) { style in
                                        Button(action: { selectedFrame = style }) {
                                            Text(style)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(selectedFrame == style ? .white : .primary)
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedFrame == style
                                                        ? ThemeManager.shared.primaryPink
                                                        : ThemeManager.shared.cardBackground
                                                )
                                                .cornerRadius(14)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color de marco")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                ForEach(pastelColors, id: \.name) { item in
                                    Button(action: { selectedColor = item.color }) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == item.color ? ThemeManager.shared.primaryPink : Color.gray.opacity(0.2), lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stickers")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                                ForEach(stickerOptions, id: \.self) { sticker in
                                    Button(action: {
                                        if selectedStickers.contains(sticker) {
                                            selectedStickers.removeAll { $0 == sticker }
                                        } else {
                                            selectedStickers.append(sticker)
                                        }
                                    }) {
                                        Text(sticker)
                                            .font(.system(size: 28))
                                            .frame(width: 52, height: 52)
                                            .background(
                                                selectedStickers.contains(sticker)
                                                    ? ThemeManager.shared.primaryPink.opacity(0.2)
                                                    : ThemeManager.shared.cardBackground
                                            )
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(selectedStickers.contains(sticker) ? ThemeManager.shared.primaryPink : Color.gray.opacity(0.15), lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            CustomTextField(placeholder: "Título", text: $title, icon: "textformat")

                            CustomTextField(placeholder: "Descripción", text: $description, icon: "pencil")

                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.primary.opacity(0.4))
                                    .font(.system(size: 18))

                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(ThemeManager.shared.primaryPink)

                                Spacer()
                            }
                            .padding()
                            .background(ThemeManager.shared.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }

                        Button(action: { showSavedAlert = true }) {
                            Text("Guardar")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [ThemeManager.shared.primaryPink, ThemeManager.shared.primaryPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Editar Recuerdo")
            .alert("Recuerdo guardado", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Tu recuerdo se ha guardado exitosamente.")
            }
        }
    }
}
