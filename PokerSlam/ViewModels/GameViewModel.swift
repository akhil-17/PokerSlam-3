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
    private let hapticsManager: HapticsManaging

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

    // Convenience initializer for SwiftUI Views (creates own dependencies)
    // TODO: Replace with proper dependency injection from App level
    convenience init() {
        let haptics = HapticsManager()
        let gameState = GameStateManager(hapticsManager: haptics)
        let selection = CardSelectionManager(gameStateManager: gameState, hapticsManager: haptics)
        let connections = ConnectionDrawingService(gameStateManager: gameState, cardSelectionManager: selection)
        let animator = ScoreAnimator() 
        self.init(gameStateManager: gameState, 
                  cardSelectionManager: selection, 
                  connectionDrawingService: connections, 
                  scoreAnimator: animator, // Pass animator
                  hapticsManager: haptics)
    }

    // MARK: - Initialization (Designated Initializer)
    // Add scoreAnimator to init
    init(gameStateManager: GameStateManager, cardSelectionManager: CardSelectionManager, connectionDrawingService: ConnectionDrawingService, scoreAnimator: ScoreAnimator, hapticsManager: HapticsManaging) {
        self.gameStateManager = gameStateManager
        self.cardSelectionManager = cardSelectionManager
        self.connectionDrawingService = connectionDrawingService
        self.scoreAnimator = scoreAnimator
        self.hapticsManager = hapticsManager

        setupBindings()
        setupCallbacks()

        // Initial game setup
        gameStateManager.dealInitialCards() // Triggers callback to update eligibility
        scoreAnimator.resetScoreDisplay() // Initialize score display
    }

    private func setupBindings() {
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
        
    }

    private func setupCallbacks() {
        // When selection changes in CardSelectionManager, update ConnectionDrawingService
        cardSelectionManager.onSelectionChanged = { [weak self] in
            // Call updateConnections with no arguments
            self?.connectionDrawingService.updateConnections()
        }

        // When new cards are dealt by GameStateManager, update eligible cards
        gameStateManager.onNewCardsDealt = { [weak self] in
            // CardSelectionManager updates its own published eligibleCards.
            // We just need to ensure its internal method is called.
            self?.cardSelectionManager.updateEligibleCards() // Call with no arguments
        }

        // When GameStateManager checks if the game is over, update UI state
        gameStateManager.onGameOverChecked = { [weak self] in
            // No explicit action needed here now, GameView observes gameStateManager.isGameOver directly
        }
    }

    // MARK: - Computed Properties for UI

    /// Returns whether cards are currently interactive
    var areCardsInteractive: Bool {
        !gameStateManager.isGameOver
    }

    // MARK: - User Actions

    /// Selects or deselects a card.
    func selectCard(_ card: Card) {
        gameStateManager.setUserInteracted() // Correct call
        cardSelectionManager.selectCard(card) // Correct call (no extra args)
    }

    /// Unselects all currently selected cards.
    func unselectAllCards() {
        cardSelectionManager.unselectAllCards()
        // eligibleCards updated via onSelectionChanged callback
    }

    /// Plays the currently selected hand.
    func playHand() {
        gameStateManager.setUserInteracted() // Correct call
        guard !cardSelectionManager.selectedCards.isEmpty else {
            return
        }

        let playedCards = cardSelectionManager.selectedCards
        // Correct call: add label, convert Set to Array
        if let handType = PokerHandDetector.detectHand(cards: Array(playedCards)) { 
            
            // Calculate Score
            let scoreValue = handType.rawValue // Correctly use rawValue
            gameStateManager.updateScore(by: scoreValue)
            gameStateManager.setLastPlayedHand(handType)
            scoreAnimator.updateScore(gameStateManager.score) // Animate to new score
            hapticsManager.playSuccessNotification()

            cardSelectionManager.setSuccessState(handType: handType) // Set UI states
            cardSelectionManager.clearSelectionAfterPlay() // Clear selection model state
            connectionDrawingService.resetConnections() // Clear connection lines immediately
            
            // Perform async actions: remove, shift, deal
            Task {
                // Correct call: convert Set to Array
                await gameStateManager.removeCardsAndShiftAndDeal(playedCards: Array(playedCards))
                // Reset selection AFTER animations/dealing are triggered in GSM
                // But do it before resetting UI state
                self.cardSelectionManager.unselectAllCards()
                
                // Wait a tiny bit for state to potentially settle before resetting UI flag
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Reset the success state so button can reappear
                self.cardSelectionManager.resetSuccessState()
            }

        } else {
            // Trigger error haptic/animation
            hapticsManager.playErrorNotification() // Correct haptic method
            cardSelectionManager.setErrorState() // Set state via manager
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds duration for error indication
                // Reset error state AFTER delay
                cardSelectionManager.resetErrorState()
            }
            // Keep cards selected after invalid attempt
        }
    }

    /// Resets the game to its initial state.
    func resetGame() {
        // 1. Trigger Reset Animation/State
        isResetting = true // Use correct property
        hapticsManager.playResetNotification()

        // Reset all services
        gameStateManager.resetState()
        cardSelectionManager.reset() // Correct reset method name
        scoreAnimator.resetScoreDisplay() // Reset displayed score to 0
        connectionDrawingService.resetConnections()

        // Deal new cards (this will trigger callbacks)
        gameStateManager.dealInitialCards()
        
        // 4. Reset UI animation flag slightly later
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Allow reset animation to start
            self.isResetting = false // Use correct property
        }
    }
}

