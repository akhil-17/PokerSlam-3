import Foundation
import SwiftUI // For @MainActor, @Published, Date

@MainActor
final class CardSelectionManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var selectedCards: Set<Card> = []
    @Published private(set) var eligibleCards: Set<Card> = []
    @Published private(set) var selectionOrder: [Card] = []
    @Published private(set) var currentHandText: String?
    @Published private(set) var isAnimatingHandText = false
    @Published private(set) var isErrorState = false
    @Published private(set) var errorAnimationTimestamp: Date?
    @Published private(set) var isSuccessState = false

    // MARK: - Internal State
    private var selectedCardPositions: [(row: Int, col: Int)] = []

    // MARK: - Dependencies
    private let gameStateManager: GameStateManager
    private let hapticsManager: HapticsManaging
    
    // Callback to notify GameViewModel to update connections
    var onSelectionChanged: (() -> Void)?

    init(gameStateManager: GameStateManager, hapticsManager: HapticsManaging) {
        self.gameStateManager = gameStateManager
        self.hapticsManager = hapticsManager
    }

    // MARK: - Selection Logic

    func selectCard(_ card: Card) {
        // Use gameStateManager.isGameOver instead of relying on GameViewModel
        guard !gameStateManager.isGameOver else { return }

        if selectedCards.contains(card) {
            handleDeselection(card)
        } else if isCardEligibleForSelection(card) && selectedCards.count < 5 {
            handleSelection(card)
        } else if !selectedCards.isEmpty {
            // If tapping an ineligible card with cards selected, unselect all
            unselectAllCards()
        } else {
            // Invalid selection - play error feedback
            hapticsManager.playErrorNotification()
        }
        
        // Notify that selection changed (for connection updates)
        onSelectionChanged?()
    }

    private func handleDeselection(_ card: Card) {
        // Original logic: If multiple selected, deselect all. If only one, deselect it.
        // This seems counter-intuitive. Let's refine to: Always deselect the tapped card.
        // Revisit if the original multi-deselect was intentional.
        // For now, implementing deselect-single:
        // selectedCards.remove(card)
        // if let index = selectionOrder.firstIndex(of: card) {
        //     selectionOrder.remove(at: index)
        //     // Also remove corresponding position if tracking matches order
        //     if index < selectedCardPositions.count { 
        //         selectedCardPositions.remove(at: index)
        //     }
        // }
        //  // If selectionOrder and selectedCardPositions should always match, ensure consistency
        //  if selectedCards.isEmpty { // If last card was deselected
        //      selectedCardPositions.removeAll()
        //      selectionOrder.removeAll()
        //  } else {
        //      // Rebuild positions based on remaining selection order?
        //      rebuildSelectedPositions()
        //  }
        
        // New logic: Tapping any selected card unselects all
        unselectAllCards()
        
        // hapticsManager.playDeselectionImpact() // unselectAllCards plays this
        // updateEligibleCards() // unselectAllCards updates eligibility
        // updateCurrentHandText() // unselectAllCards updates text
        // onSelectionChanged is called by selectCard
    }
    
    private func handleSelection(_ card: Card) {
         // Set interaction flag via GameStateManager
        if selectedCards.isEmpty {
            gameStateManager.setUserInteracted()
        }
        selectedCards.insert(card)
        if let position = gameStateManager.findCardPosition(card) { // Use GameStateManager's helper
            selectedCardPositions.append(position)
        }
        selectionOrder.append(card)
        hapticsManager.playSelectionChanged()
        updateEligibleCards()
        updateCurrentHandText()
        // onSelectionChanged is called by selectCard
    }
    
    func unselectAllCards() {
        guard !selectedCards.isEmpty else { return } // Avoid unnecessary updates/haptics
        selectedCards.removeAll()
        selectedCardPositions.removeAll()
        selectionOrder.removeAll()
        currentHandText = nil
        hapticsManager.playDeselectionImpact()
        updateEligibleCards()
        // Notify that selection changed (for connection updates)
        onSelectionChanged?()
    }
    
    // MARK: - Eligibility & Adjacency (Using GameStateManager for positions)

    private func isCardEligibleForSelection(_ card: Card) -> Bool {
        if selectedCards.isEmpty { return true }
        guard selectedCards.count < 5 else { return false } // Explicitly check count here too

        guard let cardPosition = gameStateManager.findCardPosition(card) else { return false }

        // Check if the card is adjacent to *any* of the currently selected cards
        for position in selectedCardPositions {
            // Use the *exact* adjacency logic from GameStateManager/original ViewModel
            if gameStateManager.isAdjacent(position1: cardPosition, position2: position) {
                return true
            }
        }

        return false
    }

    func updateEligibleCards() {
        eligibleCards.removeAll()
        
        // If 5 cards are already selected, no other cards should be eligible
        if selectedCards.count >= 5 {
            return
        }

        // Get all current card positions from GameStateManager
        let allCardPositions = gameStateManager.cardPositions

        if selectedCards.isEmpty {
            // If no cards are selected, all cards are eligible
            for position in allCardPositions {
                eligibleCards.insert(position.card)
            }
            return
        }

        // Find all cards adjacent to any selected card
        for position in allCardPositions {
            // Check eligibility using the internal method (which uses selectedPositions)
            if isCardEligibleForSelection(position.card) {
                eligibleCards.insert(position.card)
            }
        }

        // Remove any cards that are already selected
        eligibleCards.subtract(selectedCards)
    }

    // MARK: - Hand Text & State Updates

    func updateCurrentHandText() {
        guard !selectedCards.isEmpty else {
            currentHandText = nil
            return
        }

        let selectedCardsArray = Array(selectedCards) // Use the Set directly
        if let handType = PokerHandDetector.detectHand(cards: selectedCardsArray) {
            currentHandText = "\(handType.displayName) +\(handType.rawValue)"
        } else {
            // Optionally show text indicating number selected if not a valid hand?
            // currentHandText = "\(selectedCardsArray.count) cards selected"
            currentHandText = nil // Keep original behavior
        }
    }
    
    /// Clears the selection state after a hand is played.
    func clearSelectionAfterPlay() {
        selectedCards.removeAll()
        selectedCardPositions.removeAll()
        selectionOrder.removeAll()
        // Keep currentHandText for animation? Reset is handled later.
        // Keep isSuccessState for animation? Reset is handled later.
    }
    
    /// Sets the state for a successfully played hand animation.
    func setSuccessState(handType: HandType) {
        isSuccessState = true
        isAnimatingHandText = true
        // Update text immediately for animation
        currentHandText = "\(handType.displayName) +\(handType.rawValue)"
    }
    
    /// Resets the success state after animations complete.
    func resetSuccessState() {
         // Use withAnimation in the calling context (GameViewModel) if needed
         self.isSuccessState = false
         self.isAnimatingHandText = false
         self.currentHandText = nil 
         // Update eligible cards *after* state is reset
         self.updateEligibleCards()
    }
    
    /// Sets the state for an invalid hand attempt.
    func setErrorState() {
        isErrorState = true
        errorAnimationTimestamp = Date()
    }
    
    /// Resets the error state after animations complete.
    func resetErrorState() {
        // Use withAnimation in the calling context (GameViewModel) if needed
        self.isErrorState = false
        self.errorAnimationTimestamp = nil
    }
    
    // MARK: - Resetting State
    func reset() {
        // print("🔄 Resetting Card Selection Manager...") // Removed
        selectedCards.removeAll()
        eligibleCards.removeAll()
        isSuccessState = false
        isErrorState = false
        // Call onSelectionChanged to notify observers (like ConnectionDrawingService)
        onSelectionChanged?() // Removed argument, closure takes Void
    }
    
    // MARK: - Helpers
    
    private func rebuildSelectedPositions() {
         selectedCardPositions = selectionOrder.compactMap { gameStateManager.findCardPosition($0) }
    }
} 