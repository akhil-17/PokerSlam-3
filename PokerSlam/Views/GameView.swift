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
        return text.components(separatedBy: " +").first?.uppercased()
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
                GradientText(
                    font: .messageText
                ) {
                    GlyphAnimatedText(text: "Game over, all poker hands played")
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            } else if let text = text {
                if let handName = handName, let scoreText = scoreText {
                    HStack(spacing: 4) {
                        GradientText(
                            font: .handFormationText,
                            tracking: 1
                        ) {
                            GlyphAnimatedText(text: handName)
                        }
                        GradientText(
                            font: .handFormationScoreText,
                            tracking: 1
                        ) {
                            let scoreDelay = Double(handName.count) * 0.03 + 0.1
                            GlyphAnimatedText(text: scoreText, animationDelay: scoreDelay)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .offset(y: isAnimating ? -20 : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isAnimating)
                } else {
                    GradientText(
                        font: .messageText
                    ) {
                        GlyphAnimatedText(text: text)
                    }
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
                            text: "Connect 2–5 cards to make poker hands",
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
                    
                    // Fixed height container for the card grid
                    ZStack {
                        CardGridView(viewModel: viewModel)
                            .onChange(of: viewModel.selectedCards.count) { oldValue, newValue in
                                if newValue > 0 {
                                    showIntroMessage = false
                                }
                            }
                    }
                    .frame(height: 550) // Fixed height for the card grid container
                    
                    // Fixed height container for bottom buttons
                    ZStack {
                        if viewModel.isGameOver {
                            PrimaryButton(
                                title: "Play again",
                                icon: "arrow.clockwise",
                                isAnimated: true,
                                isErrorState: false,
                                errorAnimationTimestamp: nil,
                                action: {
                                    Task { @MainActor in
                                        // Update high score if current score is higher
                                        if viewModel.score > gameState.currentScore {
                                            gameState.updateCurrentScore(viewModel.score)
                                        }
                                        viewModel.resetGame()
                                    }
                                }
                            )
                            .modifier(SuccessAnimationModifier(isSuccess: viewModel.isResetting))
                        } else {
                            // Use a custom view to handle the animation
                            PlayHandButtonContainer(
                                viewModel: viewModel,
                                gameState: gameState
                            )
                        }
                    }
                    .frame(height: 76) // Increased from 60 to 76 to accommodate taller buttons
                    
                    Spacer()
                }
            }
        }
    }
}

private struct CardGridView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var cardFrames: [UUID: CGRect] = [:]
    
    var body: some View {
        ZStack {
            // Connection lines layer
            ConnectionLinesLayer(
                viewModel: viewModel,
                cardFrames: cardFrames,
                isAnimated: !viewModel.isAnimating
            )
            
            // Card grid
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
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear.onAppear {
                                            // Calculate the offset for the card
                                            let offsetX = CGFloat(cardPosition.currentCol - cardPosition.targetCol) * 68
                                            let offsetY = CGFloat(cardPosition.currentRow - cardPosition.targetRow) * 102
                                            
                                            // Create a frame that includes the offset
                                            let frame = geometry.frame(in: .named("cardGrid"))
                                            let adjustedFrame = CGRect(
                                                x: frame.minX + offsetX,
                                                y: frame.minY + offsetY,
                                                width: frame.width,
                                                height: frame.height
                                            )
                                            
                                            // Store the adjusted frame for connection lines
                                            cardFrames[cardPosition.card.id] = adjustedFrame
                                        }
                                        .onChange(of: geometry.frame(in: .named("cardGrid"))) { oldFrame, newFrame in
                                            // Calculate the offset for the card
                                            let offsetX = CGFloat(cardPosition.currentCol - cardPosition.targetCol) * 68
                                            let offsetY = CGFloat(cardPosition.currentRow - cardPosition.targetRow) * 102
                                            
                                            // Create a frame that includes the offset
                                            let adjustedFrame = CGRect(
                                                x: newFrame.minX + offsetX,
                                                y: newFrame.minY + offsetY,
                                                width: newFrame.width,
                                                height: newFrame.height
                                            )
                                            
                                            // Update the card frame when it changes
                                            cardFrames[cardPosition.card.id] = adjustedFrame
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
        .coordinateSpace(name: "cardGrid")
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
                        // 2-card hands (lowest scoring)
                        SectionHeader(title: "2-Card Hands")
                        HandReferenceRow(
                            title: "Pair",
                            description: "Two cards of same rank (e.g., 2♠ 2♥)",
                            score: "15"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 3-card hands
                        SectionHeader(title: "3-Card Hands")
                        HandReferenceRow(
                            title: "Mini Straight",
                            description: "Three consecutive cards (e.g., 3♠ 4♥ 5♦)",
                            score: "25"
                        )
                        HandReferenceRow(
                            title: "Mini Flush",
                            description: "Three cards of same suit (e.g., A♥ K♥ Q♥)",
                            score: "30"
                        )
                        HandReferenceRow(
                            title: "Mini Straight Flush",
                            description: "Three consecutive cards of same suit (e.g., 8♣ 7♣ 6♣)",
                            score: "35"
                        )
                        HandReferenceRow(
                            title: "Mini Royal Flush",
                            description: "J, Q, K of same suit (e.g., J♣ Q♣ K♣)",
                            score: "40"
                        )
                        HandReferenceRow(
                            title: "Three of a Kind",
                            description: "Three cards of same rank (e.g., 4♠ 4♥ 4♦)",
                            score: "45"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 4-card hands
                        SectionHeader(title: "4-Card Hands")
                        HandReferenceRow(
                            title: "Two Pair",
                            description: "Two different pairs (e.g., J♠ J♥ Q♣ Q♦)",
                            score: "50"
                        )
                        HandReferenceRow(
                            title: "Nearly Straight",
                            description: "Four consecutive cards (e.g., 5♠ 4♥ 3♦ 2♣)",
                            score: "55"
                        )
                        HandReferenceRow(
                            title: "Nearly Flush",
                            description: "Four cards of same suit (e.g., A♠ K♠ Q♠ J♠)",
                            score: "60"
                        )
                        HandReferenceRow(
                            title: "Nearly Straight Flush",
                            description: "Four consecutive cards of same suit (e.g., 9♠ 8♠ 7♠ 6♠)",
                            score: "65"
                        )
                        HandReferenceRow(
                            title: "Nearly Royal Flush",
                            description: "J, Q, K, A of same suit (e.g., J♥ Q♥ K♥ A♥)",
                            score: "70"
                        )
                        HandReferenceRow(
                            title: "Four of a Kind",
                            description: "Four cards of same rank (e.g., 7♠ 7♥ 7♦ 7♣)",
                            score: "75"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 5-card hands (highest scoring)
                        SectionHeader(title: "5-Card Hands")
                        HandReferenceRow(
                            title: "Straight",
                            description: "Five consecutive cards (e.g., 9♠ 8♥ 7♦ 6♣ 5♠)",
                            score: "80"
                        )
                        HandReferenceRow(
                            title: "Flush",
                            description: "Five cards of same suit (e.g., A♦ 8♦ 6♦ 4♦ 2♦)",
                            score: "85"
                        )
                        HandReferenceRow(
                            title: "Full House",
                            description: "Three of a kind plus a pair (e.g., 3♣ 3♦ 3♥ 2♠ 2♣)",
                            score: "90"
                        )
                        HandReferenceRow(
                            title: "Straight Flush",
                            description: "Five consecutive cards of same suit (e.g., 9♠ 8♠ 7♠ 6♠ 5♠)",
                            score: "95"
                        )
                        HandReferenceRow(
                            title: "Royal Flush",
                            description: "A, K, Q, J, 10 of same suit (e.g., A♥ K♥ Q♥ J♥ 10♥)",
                            score: "100"
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

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12))
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.75))
            
            Rectangle()
                .fill(Color(hex: "#d4d4d4").opacity(0.75))
                .frame(height: 2)
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct HandReferenceRow: View {
    let title: String
    let description: String
    let score: String
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Split description and example
                if let exampleRange = description.range(of: "(e.g.,") {
                    let descriptionText = String(description[..<exampleRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let exampleText = String(description[exampleRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
                    
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(exampleText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Text(score)
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

/// A container view that handles the animation of the "Play hand" button
struct PlayHandButtonContainer: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var gameState: GameState
    @State private var showButton: Bool = false
    @State private var isErrorAnimating: Bool = false
    @State private var isSuccessAnimating: Bool = false
    
    var body: some View {
        ZStack {
            if showButton {
                PrimaryButton(
                    title: "Play hand",
                    icon: "play.fill",
                    isAnimated: true,
                    isErrorState: viewModel.isErrorState,
                    errorAnimationTimestamp: viewModel.errorAnimationTimestamp,
                    isSuccessState: viewModel.isSuccessState,
                    action: {
                        Task { @MainActor in
                            print("🔘 Button tapped, playing hand")
                            // Play the hand
                            viewModel.playHand()
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Color.clear
                    .frame(height: 76)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showButton)
        .onChange(of: viewModel.selectedCards.count) { oldValue, newValue in
            print("🔘 Selected cards count changed: \(oldValue) -> \(newValue), isSuccessState: \(viewModel.isSuccessState), isSuccessAnimating: \(isSuccessAnimating)")
            
            // Only update button visibility based on selection count if we're not in the middle of a success animation
            if !isSuccessAnimating {
                if newValue >= 2 {
                    print("🔘 Showing button due to selection count: \(newValue)")
                    showButton = true
                } else {
                    showButton = false
                }
            } else {
                print("🔘 Ignoring selection count change during success animation")
            }
        }
        .onChange(of: viewModel.isSuccessState) { oldValue, newValue in
            print("🔘 Success state changed: \(oldValue) -> \(newValue)")
            
            // When success state becomes true, hide the button and set animation flag
            if newValue == true {
                print("🔘 Hiding button due to success state")
                showButton = false
                isSuccessAnimating = true
            }
            // When success state becomes false, wait a moment before checking selection count
            else if oldValue == true && newValue == false {
                print("🔘 Success animation completed, waiting before checking selection count")
                
                // Add a small delay before checking selection count to avoid race conditions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔘 Delay completed, checking selection count: \(viewModel.selectedCards.count)")
                    isSuccessAnimating = false
                    
                    // Check if we should show the button based on current selection
                    if viewModel.selectedCards.count >= 2 {
                        print("🔘 Showing button after success animation")
                        showButton = true
                    }
                }
            }
        }
        .onChange(of: viewModel.errorAnimationTimestamp) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                // Start error animation
                isErrorAnimating = true
                
                // Reset after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isErrorAnimating = false
                }
            }
        }
        .onAppear {
            // Set initial state
            print("🔘 PlayHandButtonContainer appeared, selection count: \(viewModel.selectedCards.count)")
            showButton = viewModel.selectedCards.count >= 2
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
} 
