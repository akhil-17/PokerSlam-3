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
    
    @State private var currentViewState: ViewState = .mainMenu
    @State private var showingHandReference = false
    
    // State for title wave animation
    @State private var isTitleWaveAnimating = false
    @State private var titleWaveLoopTask: Task<Void, Never>? = nil

    // MARK: - Body
    var body: some View {
        ZStack {
            // Single instance of the background
            MeshGradientBackground()
                .ignoresSafeArea()

            // Conditional content based on view state
            if currentViewState == .mainMenu {
                mainMenuContent
                    .transition(.opacity) // Add transition for fade
            } else {
                gamePlayContent
                    .ignoresSafeArea() // Allow game content (and overlay) to extend
                    .transition(.opacity) // Add transition for fade
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentViewState) // Animate state changes
        .onChange(of: currentViewState) { oldValue, newValue in
            if newValue == .mainMenu {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                      // Check if we are still in the main menu state after delay
                      if currentViewState == .mainMenu {
                          startTitleWaveLoop()
                      }
                 }
            } else if oldValue == .mainMenu {
                 stopTitleWaveLoop()
            }
        }
        .onAppear {
            // Initial setup if needed, though viewModel handles its own reset
            // Start title wave animation if initial state is mainMenu
            if currentViewState == .mainMenu {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                     // Re-check state in case it changed very quickly
                     if currentViewState == .mainMenu {
                         startTitleWaveLoop()
                     }
                }
            }
        }
    }

    // MARK: - View Components

    /// Content view for the Main Menu state
    private var mainMenuContent: some View {
        ZStack {
            // Add the falling ranks animation behind everything
            FallingRanksView()
                .blendMode(.multiply)
            
            // VStack to center the title
            VStack {
                Spacer()
                GradientText(font: .gameTitle, applyShadow: false) {
                    // Pass wave state directly to GlyphAnimatedText
                    GlyphAnimatedText(text: "Poker Slam", isWaveAnimating: isTitleWaveAnimating)
                }
                .blendMode(.colorDodge)
                .opacity(0.5)
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
            // Stop title animation when leaving menu
            stopTitleWaveLoop()
            // Reset game state when starting
            Task { @MainActor in
                viewModel.resetGame() // Removed isNewGame argument
                // Transition to game play
                currentViewState = .gamePlay
            }
        }
    }

    /// Content view for the Game Play state
    private var gamePlayContent: some View {
        // Wrap in ZStack to allow overlay
        ZStack {
            // This VStack structure mirrors the old GameContainer's body
            VStack(spacing: 0) {
                // Custom Header
                gameHeader

                // Main Content Area
                gameMainContent
            }
            .padding(.top)
            .padding(.bottom)
            .disabled(showingHandReference) // Disable game interaction when reference is shown

            // Overlay the HandReferenceView
            if showingHandReference {
                HandReferenceView(dismissAction: { showingHandReference = false })
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Expand to full size
                    .ignoresSafeArea() // Make sure overlay content ignores safe area too
                    .background(.ultraThinMaterial)
                    .cornerRadius(20) // Apply corner radius to the background layer
                    .shadow(radius: 10) // Optional: Add a subtle shadow
                    .transition(.opacity) // <<< Change transition to opacity only
                    .zIndex(1) // Ensure it's above other content
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingHandReference) // <<< Add animation for overlay fade
        .animation(.easeInOut(duration: 0.5), value: currentViewState) // Keep animation for view state change
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
        .padding(.top, 20)
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
                        // Determine the text content
                        let scoreLabelText = viewModel.score > gameState.currentScore ? "New high score" : "Score"
                        
                        // Single Text view for the label
                        Text(scoreLabelText)
                            .textCase(.uppercase)
                            .tracking(1)
                            .font(.scoreLabel)
                            .foregroundStyle(Color(hex: "#999999")) // Keep base color or make dynamic?
                        
                        // Optional: Apply gradient overlay if needed, simplified
                        // Text(scoreLabelText)
                        //     .textCase(.uppercase)
                        //     .tracking(1)
                        //     .font(.scoreLabel)
                        //     .foregroundStyle(.clear)
                        //     .background { MeshGradientBackground2() }
                        //     .mask {
                        //         Text(scoreLabelText)
                        //             .textCase(.uppercase)
                        //             .tracking(1)
                        //             .font(.scoreLabel)
                        //     }
                    }
                    .id("scoreLabel_" + (viewModel.score > gameState.currentScore ? "high" : "normal")) // Use ID for transition
                    .transition(.opacity.animation(.easeInOut(duration: 0.2))) // Apply crossfade transition
                    
                    // Score Value (with gradient animation)
                    ZStack {
                        Text("\(viewModel.displayedScore)")
                            .font(.scoreValue)
                            .foregroundColor(Color(hex: "#999999"))
                            .blendMode(.colorDodge)
                            .opacity(viewModel.isScoreAnimating ? 0 : 1)

                        Text("\(viewModel.displayedScore)")
                            .font(.scoreValue)
                            .foregroundStyle(.clear)
                            .background { MeshGradientBackground2() }
                            .mask {
                                Text("\(viewModel.displayedScore)")
                                    .font(.scoreValue)
                            }
                            .opacity(viewModel.isScoreAnimating ? 1 : 0)
                    }
                }
            }
        }
    }

    /// Main content section for the game play view (Hand Text, Grid, Buttons)
    private var gameMainContent: some View {
        VStack(spacing: 0) {
            // Hand Formation Text Display
            if !viewModel.hasUserInteractedThisGame && viewModel.currentHandText == nil && !viewModel.isGameOver {
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

    // MARK: - Title Wave Animation Loop Control
    
    private func startTitleWaveLoop() {
        guard titleWaveLoopTask == nil else { return }
        isTitleWaveAnimating = true
        
        titleWaveLoopTask = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch is CancellationError {
                    break
                } catch {
                    break
                }
            }
            isTitleWaveAnimating = false
            titleWaveLoopTask = nil
        }
    }
    
    private func stopTitleWaveLoop() {
        if let task = titleWaveLoopTask {
            task.cancel()
            titleWaveLoopTask = nil
        }
        isTitleWaveAnimating = false
    }
}

private struct HandFormationText: View {
    let text: String?
    let isAnimating: Bool
    let isGameOver: Bool
    
    // State for wave animation
    @State private var glyphAnimationComplete = false
    @State private var isWaveAnimating = false
    @State private var waveLoopTask: Task<Void, Never>? = nil
    
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
                            GlyphAnimatedText(text: handName, isWaveAnimating: isWaveAnimating)
                        }
                        GradientText(
                            font: .handFormationScoreText,
                            tracking: 1
                        ) {
                            let scoreDelay = Double(handName.count) * 0.03 + 0.1
                            GlyphAnimatedText(text: scoreText, animationDelay: scoreDelay, isWaveAnimating: isWaveAnimating) { 
                                if self.text == text {
                                    glyphAnimationComplete = true
                                }
                            }
                        }
                    }
                    .id(text)
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
        .frame(minHeight: 40, alignment: .top)
        .onChange(of: text) { _, newText in
            // Reset wave animation state whenever text changes
            glyphAnimationComplete = false // Mark glyph animation as incomplete
            // StopWaveLoop is implicitly called by onChange(of: glyphAnimationComplete)
        }
        .onChange(of: glyphAnimationComplete) { _, newValue in
            // Start/stop wave loop when glyph animation completes/resets
            if newValue {
                startWaveLoop()
            } else {
                stopWaveLoop()
            }
        }
        .onDisappear {
             // Ensure loop stops if view disappears
             stopWaveLoop()
        }
    }

    // MARK: - Wave Animation Loop Control
    
    private func startWaveLoop() {
        // Prevent multiple loops
        guard waveLoopTask == nil, glyphAnimationComplete else { return }
        
        isWaveAnimating = true 
        
        waveLoopTask = Task { @MainActor in
            while glyphAnimationComplete && !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch is CancellationError {
                    break
                } catch {
                    break
                }
            }
            isWaveAnimating = false
            waveLoopTask = nil
        }
    }
    
    private func stopWaveLoop() {
        if let task = waveLoopTask {
            task.cancel()
            waveLoopTask = nil
        }
        // Explicitly set animating to false
        isWaveAnimating = false
        // Also ensure glyph animation is marked as incomplete if we stop the loop early
        // This prevents restart if text hasn't changed but disappear/reappear happens.
        if glyphAnimationComplete { 
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
                                    isEligible: viewModel.eligibleCards.contains(cardPosition.card) && !viewModel.isGameOver,
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
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.currentRow)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.currentCol)
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
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // New header
            handReferenceHeader
            
            // Content VStack with padding
            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        Text("Create sets of 2-5 poker hands and score! Adjacent cards can be selected horizontally, vertically, or diagonally.")
                            .font(.handReferenceInstruction)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 5)

                        // 2-card hands (lowest scoring)
                        SectionHeader(title: "2-Card Hands")
                        HandReferenceRow(
                            title: "Pair",
                            description: "Two cards with matching ranks (e.g., 5♠ 5♥)",
                            score: "15"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 3-card hands
                        SectionHeader(title: "3-Card Hands")
                        HandReferenceRow(
                            title: "Mini Straight",
                            description: "Three cards in sequence (e.g., 3♠ 4♥ 5♦)",
                            score: "25"
                        )
                        HandReferenceRow(
                            title: "Mini Flush",
                            description: "Three cards with matching suits (e.g., 3♥ K♥ 9♥)",
                            score: "30"
                        )
                        HandReferenceRow(
                            title: "Mini Straight Flush",
                            description: "Three cards in sequence with matching suits (e.g., A♣ 2♣ 3♣)",
                            score: "35"
                        )
                        HandReferenceRow(
                            title: "Mini Royal Flush",
                            description: "J, Q, K with matching suits (e.g., J♦ Q♦ K♦)",
                            score: "40"
                        )
                        HandReferenceRow(
                            title: "Three of a Kind",
                            description: "Three cards with matching ranks (e.g., 4♠ 4♥ 4♦)",
                            score: "45"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 4-card hands
                        SectionHeader(title: "4-Card Hands")
                        HandReferenceRow(
                            title: "Two Pair",
                            description: "Two pairs, each with matching ranks (e.g., 6♠ 6♥ K♣ K♦)",
                            score: "50"
                        )
                        HandReferenceRow(
                            title: "Nearly Straight",
                            description: "Four cards in sequence (e.g., 6♠ 7♥ 8♦ 9♣)",
                            score: "55"
                        )
                        HandReferenceRow(
                            title: "Nearly Flush",
                            description: "Four cards with matching suits (e.g., 5♠ A♠ 9♠ 3♠)",
                            score: "60"
                        )
                        HandReferenceRow(
                            title: "Nearly Straight Flush",
                            description: "Four cards in sequence with matching suits (e.g., K♠ A♠ 2♠ 3♠)",
                            score: "65"
                        )
                        HandReferenceRow(
                            title: "Nearly Royal Flush",
                            description: "J, Q, K, A with matching suits (e.g., J♣ Q♣ K♣ A♣)",
                            score: "70"
                        )
                        HandReferenceRow(
                            title: "Four of a Kind",
                            description: "Four cards with matching ranks (e.g., 7♠ 7♥ 7♦ 7♣)",
                            score: "75"
                        )
                        
                        // Add spacing between groups
                        Spacer()
                            .frame(height: 16)
                        
                        // 5-card hands (highest scoring)
                        SectionHeader(title: "5-Card Hands")
                        HandReferenceRow(
                            title: "Straight",
                            description: "Five cards in sequence (e.g., 7♠ 8♥ 9♦ 10♣ J♠)",
                            score: "80"
                        )
                        HandReferenceRow(
                            title: "Flush",
                            description: "Five cards with matching suits (e.g., 4♦ 8♦ Q♦ 5♦ 2♦)",
                            score: "85"
                        )
                        HandReferenceRow(
                            title: "Full House",
                            description: "Three cards with matching ranks, and two other cards with matching ranks (e.g., 3♣ 3♦ 3♥ 2♠ 2♣)",
                            score: "90"
                        )
                        HandReferenceRow(
                            title: "Straight Flush",
                            description: "Five cards in sequence with matching suits (e.g., 5♠ 6♠ 7♠ 8♠ 9♠)",
                            score: "95"
                        )
                        HandReferenceRow(
                            title: "Royal Flush",
                            description: "10, J , Q, K, A with matching suits (e.g., 10♥ J♥ Q♥ K♥ A♥)",
                            score: "100"
                        )
                    }
                    .padding()
                    .padding(.bottom, 48)
                }
            }
            .padding(.top, 4)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 40)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0), location: 0.0),
                                .init(color: Color.white.opacity(1), location: 0.75),
                                .init(color: Color.white.opacity(1), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .padding(.top, 4)
    }

    // New header view component
    private var handReferenceHeader: some View {
        HStack {
            Spacer() // Push button to the right
            
            CircularIconButton(iconName: "xmark") {
                dismissAction() // Call the dismiss action
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 68)
        .padding(.bottom, 10)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.handReferenceSectionHeader)
                .foregroundColor(.white.opacity(0.75))
            
            Rectangle()
                .fill(Color(hex: "#d4d4d4").opacity(0.75))
                .frame(height: 2)
            
            Text("Score".uppercased())
                .font(.handReferenceSectionHeader)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct HandReferenceRow: View {
    let title: String
    let description: String
    let score: String
    
    // Computed property to parse example cards
    private var exampleCards: [Card] {
        parseExampleCards(from: description)
    }
    
    var body: some View {
        HStack(alignment: .top) { // Align items to the top
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.handReferenceRowTitle)
                    .foregroundColor(.white)
                
                // Display description text
                descriptionTextView
                
                // Display mini cards if available
                if !exampleCards.isEmpty {
                    miniCardPreview
                        .padding(.top, 8) // Add some space above the cards
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text(score)
                .font(.handReferenceRowScore)
                .foregroundColor(.white)
                .padding(.leading, 8) // Add padding to prevent overlap with text/cards
        }
    }
    
    // Subview for the description text handling
    @ViewBuilder
    private var descriptionTextView: some View {
        if let exampleRange = description.range(of: "(e.g.,") {
            let descriptionText = String(description[..<exampleRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            
            Text(descriptionText)
                .font(.handReferenceRowDescription)
                .foregroundColor(.white.opacity(0.8))

        } else {
            Text(description)
                .font(.handReferenceRowDescription)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // Subview for the mini card preview
    private var miniCardPreview: some View {
        HStack(spacing: 4) { // Spacing between mini cards
            ForEach(exampleCards) { card in
                CardView(
                    card: card,
                    isSelected: false, // Mini cards are never selected
                    isEligible: true,  // Mini cards look better when fully opaque
                    isInteractive: false, // Mini cards are not interactive
                    style: .mini, // Use the new mini style
                    onTap: {} // No action needed
                )
            }
        }
    }
    
    // Helper function to parse cards from description string
    private func parseExampleCards(from description: String) -> [Card] {
        guard let exampleRangeStart = description.range(of: "(e.g.,")?.upperBound,
              let exampleRangeEnd = description.lastIndex(of: ")") else {
            return []
        }
        
        let exampleSubstring = description[exampleRangeStart..<exampleRangeEnd]
            .trimmingCharacters(in: .whitespaces)
        
        let cardStrings = exampleSubstring.split(separator: " ")
        
        var cards: [Card] = []
        
        for cardString in cardStrings {
            var rankString = ""
            var suitString = ""
            
            if cardString.hasPrefix("10") {
                rankString = "10"
                suitString = String(cardString.dropFirst(2))
            } else if cardString.count >= 2 {
                rankString = String(cardString.prefix(1))
                suitString = String(cardString.suffix(1))
            }
            
            guard let rank = rankMap[rankString],
                  let suit = suitMap[suitString] else {
                continue // Skip if parsing fails
            }
            
            cards.append(Card(suit: suit, rank: rank))
        }
        
        return cards
    }
    
    // Mapping dictionaries for parsing
    private let rankMap: [String: Rank] = [
        "A": .ace, "2": .two, "3": .three, "4": .four, "5": .five,
        "6": .six, "7": .seven, "8": .eight, "9": .nine, "10": .ten,
        "J": .jack, "Q": .queen, "K": .king
    ]
    
    private let suitMap: [String: Suit] = [
        "♥": .hearts, "♦": .diamonds, "♣": .clubs, "♠": .spades
    ]
}

struct PlayHandButtonContainer: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var gameState: GameState

    var body: some View {
        ZStack {
            // Use derived condition for visibility
            if viewModel.selectedCards.count >= 2 && !viewModel.isSuccessState {
                PrimaryButton(
                    title: "Play hand",
                    icon: "play.fill",
                    isAnimated: true,
                    isErrorState: viewModel.isErrorState,
                    errorAnimationTimestamp: viewModel.errorAnimationTimestamp,
                    isSuccessState: viewModel.isSuccessState,
                    action: {
                        Task { @MainActor in
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
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
} 
