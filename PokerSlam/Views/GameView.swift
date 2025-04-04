import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showingHandReference = false
    
    var body: some View {
        GameContainer(
            viewModel: viewModel,
            gameState: gameState,
            showingHandReference: $showingHandReference,
            dismiss: dismiss
        )
        .sheet(isPresented: $showingHandReference) {
            HandReferenceView()
        }
        .onDisappear {
            // Update high score if current score is higher
            if viewModel.score > gameState.currentScore {
                gameState.updateCurrentScore(viewModel.score)
            }
        }
    }
}

private struct HandFormationText: View {
    let text: String?
    let isAnimating: Bool
    let isGameOver: Bool
    
    private var handName: String? {
        guard let text = text else { return nil }
        return text.components(separatedBy: " +").first
    }
    
    private var scoreText: String? {
        guard let text = text else { return nil }
        let components = text.components(separatedBy: " +")
        guard components.count > 1 else { return nil }
        return "+" + components[1]
    }
    
    var body: some View {
        ZStack {
            if isGameOver {
                Text("Game over, no more poker hands can be formed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if let text = text {
                if let handName = handName, let scoreText = scoreText {
                    HStack(spacing: 4) {
                        Text(handName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(scoreText)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .offset(y: isAnimating ? -20 : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isAnimating)
                } else {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .offset(y: isAnimating ? -20 : 0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(.easeOut(duration: 0.3), value: isAnimating)
                }
            }
        }
        .frame(minHeight: 40)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct GameContainer: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var gameState: GameState
    @Binding var showingHandReference: Bool
    @State private var showIntroMessage = true
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { 
                        Task { @MainActor in
                            // Update high score if current score is higher
                            if viewModel.score > gameState.currentScore {
                                gameState.updateCurrentScore(viewModel.score)
                            }
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(viewModel.score > gameState.currentScore ? "New high score!" : "Score")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(viewModel.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingHandReference = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Main Content
                VStack(spacing: 0) {
                    if showIntroMessage && viewModel.currentHandText == nil && !viewModel.isGameOver {
                        HandFormationText(
                            text: "Create poker hands with adjacent cards",
                            isAnimating: false,
                            isGameOver: false
                        )
                    } else {
                        HandFormationText(
                            text: viewModel.currentHandText,
                            isAnimating: viewModel.isAnimatingHandText,
                            isGameOver: viewModel.isGameOver
                        )
                    }
                    
                    CardGridView(viewModel: viewModel)
                        .onChange(of: viewModel.selectedCards.count) { oldValue, newValue in
                            if newValue > 0 {
                                showIntroMessage = false
                            }
                        }
                    
                    // Fixed height container for bottom buttons
                    ZStack {
                        if viewModel.isGameOver {
                            Button(action: {
                                Task { @MainActor in
                                    // Update high score if current score is higher
                                    if viewModel.score > gameState.currentScore {
                                        gameState.updateCurrentScore(viewModel.score)
                                    }
                                    viewModel.resetGame()
                                }
                            }) {
                                Text("Play Again")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                            }
                            .padding()
                        } else if viewModel.selectedCards.count >= 2 {
                            Button(action: {
                                Task { @MainActor in
                                    viewModel.playHand()
                                }
                            }) {
                                Text("Play Hand")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                            }
                            .padding()
                        } else {
                            Color.clear
                                .frame(height: 60) // Approximate height of the buttons with padding
                        }
                    }
                    .frame(height: 60) // Fixed height to prevent layout shifts
                    
                    Spacer()
                }
            }
        }
    }
}

private struct CardGridView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { row in
                LazyHStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { col in
                        if let cardPosition = viewModel.cardPositions.first(where: { $0.currentRow == row && $0.currentCol == col }) {
                            CardView(
                                card: cardPosition.card,
                                isSelected: viewModel.selectedCards.contains(cardPosition.card),
                                isEligible: viewModel.eligibleCards.contains(cardPosition.card),
                                isInteractive: viewModel.areCardsInteractive,
                                onTap: { 
                                    Task { @MainActor in
                                        viewModel.selectCard(cardPosition.card)
                                    }
                                }
                            )
                            .offset(
                                x: CGFloat(cardPosition.currentCol - cardPosition.targetCol) * 68,
                                y: CGFloat(cardPosition.currentRow - cardPosition.targetRow) * 102
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.targetRow)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.targetCol)
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            // Empty space
                            Color.clear
                                .frame(width: 64, height: 94)
                        }
                    }
                }
                .frame(height: 94)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            if !viewModel.selectedCards.isEmpty && viewModel.areCardsInteractive {
                Task { @MainActor in
                    viewModel.unselectAllCards()
                }
            }
        }
    }
}

struct HandReferenceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
            
            VStack(spacing: 20) {
                Text("Poker Hands")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // 5-card hands
                        HandReferenceRow(
                            title: "Royal Flush",
                            description: "A, K, Q, J, 10 of same suit (e.g., A♥ K♥ Q♥ J♥ 10♥)",
                            score: "100"
                        )
                        HandReferenceRow(
                            title: "Straight Flush",
                            description: "Five consecutive cards of same suit (e.g., 9♠ 8♠ 7♠ 6♠ 5♠)",
                            score: "95"
                        )
                        HandReferenceRow(
                            title: "Full House",
                            description: "Three of a kind plus a pair (e.g., 3♣ 3♦ 3♥ 2♠ 2♣)",
                            score: "90"
                        )
                        HandReferenceRow(
                            title: "Flush",
                            description: "Five cards of same suit (e.g., A♦ 8♦ 6♦ 4♦ 2♦)",
                            score: "85"
                        )
                        HandReferenceRow(
                            title: "Straight",
                            description: "Five consecutive cards (e.g., 9♠ 8♥ 7♦ 6♣ 5♠)",
                            score: "80"
                        )
                        
                        // 4-card hands
                        HandReferenceRow(
                            title: "Four of a Kind",
                            description: "Four cards of same rank (e.g., 7♠ 7♥ 7♦ 7♣)",
                            score: "75"
                        )
                        HandReferenceRow(
                            title: "Nearly Royal Flush",
                            description: "J, Q, K, A of same suit (e.g., J♥ Q♥ K♥ A♥)",
                            score: "70"
                        )
                        HandReferenceRow(
                            title: "Nearly Flush",
                            description: "Four cards of same suit (e.g., A♠ K♠ Q♠ J♠)",
                            score: "65"
                        )
                        HandReferenceRow(
                            title: "Nearly Straight",
                            description: "Four consecutive cards (e.g., 5♠ 4♥ 3♦ 2♣)",
                            score: "60"
                        )
                        HandReferenceRow(
                            title: "Two Pair",
                            description: "Two different pairs (e.g., J♠ J♥ Q♣ Q♦)",
                            score: "55"
                        )
                        
                        // 3-card hands
                        HandReferenceRow(
                            title: "Three of a Kind",
                            description: "Three cards of same rank (e.g., 4♠ 4♥ 4♦)",
                            score: "50"
                        )
                        HandReferenceRow(
                            title: "Mini Royal Flush",
                            description: "J, Q, K of same suit (e.g., J♣ Q♣ K♣)",
                            score: "45"
                        )
                        HandReferenceRow(
                            title: "Mini Flush",
                            description: "Three cards of same suit (e.g., A♥ K♥ Q♥)",
                            score: "40"
                        )
                        HandReferenceRow(
                            title: "Mini Straight",
                            description: "Three consecutive cards (e.g., 3♠ 4♥ 5♦)",
                            score: "35"
                        )
                        
                        // 2-card hands
                        HandReferenceRow(
                            title: "One Pair",
                            description: "Two cards of same rank (e.g., 2♠ 2♥)",
                            score: "15"
                        )
                    }
                    .padding()
                }
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct HandReferenceRow: View {
    let title: String
    let description: String
    let score: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(score)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
} 