import SwiftUI
import FirebaseFirestore

public struct LoveGameView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [LoveCard] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var intimacyScore = 0
    @State private var cardsPlayed = 0
    @State private var offset: CGSize = .zero
    @State private var selectedCategory = "Todas"

    private let categories = ["Todas", "Romanticas", "Atrevidas", "Curiosas", "Acciones"]

    private let allCards: [LoveCard] = [
        LoveCard(question: "Cual fue tu primera impresion de mi?", category: "Romanticas"),
        LoveCard(question: "Que es lo que mas te gusta de nosotros?", category: "Romanticas"),
        LoveCard(question: "Describe nuestro momento mas feliz", category: "Romanticas"),
        LoveCard(question: "Que promesa te gustaria que hicieramos?", category: "Romanticas"),
        LoveCard(question: "Cual es tu cancion favorita de nuestra historia?", category: "Romanticas"),
        LoveCard(question: "Que es lo que mas valoras de nuestra relacion?", category: "Romanticas"),
        LoveCard(question: "Donde te gustaria estar conmigo ahora mismo?", category: "Romanticas"),
        LoveCard(question: "Que fue lo que te enamoro de mi?", category: "Romanticas"),

        LoveCard(question: "Besa el lugar que mas te guste de mi", category: "Atrevidas"),
        LoveCard(question: "Quitame una prenda con los dientes", category: "Atrevidas"),
        LoveCard(question: "Susurrame algo sexy al oido", category: "Atrevidas"),
        LoveCard(question: "Bailame una cancion sensual", category: "Atrevidas"),
        LoveCard(question: "Hazme un masaje donde mas lo necesite", category: "Atrevidas"),
        LoveCard(question: "Di algo que me haga sonrojar", category: "Atrevidas"),

        LoveCard(question: "En que piensas cuando no estamos juntos?", category: "Curiosas"),
        LoveCard(question: "Cual es tu recuerdo favorito de nuestra primera cita?", category: "Curiosas"),
        LoveCard(question: "Que es lo que nunca me has dicho y quisieras decirme?", category: "Curiosas"),
        LoveCard(question: "Que te gustaria aprender juntos?", category: "Curiosas"),
        LoveCard(question: "Cual es tu mayor miedo en la relacion?", category: "Curiosas"),
        LoveCard(question: "Que es lo que mas te sorprende de mi?", category: "Curiosas"),

        LoveCard(question: "Escribeme una nota de amor en la mano", category: "Acciones"),
        LoveCard(question: "Prepara tu bebida favorita para mi", category: "Acciones"),
        LoveCard(question: "Bailemos una cancion lenta ahora mismo", category: "Acciones"),
        LoveCard(question: "Hazme cosquillas por 15 segundos", category: "Acciones"),
        LoveCard(question: "Abrázame fuerte por 20 segundos", category: "Acciones"),
        LoveCard(question: "Dime 3 cosas que te gusten de mi", category: "Acciones"),
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    header
                    categoryPicker
                    Spacer()
                    cardStack
                    Spacer()
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Love Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .onAppear { filterCards() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Intimidad: \(intimacyScore)").appFont(size: 16, weight: .bold).foregroundColor(theme.primary)
                Text("Cartas: \(cardsPlayed)/\(cards.count)").appFont(size: 12).foregroundColor(theme.textSecondary)
            }
            Spacer()
            Text("\(currentIndex + 1)").appFont(size: 14, weight: .semibold).foregroundColor(theme.textSecondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        filterCards()
                    } label: {
                        Text(cat)
                            .appFont(size: 12, weight: .semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(cat == selectedCategory ? theme.primary : Color.clear)
                            .foregroundColor(cat == selectedCategory ? .white : theme.textPrimary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(cat == selectedCategory ? Color.clear : theme.primary.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }

    private var cardStack: some View {
        ZStack {
            if cards.isEmpty {
                Text("No hay cartas en esta categoria")
                    .appFont(size: 16)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if currentIndex < cards.count {
                let card = cards[currentIndex]
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.white)
                        .shadow(color: theme.primary.opacity(0.1), radius: 16)

                    VStack(spacing: 16) {
                        if isRevealed {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 36))
                                .foregroundColor(categoryColor(card.category))

                            Text(card.question)
                                .appFont(size: 20, weight: .semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal)

                            Text(card.category)
                                .appFont(size: 11, weight: .bold)
                                .foregroundColor(categoryColor(card.category))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(categoryColor(card.category).opacity(0.12))
                                .clipShape(Capsule())
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(theme.primary)
                                Text("Toca para revelar")
                                    .appFont(size: 16, weight: .semibold)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 320)
                .offset(x: offset.width, y: offset.height * 0.1)
                .rotationEffect(.degrees(Double(offset.width / 40)))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if isRevealed {
                                offset = gesture.translation
                            }
                        }
                        .onEnded { gesture in
                            if abs(gesture.translation.width) > 100 && isRevealed {
                                swipeCard()
                            }
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        isRevealed = true
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                if currentIndex > 0 {
                    withAnimation {
                        currentIndex -= 1
                        isRevealed = false
                    }
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == 0)
            .foregroundColor(theme.textPrimary)

            if isRevealed {
                Button {
                    intimacyScore += 1
                    withAnimation { swipeCard() }
                } label: {
                    Text("Completado")
                        .appFont(size: 14, weight: .semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.3))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.scale)
            }

            Button {
                if currentIndex < cards.count - 1 {
                    withAnimation {
                        currentIndex += 1
                        isRevealed = false
                    }
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(currentIndex >= cards.count - 1)
            .foregroundColor(theme.textPrimary)
        }
    }

    private func swipeCard() {
        if currentIndex < cards.count - 1 {
            withAnimation(.spring()) {
                currentIndex += 1
                isRevealed = false
                cardsPlayed += 1
            }
        }
    }

    private func filterCards() {
        if selectedCategory == "Todas" {
            cards = allCards.shuffled()
        } else {
            cards = allCards.filter { $0.category == selectedCategory }.shuffled()
        }
        currentIndex = 0
        isRevealed = false
        cardsPlayed = 0
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Romanticas": return .red
        case "Atrevidas": return Color.orange
        case "Curiosas": return Color.purple
        case "Acciones": return Color.green
        default: return theme.primary
        }
    }
}

private struct LoveCard {
    let question: String
    let category: String
}
