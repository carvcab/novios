import SwiftUI

public struct WishlistView: View {
    @State private var goals: [GoalModel] = [
        GoalModel(title: "Ver la aurora boreal juntos 🌌", isCompleted: false, createdBy: "user_me"),
        GoalModel(title: "Aprender a bailar salsa 💃🕺", isCompleted: true, createdBy: "partner_123"),
        GoalModel(title: "Tener nuestra primera casa 🏡", isCompleted: false, createdBy: "user_me")
    ]
    @State private var newGoalText = ""
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    GlassCard {
                        HStack {
                            TextField("Agregar nueva meta de pareja...", text: $newGoalText)
                                .foregroundColor(.primary)
                            
                            Button {
                                if !newGoalText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    goals.append(GoalModel(title: newGoalText, createdBy: "user_me"))
                                    newGoalText = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(goals.indices, id: \.self) { idx in
                                GlassCard {
                                    HStack(spacing: 14) {
                                        Button {
                                            goals[idx].isCompleted.toggle()
                                        } label: {
                                            Image(systemName: goals[idx].isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(goals[idx].isCompleted ? .green : .gray)
                                        }
                                        
                                        Text(goals[idx].title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(goals[idx].isCompleted ? Color.white.opacity(0.5) : .white)
                                            .strikethrough(goals[idx].isCompleted)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Lista de Deseos & Metas")
        }
    }
}
