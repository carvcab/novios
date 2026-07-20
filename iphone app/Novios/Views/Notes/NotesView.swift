import SwiftUI

public struct NotesView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "note.text")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Notas Compartidas")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("Tus notas compartidas aparecerán aquí")
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .navigationTitle("Notas")
    }
}
