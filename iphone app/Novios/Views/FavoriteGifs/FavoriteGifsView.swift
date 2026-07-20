import SwiftUI

public struct FavoriteGifsView: View {
    @State private var searchText = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 0) {
                    // Search bar
                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.primary.opacity(0.4))
                            TextField("Buscar GIFs...", text: $searchText)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.primary.opacity(0.4))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // GIF Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(0..<30, id: \.self) { index in
                                GlassCard {
                                    VStack(spacing: 6) {
                                        Text(gifEmojis[index % gifEmojis.count])
                                            .font(.system(size: 36))
                                        Text("GIF \(index + 1)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.primary.opacity(0.4))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .padding(8)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("GIFs")
        }
    }

    private let categories = ["💕Románticos", "😂Divertidos", "😘Cariñosos", "🎉Celebración", "🥰Amor"]
    private let gifEmojis = ["😊", "😂", "❤️", "🥰", "😘", "💕", "🎉", "🤗", "😍", "💪", "🎊", "💖", "✨", "🔥", "💋"]
}
