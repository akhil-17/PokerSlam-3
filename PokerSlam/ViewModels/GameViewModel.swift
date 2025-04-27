import Foundation
import SwiftUI
import Combine // For .assign(to:)

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Services / Managers
    private let gameStateManager: GameStateManager
    private let cardSelectionManager: CardSelectionManager
    private let connectionDrawingService: ConnectionDrawingService
    private let scoreAnimator: ScoreAnimator
    private let hapticsManager: HapticsManager

    // MARK: - Published Properties for UI Binding
    // State proxied from underlying services

    // From GameStateManager
    @Published private(set) var cardPositions: [CardPosition] = []
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var hasUserInteractedThisGame: Bool = false

    // From CardSelectionManager
    @Published private(set) var selectedCards: Set<Card> = []
    @Published private(set) var eligibleCards: Set<Card> = []
    @Published private(set) var currentHandText: String?
    @Published private(set) var isAnimatingHandText = false
    @Published private(set) var isErrorState = false
    @Published private(set) var errorAnimationTimestamp: Date?
    @Published private(set) var isSuccessState = false

    // From ConnectionDrawingService
    @Published private(set) var connections: [Connection] = []

    // From ScoreAnimator
    @Published private(set) var displayedScore: Int = 0
    @Published private(set) var isScoreAnimating: Bool = false
    // Actual score is now read-only from GameStateManager
    var score: Int { gameStateManager.score }
    
    // Local UI State?
    @Published private(set) var isResetting = false
    @Published private(set) var isAnimating: Bool = false // Temporarily re-added for ConnectionLinesLayer

    // MARK: - Combine Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        // Instantiate services
        self.hapticsManager = HapticsManager()
        // Pass dependencies (HapticsManager, default detector) to GameStateManager
        self.gameStateManager = GameStateManager(hapticsManager: self.hapticsManager)
        // ScoreAnimator needs no deps initially
        self.scoreAnimator = ScoreAnimator()
        // CardSelectionManager needs GameState and Haptics
        self.cardSelectionManager = CardSelectionManager(gameStateManager: self.gameStateManager, hapticsManager: self.hapticsManager)
        // ConnectionDrawingService needs GameState and Selection
        self.connectionDrawingService = ConnectionDrawingService(gameStateManager: self.gameStateManager, cardSelectionManager: self.cardSelectionManager)

        print("🚀 GameViewModel Initialized")
        setupBindings()
        setupCallbacks()

        // Initial game setup
        gameStateManager.dealInitialCards() // Triggers callback to update eligibility
        scoreAnimator.resetScoreDisplay() // Initialize score display
    }

    private func setupBindings() {
        print("🔗 Setting up bindings...")
        // Bind GameStateManager properties
        gameStateManager.$cardPositions
            .assign(to: &$cardPositions)
        gameStateManager.$isGameOver
            .assign(to: &$isGameOver)
         gameStateManager.$hasUserInteractedThisGame
             .assign(to: &$hasUserInteractedThisGame)

        // Bind CardSelectionManager properties
        cardSelectionManager.$selectedCards
            .assign(to: &$selectedCards)
        cardSelectionManager.$eligibleCards
            .assign(to: &$eligibleCards)
        cardSelectionManager.$currentHandText
            .assign(to: &$currentHandText)
        cardSelectionManager.$isAnimatingHandText
            .assign(to: &$isAnimatingHandText)
        cardSelectionManager.$isErrorState
            .assign(to: &$isErrorState)
        cardSelectionManager.$errorAnimationTimestamp
            .assign(to: &$errorAnimationTimestamp)
        cardSelectionManager.$isSuccessState
            .assign(to: &$isSuccessState)

        // Bind ConnectionDrawingService properties
        connectionDrawingService.$connections
            .assign(to: &$connections)

        // Bind ScoreAnimator properties
        scoreAnimator.$displayedScore
            .assign(to: &$displayedScore)
        scoreAnimator.$isScoreAnimating
            .assign(to: &$isScoreAnimating)
        
         print("✅ Bindings setup complete.")
    }

    private func setupCallbacks() {
         print("📞 Setting up callbacks...")
        // When selection changes, update connections
        cardSelectionManager.onSelectionChanged = { [weak self] in
             print("Callback: Selection Changed -> Updating Connections")
            self?.connectionDrawingService.updateConnections()
        }
        
        // When new cards are dealt (initial or after play), update eligibility
        gameStateManager.onNewCardsDealt = { [weak self] in
             print("Callback: New Cards Dealt -> Updating Eligibility")
            self?.cardSelectionManager.updateEligibleCards()
        }
        
        // When game over check completes (optional, if VM needs to react)
         gameStateManager.onGameOverChecked = { [weak self] in
             print("Callback: Game Over Checked. Is Over: \(self?.gameStateManager.isGameOver ?? true)")
             // Can perform actions here if needed when game over state is confirmed
         }
         print("✅ Callbacks setup complete.")
    }

    // MARK: - Computed Properties for UI

    /// Returns whether cards are currently interactive
    var areCardsInteractive: Bool {
        !gameStateManager.isGameOver
    }

    // MARK: - User Actions

    /// Selects or deselects a card.
    func selectCard(_ card: Card) {
        print("🖱️ selectCard Action: \(card.rank)\(card.suit)")
        cardSelectionManager.selectCard(card)
        // Connection update is handled by the onSelectionChanged callback
    }

    /// Unselects all currently selected cards.
    func unselectAllCards() {
        print("🖱️ unselectAllCards Action")
        cardSelectionManager.unselectAllCards()
         // Connection update is handled by the onSelectionChanged callback
    }

    /// Plays the currently selected hand.
    func playHand() {
        print("▶️ playHand Action")
        let cardsToPlay = Array(cardSelectionManager.selectedCards)
        guard !cardsToPlay.isEmpty else {
             print("⚠️ Play attempt with no cards selected.")
             return
        }

        if let handType = PokerHandDetector.detectHand(cards: cardsToPlay) {
            print("✅ Valid Hand Detected: \(handType.displayName)")
            // --- Valid Hand Sequence ---
            gameStateManager.updateScore(by: handType.rawValue)
            gameStateManager.setLastPlayedHand(handType)
            scoreAnimator.updateScore(gameStateManager.score) // Animate to new score
            hapticsManager.playSuccessNotification()

            cardSelectionManager.setSuccessState(handType: handType) // Set UI states
            cardSelectionManager.clearSelectionAfterPlay() // Clear selection model state
            connectionDrawingService.resetConnections() // Clear connection lines immediately
            
            // Trigger removal/shift/deal in GameStateManager
            // Wrap the async call in a Task
            Task {
                await gameStateManager.removeCardsAndShiftAndDeal(playedCards: cardsToPlay)
                // GameStateManager now handles its internal sequencing and callbacks
            }

            // Schedule the reset of the success UI state after animation durations
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.successStateResetDelay) { // Match original delay
                print("⏱️ Resetting success state UI after delay")
                // Use withAnimation if GameView needs it for the state change
                withAnimation(AnimationConstants.uiStateResetAnimation) {
                    self.cardSelectionManager.resetSuccessState()
                }
                 // Eligibility is updated via GameStateManager callback (onNewCardsDealt)
            }

        } else {
             print("❌ Invalid Hand Attempt")
            // --- Invalid Hand Sequence ---
            gameStateManager.setLastPlayedHand(nil)
            hapticsManager.playErrorNotification()
            cardSelectionManager.setErrorState()

            // Schedule the reset of the error UI state
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.errorStateResetDelay) { // Match original delay
                print("⏱️ Resetting error state UI after delay")
                 // Use withAnimation if GameView needs it for the state change
                 // Use AnimationConstants.uiStateResetAnimation (or a specific one for error)
                 // withAnimation(AnimationConstants.uiStateResetAnimation) { ... }
                 self.cardSelectionManager.resetErrorState()
            }
        }
    }

    /// Resets the game to its initial state.
    func resetGame() {
        print("🔄 resetGame Action")
        guard !isResetting else { return } // Prevent double-reset

        isResetting = true
        hapticsManager.playResetNotification()

        // Reset all services
        gameStateManager.resetState()
        cardSelectionManager.resetSelection()
        scoreAnimator.resetScoreDisplay() // Reset displayed score to 0
        connectionDrawingService.resetConnections()

        // Deal new cards (this will trigger callbacks)
        gameStateManager.dealInitialCards()
        
        // Reset the isResetting flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.gameResetDelay) { // Match original delay
            print("⏱️ Resetting resetGame state UI after delay")
            self.isResetting = false
        }
    }
}

