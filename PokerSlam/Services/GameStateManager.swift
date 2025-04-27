import Foundation
import SwiftUI // For @MainActor, @Published, withAnimation

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var cardPositions: [CardPosition] = []
    @Published private(set) var score: Int = 0
    @Published var isGameOver = false
    @Published private(set) var lastPlayedHand: HandType? // Can be set internally
    @Published private(set) var hasUserInteractedThisGame: Bool = false // Can be set internally
    
    var deck: [Card] = []
    
    // Dependencies (will be injected later if needed, e.g., for calling eligibility checks after dealing)
    // var cardSelectionManager: CardSelectionManager? 
    var onNewCardsDealt: (() -> Void)?
    var onGameOverChecked: (() -> Void)?
    
    // Haptics (Injected)
    private let hapticsManager: HapticsManaging
    // private let shiftFeedback = UIImpactFeedbackGenerator(style: .light) // Removed
    // private let newCardFeedback = UIImpactFeedbackGenerator(style: .soft) // Removed
    
    // Hand Detection (Injected via closure)
    private let detectHand: ([Card]) -> HandType?
    
    // Initialize with dependencies
    init(hapticsManager: HapticsManaging, detectHand: @escaping ([Card]) -> HandType? = PokerHandDetector.detectHand) {
        self.hapticsManager = hapticsManager
        self.detectHand = detectHand
        // Prepare haptics if kept local // Removed
        // shiftFeedback.prepare() // Removed
        // newCardFeedback.prepare() // Removed
        // Initial setup
        setupDeck()
        // dealInitialCards() // Let GameViewModel call this after init
    }
    
    // MARK: - Game Setup & Reset
    
    func setupDeck() {
        deck = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        deck.shuffle()
        // print("🃏 Deck setup with \(deck.count) cards.") // Removed
    }
    
    func dealInitialCards() {
        var initialPositions: [CardPosition] = [] // Define outside the if/else

        // Use GridConstants.initialCardCount
        // Replace guard with if/else
        if deck.count >= GridConstants.initialCardCount {
             // --- Standard path: Deal 25 cards --- 
             // print("Deck has sufficient cards (\(deck.count)). Dealing \(GridConstants.initialCardCount).") // Removed
             // Use GridConstants.rows and GridConstants.columns
             for row in 0..<GridConstants.rows {
                 for col in 0..<GridConstants.columns {
                     if let card = deck.popLast() {
                         initialPositions.append(CardPosition(card: card, row: row, col: col))
                     }
                 }
             }
        } else {
            // --- Edge Case Path: Deal remaining (< 25) cards --- 
            // print("⚠️ Warning: Deck only has \(deck.count) cards. Dealing available cards.") // Removed
            let cardsToDeal = deck.count
            for i in 0..<cardsToDeal {
                if let card = deck.popLast() {
                    // Use GridConstants.columns
                    let row = i / GridConstants.columns
                    let col = i % GridConstants.columns
                    initialPositions.append(CardPosition(card: card, row: row, col: col))
                }
            }
            // No return needed, proceed to animation
        }

        // --- Common logic: Animate dealing whatever is in initialPositions --- 
        cardPositions.removeAll()
        // print("Dealing initial cards...") // Removed
        
        // Use AnimationConstants
        let baseDelay = AnimationConstants.initialDealBaseDelay
        let staggerDelayIncrement = AnimationConstants.initialDealStagger
        
        for (_, position) in initialPositions.enumerated() {
            let row = position.targetRow
            let col = position.targetCol
            // Use GridConstants.columns
            let staggerDelay = Double(row * GridConstants.columns + col) * staggerDelayIncrement
            let totalDelay = baseDelay + staggerDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                // Use AnimationConstants for the spring
                withAnimation(.spring(response: AnimationConstants.newCardDealSpringResponse, dampingFraction: AnimationConstants.newCardDealSpringDamping)) {
                    self.cardPositions.append(position)
                }
                // Use injected hapticsManager with correct method
                self.hapticsManager.playNewCardImpact()
                
                if self.cardPositions.count == initialPositions.count {
                    // print("✅ Initial deal complete. Card count: \(self.cardPositions.count)") // Removed
                    self.onNewCardsDealt?() // Notify GameViewModel to update eligibility etc.
                }
            }
        }
    }
    
    func resetState() {
        // print("🔄 Resetting Game State Manager...") // Removed
        cardPositions.removeAll()
        score = 0
        isGameOver = false
        lastPlayedHand = nil
        hasUserInteractedThisGame = false
        setupDeck() // Re-setup deck
        // Note: dealInitialCards should be called *after* reset by GameViewModel
    }
    
    // MARK: - Game Play Logic
    
    func updateScore(by amount: Int) {
        score += amount
    }
    
    func setLastPlayedHand(_ hand: HandType?) {
        lastPlayedHand = hand
    }

    func setUserInteracted() {
         if !hasUserInteractedThisGame {
              hasUserInteractedThisGame = true
         }
    }
    
    /// Removes played cards, shifts remaining cards down, deals new cards, and checks game over.
    /// Calls completion handlers for updating eligibility and checking game over state.
    /// Uses async/await to sequence operations with delays matching animations.
    func removeCardsAndShiftAndDeal(playedCards: [Card]) async {
        guard !playedCards.isEmpty else { return }

        let playedCardIDs = Set(playedCards.map { $0.id })
        let emptyPositions = playedCards.compactMap { card in
            cardPositions.first { $0.card.id == card.id }
                .map { ($0.currentRow, $0.currentCol) }
        }
        
        // print("🔍 Animating removal of \(playedCards.count) cards. Positions: \(emptyPositions)") // Removed

        // 1. Trigger removal animation by setting the flag
        withAnimation(.spring(response: AnimationConstants.newCardDealSpringResponse, dampingFraction: AnimationConstants.newCardDealSpringDamping)) {
            for index in cardPositions.indices {
                if playedCardIDs.contains(cardPositions[index].card.id) {
                    cardPositions[index].isBeingRemoved = true
                }
            }
            // Optional: Play a different haptic for removal? Or rely on GameViewModel's success haptic.
            // self.hapticsManager.play...() 
        }

        // 2. WAIT for the removal animation to complete
        do {
            // Use the same animation duration used for the trigger
            let removalDuration = UInt64(AnimationConstants.newCardDealSpringResponse * 1_000_000_000) 
            try await Task.sleep(nanoseconds: removalDuration)
        } catch { 
            // Log non-fatally if needed, ignore cancellation errors
            if !(error is CancellationError) {
                 print("⏱️ Removal Task.sleep interrupted unexpectedly: \(error)") 
            }
        }

        // 3. Actually remove the cards from the data source AFTER animation delay
        cardPositions.removeAll { $0.isBeingRemoved }
        // print("🔍 Remaining cards after removal, before shift: \(cardPositions.count)") // Removed

        // 4. Shift existing cards down (triggers its own animation)
        shiftCardsDown(basedOn: emptyPositions)
        
        // 5. Wait for shift animation to visually complete
        do {
             let shiftDuration = UInt64(AnimationConstants.cardShiftDuration * 1_000_000_000)
             try await Task.sleep(nanoseconds: shiftDuration)
        } catch {
            // print("⏱️ Shift Task.sleep interrupted: \(error)") // Removed (or log non-fatally if needed)
        }
        
        // 6. Deal new cards (triggers its own animation)
        dealNewCardsToFillGrid() 
        
        // Callbacks are now handled within dealNewCardsToFillGrid
    }
    
    // shiftCardsDown remains synchronous, animation handled by SwiftUI
    private func shiftCardsDown(basedOn previousEmptyPositions: [(Int, Int)]) {
        // Use AnimationConstants for the spring
        withAnimation(.spring(response: AnimationConstants.cardShiftSpringResponse, dampingFraction: AnimationConstants.cardShiftSpringDamping)) {
            // Use injected hapticsManager with correct method
            self.hapticsManager.playShiftImpact()
            
            var cardsToUpdate = self.cardPositions // Work on a copy to calculate targets
            var needsUpdate = false
            
            // Use GridConstants.columns
            for col in 0..<GridConstants.columns {
                // Use the copy for filtering/sorting/calculation
                let columnCards = cardsToUpdate
                    .filter { $0.currentCol == col }
                    .sorted { $0.currentRow < $1.currentRow } // Sort top-to-bottom
                
                // Empty positions calculation remains the same
                let columnEmptyPositions = previousEmptyPositions
                    .filter { $0.1 == col }
                    .map { $0.0 }
                    .sorted() // Sort top-to-bottom
                
                if columnEmptyPositions.isEmpty || columnCards.isEmpty {
                    continue
                }
                
                // print("🔄 Shifting column \(col). Cards: \(columnCards.map {$0.currentRow}), Empties: \(columnEmptyPositions)") // Removed

                // Use GridConstants.rows
                var currentTargetRow = GridConstants.rows - 1 // Start checking from the bottom row (index 4)
                for card in columnCards.reversed() { // Iterate bottom-up
                    // Find the index in the *copy* being updated
                    if let cardIndex = cardsToUpdate.firstIndex(where: { $0.id == card.id }) {
                        // Check if the target row needs to be updated in the copy
                        if cardsToUpdate[cardIndex].targetRow != currentTargetRow {
                            // print("  ➡️ Calculating shift for card \(card.card.rank)\(card.card.suit) from \(originalRow) to target \(currentTargetRow) in col \(col)") // Removed
                            // Update the targetRow in the copy
                            cardsToUpdate[cardIndex].targetRow = currentTargetRow
                            needsUpdate = true
                        }
                        currentTargetRow -= 1
                    }
                }
            }
            
            // If any targets were updated, apply the changes to the main array
            if needsUpdate {
                 self.cardPositions = cardsToUpdate.map { pos in
                     var mutablePos = pos
                     // Update the actual currentRow to match the calculated targetRow
                     // This change will be animated by the view
                     mutablePos.currentRow = pos.targetRow 
                     return mutablePos
                 }
            } else {
                 // print("🔄 No card shifts required.") // Removed
            }
            // print("🔍 Card count after shift: \(self.cardPositions.count)") // Removed
        }
    }
    
    // dealNewCardsToFillGrid remains synchronous, animation handled by SwiftUI
    // It now calls the completion handlers/checks internally
    private func dealNewCardsToFillGrid() {
        let currentPositions = Set(cardPositions.map { GridPosition(row: $0.currentRow, col: $0.currentCol) })
        
        for col in 0..<GridConstants.columns {
             for row in (0..<GridConstants.rows).reversed() { // Check bottom-up
                 if !currentPositions.contains(GridPosition(row: row, col: col)) {
                    // Find the first empty slot from the bottom in this column
                    // But new cards should fill from the TOP. Let's rethink. 
                    // We need empty slots at the TOP after shifting.
                 }
             }
        }
        
         // ---- Original logic to find empty slots for new cards ----
         // It seems the original logic calculated based on the *expected* final state?
         // Let's recalculate empty positions *after* shifting based on target rows.
         let finalOccupiedPositions = Set(cardPositions.map { GridPosition(row: $0.targetRow, col: $0.targetCol) })
         var finalEmptyPositions: [(Int, Int)] = []
         // Use GridConstants.columns and GridConstants.rows
         for col in 0..<GridConstants.columns {
             for row in 0..<GridConstants.rows { // Check top-down for filling
                 if !finalOccupiedPositions.contains(GridPosition(row: row, col: col)) {
                     finalEmptyPositions.append((row, col))
                 }
             }
         }
         
         // Sort empty positions to fill top rows first, then left-to-right
         finalEmptyPositions.sort { ($0.0, $0.1) < ($1.0, $1.1) }
         
        // --- End original logic adaptation ---

        // print("🃏 Dealing new cards. Deck: \(deck.count). Empty slots: \(finalEmptyPositions.count)") // Removed
        
        if finalEmptyPositions.isEmpty {
             // print("✅ Grid already full. No new cards needed.") // Removed
             // Still need to check game over after shifting completes
             checkGameOver()        // Moved here
             onGameOverChecked?()   // Moved here
             onNewCardsDealt?()     // Moved here (Update eligibility even if no cards dealt)
             return
        }

        // Use AnimationConstants for the spring
        withAnimation(.spring(response: AnimationConstants.newCardDealSpringResponse, dampingFraction: AnimationConstants.newCardDealSpringDamping)) {
            // Use injected hapticsManager with correct method
            self.hapticsManager.playNewCardImpact()
            
            var cardsAdded = 0
            for position in finalEmptyPositions {
                if let card = self.deck.popLast() {
                    // print("  ➡️ Adding new card \(card.rank)\(card.suit) at row \(position.0), col \(position.1)") // Removed
                    // Initialize new cards at their final position
                    self.cardPositions.append(CardPosition(card: card, row: position.0, col: position.1))
                    cardsAdded += 1
                } else {
                    // print("🔥 Deck empty! Cannot fill remaining slots.") // Removed
                    break
                }
            }
            // print("✅ Added \(cardsAdded) new cards. Final count: \(self.cardPositions.count)") // Removed
        }
        
        // Update eligible cards and check game over AFTER new cards are added
        onNewCardsDealt?()     // Remains here
        checkGameOver()        // Remains here
        onGameOverChecked?()   // Remains here
    }


    func checkGameOver() {
        // Preserving original logic exactly as requested
        let allCards = cardPositions.map { $0.card }
        // print("🔍 Checking for game over. Cards: \(allCards.count), Deck: \(deck.count)") // Removed
        
        // Use GridConstants.initialCardCount
        if deck.isEmpty && cardPositions.count < GridConstants.initialCardCount {
            // print("🔍 Deck empty, checking remaining hands...") // Removed
            // Use GridConstants.minHandSize and GridConstants.maxHandSize
            for size in GridConstants.minHandSize...GridConstants.maxHandSize {
                let combinations = allCards.combinations(ofCount: size)
                for cards in combinations {
                    // Check if selectable AND is a valid hand (Use self.detectHand)
                    if canSelectCards(cards), self.detectHand(cards) != nil {
                        // print("  ✅ Valid hand found among remaining cards. Game NOT over.") // Removed
                        self.isGameOver = false
                        onGameOverChecked?() // Notify immediately
                        return // *** Exit the function early ***
                    }
                }
            }
            // print("  ❌ No valid hands found among remaining cards. GAME OVER.") // Removed
            self.isGameOver = true
            onGameOverChecked?() // Notify here as well
            return // Added return for consistency
        }
        
        // Normal check with cards on board
        // print("🔍 Checking all possible hands on board...") // Removed
        // Use GridConstants.minHandSize and GridConstants.maxHandSize
        for size in GridConstants.minHandSize...GridConstants.maxHandSize {
            let combinations = allCards.combinations(ofCount: size)
             if combinations.isEmpty { continue } // Skip if no combinations of this size
            for cards in combinations {
                // Check if selectable AND is a valid hand (Use self.detectHand)
                if canSelectCards(cards), self.detectHand(cards) != nil {
                    // print("  ✅ Valid hand possible on board. Game NOT over.") // Removed
                    self.isGameOver = false
                    onGameOverChecked?() // Notify immediately
                    return // *** Exit the function early ***
                }
            }
        }
        
        // Only declare game over if NO selectable valid hands were found
        // print("❌ No selectable valid hands found on board. GAME OVER.") // Removed
        self.isGameOver = true
        onGameOverChecked?() // Notify here as well
    }
    
    /// Helper for checkGameOver: Determines if a given set of cards *could* be selected based on adjacency.
    /// This replicates the check within the original checkGameOver logic.
    func canSelectCards(_ cards: [Card]) -> Bool {
        guard !cards.isEmpty else { return false }
        // Use GridConstants.maxHandSize
        guard cards.count <= GridConstants.maxHandSize else { return false } // Max selection size
        if cards.count == 1 { return true } // Single card is always selectable

        // Need positions for adjacency checks
        // Convert to GridPosition for easier hashing/comparison
        let positions: [GridPosition] = cards.compactMap { card in
            findCardPosition(card).map { GridPosition(row: $0.row, col: $0.col) }
        }
        guard positions.count == cards.count else { return false } // All cards must be on the board

        // --- BFS Check for Connectivity --- 
        var visited = Set<GridPosition>()
        var queue: [GridPosition] = []
        
        // Start BFS from the first position
        guard let startPosition = positions.first else { return false } // Should not happen if count > 1
        queue.append(startPosition)
        visited.insert(startPosition)
        
        while let currentPosition = queue.popLast() { // Using popLast for DFS-like behavior, can use popFirst() for true BFS
            // Find neighbors of currentPosition that are also in the input 'positions' list
            for potentialNeighbor in positions {
                if !visited.contains(potentialNeighbor) && 
                   isAdjacent(position1: (currentPosition.row, currentPosition.col), 
                              position2: (potentialNeighbor.row, potentialNeighbor.col)) 
                {
                    visited.insert(potentialNeighbor)
                    queue.append(potentialNeighbor)
                }
            }
        }
        
        // If the number of visited positions equals the total number of positions, they are connected
        return visited.count == positions.count
    }
    
    // MARK: - Helpers (Copied from GameViewModel for internal use)
    
    func findCardPosition(_ card: Card) -> (row: Int, col: Int)? {
        return cardPositions.first { $0.card.id == card.id }
            .map { ($0.currentRow, $0.currentCol) }
    }
    
    /// Gets the card at a specific position in the grid
    func cardAt(row: Int, col: Int) -> Card? {
        return cardPositions.first { $0.currentRow == row && $0.currentCol == col }?.card
    }
    
    /// Gets all cards in the grid as a 2D array (for compatibility if needed)
    var cards: [[Card?]] {
        // Use GridConstants.rows and GridConstants.columns
        var grid = Array(repeating: Array(repeating: Card?.none, count: GridConstants.columns), count: GridConstants.rows)
        for position in cardPositions {
             // Ensure indices are valid before assignment
             // Use GridConstants.rows and GridConstants.columns
             if position.currentRow >= 0 && position.currentRow < GridConstants.rows && position.currentCol >= 0 && position.currentCol < GridConstants.columns {
                grid[position.currentRow][position.currentCol] = position.card
             } else {
                 // print("🔥 Error: Card position out of bounds: row \(position.currentRow), col \(position.currentCol)") // Removed
                 // Consider adding assertionFailure or logging here for Release builds
                 assertionFailure("Card position out of bounds: row \(position.currentRow), col \(position.currentCol)")
             }
        }
        return grid
    }
    
    // Adjacency check - needed for checkGameOver helper
    func isAdjacent(position1: (row: Int, col: Int), position2: (row: Int, col: Int)) -> Bool {
        let rowDiff = abs(position1.row - position2.row)
        let colDiff = abs(position1.col - position2.col)

        // Allow diagonal only if columns are immediately adjacent (colDiff == 1) and rows differ by at most 1 (rowDiff <= 1)
        if rowDiff <= 1 && colDiff <= 1 {           
            // Exclude the case where both rowDiff and colDiff are 0 (same card)
             if rowDiff == 0 && colDiff == 0 {
                 return false
             }
            return true
        }
        
        return false
    }
}

// Helper struct (can be moved later if needed)
private struct GridPosition: Hashable {
    let row: Int
    let col: Int
}
 
