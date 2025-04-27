import Foundation
import SwiftUI // For @MainActor, @Published, withAnimation

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var cardPositions: [CardPosition] = []
    @Published private(set) var score: Int = 0
    @Published var isGameOver = false
    @Published private(set) var lastPlayedHand: HandType? // Can be set internally
    @Published private(set) var hasUserInteractedThisGame: Bool = false // Can be set internally
    
    private var deck: [Card] = []
    
    // Dependencies (will be injected later if needed, e.g., for calling eligibility checks after dealing)
    // var cardSelectionManager: CardSelectionManager? 
    var onNewCardsDealt: (() -> Void)?
    var onGameOverChecked: (() -> Void)?
    
    // Haptics (optional, can be handled by GameViewModel orchestrator)
    // var hapticsManager: HapticsManager? 
    private let shiftFeedback = UIImpactFeedbackGenerator(style: .light) // Keep local for now, or inject HapticsManager
    private let newCardFeedback = UIImpactFeedbackGenerator(style: .soft)
    
    init() {
        // Prepare haptics if kept local
        shiftFeedback.prepare()
        newCardFeedback.prepare()
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
        print("🃏 Deck setup with \(deck.count) cards.")
    }
    
    func dealInitialCards() {
        var initialPositions: [CardPosition] = [] // Define outside guard

        guard deck.count >= 25 else {
            // This block executes if deck.count < 25
            print("Error: Not enough cards in deck to deal initial grid.") 

            let cardsToDeal = deck.count // Line 62

            /* // Line 64 (Start comment)
            for i in 0..<cardsToDeal { 
                if let card = deck.popLast() {
                    let row = i / 5
                    let col = i % 5
                    initialPositions.append(CardPosition(card: card, row: row, col: col))
                }
            }
            */ // End comment

            deck.removeAll() 
            isGameOver = true 
            print("🔥 Warning: Dealt only \(cardsToDeal) cards initially. Game over.")
            return // Must exit scope
        }
        
        // --- This code runs ONLY if deck.count >= 25 ---
        for row in 0..<5 {
            for col in 0..<5 {
                if let card = deck.popLast() {
                    initialPositions.append(CardPosition(card: card, row: row, col: col))
                }
            }
        }
        
        cardPositions.removeAll()
        print("Dealing initial cards...")
        
        let baseDelay = 0.1
        let staggerDelayIncrement = 0.01
        
        for (_, position) in initialPositions.enumerated() {
            let row = position.targetRow
            let col = position.targetCol
            let staggerDelay = Double(row * 5 + col) * staggerDelayIncrement
            let totalDelay = baseDelay + staggerDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.cardPositions.append(position)
                }
                self.newCardFeedback.impactOccurred() // Use local or injected haptics
                
                if self.cardPositions.count == initialPositions.count {
                    print("✅ Initial deal complete. Card count: \(self.cardPositions.count)")
                    self.onNewCardsDealt?() // Notify GameViewModel to update eligibility etc.
                }
            }
        }
    }
    
    func resetState() {
        print("🔄 Resetting Game State Manager...")
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
    func removeCardsAndShiftAndDeal(playedCards: [Card]) {
        guard !playedCards.isEmpty else { return }

        let emptyPositions = playedCards.compactMap { card in
            cardPositions.first { $0.card.id == card.id }
                .map { ($0.currentRow, $0.currentCol) }
        }
        
        print("🔍 Removing \(playedCards.count) cards. Positions: \(emptyPositions)")

        cardPositions.removeAll { position in
            playedCards.contains { $0.id == position.card.id }
        }
        
        print("🔍 Remaining cards before shift: \(cardPositions.count)")

        // --- Shift existing cards down --- 
        shiftCardsDown(basedOn: emptyPositions)
        
        // --- Deal new cards after shift animation --- 
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Use constant for animation duration?
            self.dealNewCardsToFillGrid()
        }
    }
    
    private func shiftCardsDown(basedOn previousEmptyPositions: [(Int, Int)]) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.shiftFeedback.impactOccurred() // Use local or injected haptics
            
            var cardsToUpdate = self.cardPositions // Work on a copy to calculate targets
            var needsUpdate = false
            
            for col in 0..<5 {
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
                
                print("🔄 Shifting column \(col). Cards: \(columnCards.map {$0.currentRow}), Empties: \(columnEmptyPositions)")

                var currentTargetRow = 4 // Start checking from the bottom row
                for card in columnCards.reversed() { // Iterate bottom-up
                    let originalRow = card.currentRow
                    // Find the index in the *copy* being updated
                    if let cardIndex = cardsToUpdate.firstIndex(where: { $0.id == card.id }) {
                        // Check if the target row needs to be updated in the copy
                        if cardsToUpdate[cardIndex].targetRow != currentTargetRow {
                            print("  ➡️ Calculating shift for card \(card.card.rank)\(card.card.suit) from \(originalRow) to target \(currentTargetRow) in col \(col)")
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
                 print("🔄 No card shifts required.")
            }
            print("🔍 Card count after shift: \(self.cardPositions.count)")
        }
    }
    
    private func dealNewCardsToFillGrid() {
        let currentPositions = Set(cardPositions.map { GridPosition(row: $0.currentRow, col: $0.currentCol) })
        
        for col in 0..<5 {
             for row in (0..<5).reversed() { // Check bottom-up
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
         for col in 0..<5 {
             for row in 0..<5 { // Check top-down for filling
                 if !finalOccupiedPositions.contains(GridPosition(row: row, col: col)) {
                     finalEmptyPositions.append((row, col))
                 }
             }
         }
         
         // Sort empty positions to fill top rows first, then left-to-right
         finalEmptyPositions.sort { ($0.0, $0.1) < ($1.0, $1.1) }
         
        // --- End original logic adaptation ---

        print("🃏 Dealing new cards. Deck: \(deck.count). Empty slots: \(finalEmptyPositions.count)")
        
        if finalEmptyPositions.isEmpty {
             print("✅ Grid already full. No new cards needed.")
             // Still need to check game over after shifting completes
             checkGameOver()
             onGameOverChecked?()
             onNewCardsDealt?() // Update eligibility even if no cards dealt
             return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.newCardFeedback.impactOccurred() // Use local or injected haptics
            
            var cardsAdded = 0
            for position in finalEmptyPositions {
                if let card = self.deck.popLast() {
                    print("  ➡️ Adding new card \(card.rank)\(card.suit) at row \(position.0), col \(position.1)")
                    // Initialize new cards at their final position
                    self.cardPositions.append(CardPosition(card: card, row: position.0, col: position.1))
                    cardsAdded += 1
                } else {
                    print("🔥 Deck empty! Cannot fill remaining slots.")
                    break
                }
            }
            print("✅ Added \(cardsAdded) new cards. Final count: \(self.cardPositions.count)")
        }
        
        // Update eligible cards and check game over AFTER new cards are added
        onNewCardsDealt?()
        checkGameOver()
        onGameOverChecked?()
    }


    func checkGameOver() {
        // Preserving original logic exactly as requested
        let allCards = cardPositions.map { $0.card }
        print("🔍 Checking for game over. Cards: \(allCards.count), Deck: \(deck.count)")
        
        if deck.isEmpty && cardPositions.count < 25 {
            print("🔍 Deck empty, checking remaining hands...")
            for size in 2...5 {
                let combinations = allCards.combinations(ofCount: size)
                for cards in combinations {
                    if canSelectCards(cards), PokerHandDetector.detectHand(cards: cards) != nil {
                        print("  ✅ Valid hand found among remaining cards. Game NOT over.")
                        self.isGameOver = false
                        return
                    }
                }
            }
            print("  ❌ No valid hands found among remaining cards. GAME OVER.")
            self.isGameOver = true
            return
        }
        
        // Normal check with cards on board
        print("🔍 Checking all possible hands on board...")
        for size in 2...5 {
            let combinations = allCards.combinations(ofCount: size)
             if combinations.isEmpty { continue } // Skip if no combinations of this size
             // print("DEBUG: Checking combinations of size \(size) (\(combinations.count) found)")
            for cards in combinations {
                // Check if selectable AND is a valid hand
                if canSelectCards(cards), PokerHandDetector.detectHand(cards: cards) != nil {
                    print("  ✅ Valid hand possible on board. Game NOT over.")
                    self.isGameOver = false
                    return
                }
            }
        }
        
        // Only declare game over if NO selectable valid hands were found
        print("❌ No selectable valid hands found on board. GAME OVER.")
        self.isGameOver = true
    }
    
    /// Helper for checkGameOver: Determines if a given set of cards *could* be selected based on adjacency.
    /// This replicates the check within the original checkGameOver logic.
    private func canSelectCards(_ cards: [Card]) -> Bool {
        guard !cards.isEmpty else { return false }
        guard cards.count <= 5 else { return false } // Max selection size
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
        var grid = Array(repeating: Array(repeating: Card?.none, count: 5), count: 5)
        for position in cardPositions {
             // Ensure indices are valid before assignment
             if position.currentRow >= 0 && position.currentRow < 5 && position.currentCol >= 0 && position.currentCol < 5 {
                grid[position.currentRow][position.currentCol] = position.card
             } else {
                 print("🔥 Error: Card position out of bounds: row \(position.currentRow), col \(position.currentCol)")
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
 
