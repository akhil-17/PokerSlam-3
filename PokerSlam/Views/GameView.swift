import SwiftUI

struct GameView: View {
    // MARK: - State Enumeration
    private enum ViewState {
        case mainMenu
        case gamePlay
    }

    // MARK: - Properties
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss // Keep dismiss for potential future use or app exit
    
    @State private var currentViewState: ViewState = .mainMenu
    @State private var showingHandReference = false
    
    // Score animation properties (moved from GameContainer)
    @State private var displayedScore: Int = 0
    @State private var targetScore: Int = 0
    @State private var scoreUpdateTimer: Timer?
    @State private var isScoreAnimating: Bool = false
    
    // Intro message state (moved from GameContainer)
    @State private var showIntroMessage = true

    // MARK: - Body
    var body: some View {
        ZStack {
            // Single instance of the background
            MeshGradientBackground()

            // Conditional content based on view state
            if currentViewState == .mainMenu {
                mainMenuContent
                    .transition(.opacity) // Add transition for fade
            } else {
                gamePlayContent
                    .transition(.opacity) // Add transition for fade
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentViewState) // Animate state changes
        .sheet(isPresented: $showingHandReference) {
            HandReferenceView() // Hand reference can be shown in gamePlay state
        }
        .onAppear {
            // Initial setup if needed, though viewModel handles its own reset
            setupScoreDisplay()
        }
        .onChange(of: viewModel.score) { _, newScore in
            handleScoreUpdate(newScore)
        }
        .onDisappear {
            cleanupTimersAndState()
        }
    }

    // MARK: - View Components

    /// Content view for the Main Menu state
    private var mainMenuContent: some View {
        ZStack {
            // VStack to center the title
            VStack {
                Spacer()
                GradientText(font: .appTitle) {
                    Text("Poker Slam")
                }
                Spacer()
            }
            .padding() // Add padding if needed around the title
            
            // VStack to position "tap to start" at the bottom
            VStack {
                Spacer() // Pushes the text down
                Text("tap to start")
                    .modifier(IntroMessageTextStyle()) // Apply the custom modifier
                    .padding(.bottom, 60) // Adjust padding from bottom as needed
            }
        }
        .contentShape(Rectangle()) // Make the entire area tappable
        .onTapGesture {
            // Reset game state when starting
            Task { @MainActor in
                viewModel.resetGame() // Removed isNewGame argument
                // Reset score display immediately for the new game
                displayedScore = 0
                targetScore = 0
                isScoreAnimating = false
                showIntroMessage = true // Show intro message again
                // Transition to game play
                currentViewState = .gamePlay
            }
        }
    }

    /// Content view for the Game Play state
    private var gamePlayContent: some View {
        // This VStack structure mirrors the old GameContainer's body
        VStack(spacing: 0) {
            // Custom Header
            gameHeader

            // Main Content Area
            gameMainContent
        }
    }

    /// Header section for the game play view
    private var gameHeader: some View {
        HStack {
            CircularIconButton(iconName: "xmark") {
                Task { @MainActor in
                    // Update high score if current score is higher before returning to menu
                    if viewModel.score > gameState.currentScore {
                        gameState.updateCurrentScore(viewModel.score)
                    }
                    // Reset game and return to main menu state
                    viewModel.resetGame() // Removed isNewGame argument
                    // Reset score display when returning to menu
                    displayedScore = 0
                    targetScore = 0
                    isScoreAnimating = false
                    currentViewState = .mainMenu
                }
            }
            
            Spacer()
            
            scoreDisplay
            
            Spacer()
            
            CircularIconButton(iconName: "questionmark") {
                showingHandReference = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    /// Score display component for the header
    private var scoreDisplay: some View {
        VStack(spacing: -4) {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: 40)
                    .mask(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white.opacity(1.0), Color.white.opacity(0.0)]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .cornerRadius(12)
                    .padding(-8)

                VStack(spacing: -4) {
                    // Score Label (with gradient animation)
                    ZStack {
                        Text(viewModel.score > gameState.currentScore ? "New high score" : "Score")
                            .textCase(.uppercase)
                            .tracking(1)
                            .font(.scoreLabel)
                            .foregroundColor(Color(hex: "#999999"))
                            .blendMode(.colorDodge)
                            .opacity(isScoreAnimating ? 0 : 1)
                        
                        Text(viewModel.score > gameState.currentScore ? "New high score" : "Score")
                            .textCase(.uppercase)
                            .tracking(1)
                            .font(.scoreLabel)
                            .foregroundStyle(.clear)
                            .background { MeshGradientBackground2() }
                            .mask {
                                Text(viewModel.score > gameState.currentScore ? "New high score" : "Score")
                                    .textCase(.uppercase)
                                    .tracking(1)
                                    .font(.scoreLabel)
                            }
                            .opacity(isScoreAnimating ? 1 : 0)
                    }
                    
                    // Score Value (with gradient animation)
                    ZStack {
                        Text("\(displayedScore)")
                            .font(.scoreValue)
                            .foregroundColor(Color(hex: "#999999"))
                            .blendMode(.colorDodge)
                            .opacity(isScoreAnimating ? 0 : 1)
                        
                        Text("\(displayedScore)")
                            .font(.scoreValue)
                            .foregroundStyle(.clear)
                            .background { MeshGradientBackground2() }
                            .mask {
                                Text("\(displayedScore)")
                                    .font(.scoreValue)
                            }
                            .opacity(isScoreAnimating ? 1 : 0)
                    }
                }
            }
        }
    }

    /// Main content section for the game play view (Hand Text, Grid, Buttons)
    private var gameMainContent: some View {
        VStack(spacing: 0) {
            // Hand Formation Text Display
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
            
            // Card Grid Area
            ZStack {
                CardGridView(viewModel: viewModel)
                    .onChange(of: viewModel.selectedCards.count) { oldValue, newValue in
                        if newValue > 0 {
                            showIntroMessage = false
                        }
                    }
            }
            .frame(height: 550)
            
            // Bottom Button Area
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
                                if viewModel.score > gameState.currentScore {
                                    gameState.updateCurrentScore(viewModel.score)
                                }
                                viewModel.resetGame() // Removed isNewGame argument
                                // Reset score display for the new game
                                displayedScore = 0
                                targetScore = 0
                                isScoreAnimating = false
                                showIntroMessage = true
                            }
                        }
                    )
                    .modifier(SuccessAnimationModifier(isSuccess: viewModel.isResetting))
                } else {
                    PlayHandButtonContainer(
                        viewModel: viewModel,
                        gameState: gameState
                    )
                }
            }
            .frame(height: 76)
            
            Spacer() // Pushes content up if needed
        }
    }

    // MARK: - Helper Methods

    private func setupScoreDisplay() {
        displayedScore = viewModel.score
        targetScore = viewModel.score
    }

    private func handleScoreUpdate(_ newScore: Int) {
        // Handle instant reset to 0 (e.g., when returning to menu or starting new game)
        if newScore == 0 && displayedScore != 0 { // Prevent animation if already 0
            scoreUpdateTimer?.invalidate()
            scoreUpdateTimer = nil
            isScoreAnimating = false
            displayedScore = 0
            targetScore = 0
            return
        }
        
        // Ensure target score is updated
        targetScore = newScore

        // Cancel existing timer if score changes during animation
        scoreUpdateTimer?.invalidate()

        let difference = newScore - displayedScore
        guard difference != 0 else { return }

        // Start gradient animation
        withAnimation(.easeInOut(duration: 1.0)) {
            isScoreAnimating = true
        }

        // Configure tally animation parameters
        let steps = abs(difference)
        let totalDuration = Double(steps) * 0.01
        let clampedDuration = max(0.05, totalDuration)
        let timeInterval = max(0.005, clampedDuration / Double(steps))
        let increment = difference > 0 ? 1 : -1

        // Start the timer
        scoreUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
            displayedScore += increment

            // Stop condition
            if (increment > 0 && displayedScore >= targetScore) || (increment < 0 && displayedScore <= targetScore) {
                displayedScore = targetScore
                timer.invalidate()
                scoreUpdateTimer = nil
                // Fade out gradient animation
                withAnimation(.easeInOut(duration: 1.0)) {
                    isScoreAnimating = false
                }
            }
        }

        // Ensure timer runs during UI interactions
        if let timer = scoreUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func cleanupTimersAndState() {
        // Update high score if necessary when the view disappears completely
        if viewModel.score > gameState.currentScore {
            gameState.updateCurrentScore(viewModel.score)
        }
        // Clean up timer
        scoreUpdateTimer?.invalidate()
        scoreUpdateTimer = nil
        isScoreAnimating = false
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
                                            let frame = geometry.frame(in: .named("cardGrid"))
                                            cardFrames[cardPosition.card.id] = frame
                                        }
                                        .onChange(of: geometry.frame(in: .named("cardGrid"))) { oldFrame, newFrame in
                                            cardFrames[cardPosition.card.id] = newFrame
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
            if newValue == true {
                print("🔘 Hiding button due to success state")
                showButton = false
                isSuccessAnimating = true
            } else if oldValue == true && newValue == false {
                print("🔘 Success animation completed, waiting before checking selection count")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔘 Delay completed, checking selection count: \(viewModel.selectedCards.count)")
                    isSuccessAnimating = false
                    if viewModel.selectedCards.count >= 2 {
                        print("🔘 Showing button after success animation")
                        showButton = true
                    }
                }
            }
        }
        .onChange(of: viewModel.errorAnimationTimestamp) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                isErrorAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isErrorAnimating = false
                }
            }
        }
        .onAppear {
            print("🔘 PlayHandButtonContainer appeared, selection count: \(viewModel.selectedCards.count)")
            showButton = viewModel.selectedCards.count >= 2
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
} 
