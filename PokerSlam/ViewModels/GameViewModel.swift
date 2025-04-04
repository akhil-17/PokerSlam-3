import Foundation
import SwiftUI

/// Represents a card's position in the grid, including its current and target positions
struct CardPosition: Identifiable {
    let id = UUID()
    let card: Card
    var currentRow: Int
    var currentCol: Int
    var targetRow: Int
    var targetCol: Int
    
    init(card: Card, row: Int, col: Int) {
        self.card = card
        self.currentRow = row
        self.currentCol = col
        self.targetRow = row
        self.targetCol = col
    }
}

/// Represents a position in the grid
private struct GridPosition: Hashable {
    let row: Int
    let col: Int
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

extension Array {
    func combinations(ofCount count: Int) -> [[Element]] {
        guard count > 0 && count <= self.count else { return [] }
        
        if count == 1 {
            return self.map { [$0] }
        }
        
        var result: [[Element]] = []
        for i in 0...(self.count - count) {
            let first = self[i]
            let remaining = Array(self[(i + 1)...])
            let subCombinations = remaining.combinations(ofCount: count - 1)
            result.append(contentsOf: subCombinations.map { [first] + $0 })
        }
        return result
    }
}

/// ViewModel responsible for managing the game state and logic
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var cardPositions: [CardPosition] = []
    @Published private(set) var selectedCards: Set<Card> = []
    @Published private(set) var eligibleCards: Set<Card> = []
    @Published private(set) var score: Int = 0
    @Published var isGameOver = false
    @Published private(set) var lastPlayedHand: HandType?
    @Published private(set) var isAnimating = false
    @Published private(set) var currentHandText: String?
    @Published private(set) var isAnimatingHandText = false
    
    private var deck: [Card] = []
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let deselectionFeedback = UIImpactFeedbackGenerator(style: .light)
    private let errorFeedback = UINotificationFeedbackGenerator()
    private let successFeedback = UINotificationFeedbackGenerator()
    private let shiftFeedback = UIImpactFeedbackGenerator(style: .light)
    private let newCardFeedback = UIImpactFeedbackGenerator(style: .soft)
    private var selectedCardPositions: [(row: Int, col: Int)] = []
    
    /// Returns whether cards are currently interactive
    var areCardsInteractive: Bool {
        !isGameOver
    }
    
    init() {
        setupDeck()
        dealInitialCards()
    }
    
    private func setupDeck() {
        deck = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        deck.shuffle()
    }
    
    private func dealInitialCards() {
        cardPositions.removeAll()
        for row in 0..<5 {
            for col in 0..<5 {
                if let card = deck.popLast() {
                    cardPositions.append(CardPosition(card: card, row: row, col: col))
                }
            }
        }
        updateEligibleCards()
    }
    
    /// Gets the card at a specific position in the grid
    private func cardAt(row: Int, col: Int) -> Card? {
        return cardPositions.first { $0.currentRow == row && $0.currentCol == col }?.card
    }
    
    /// Gets all cards in the grid as a 2D array for compatibility with existing code
    private var cards: [[Card?]] {
        var grid = Array(repeating: Array(repeating: Card?.none, count: 5), count: 5)
        for position in cardPositions {
            grid[position.currentRow][position.currentCol] = position.card
        }
        return grid
    }
    
    /// Selects or deselects a card based on adjacency rules
    /// - Parameter card: The card to select or deselect
    func selectCard(_ card: Card) {
        guard areCardsInteractive else { return }
        
        if selectedCards.contains(card) {
            // If only one card is selected, deselect it
            if selectedCards.count == 1 {
                selectedCards.remove(card)
                selectedCardPositions.removeAll()
                deselectionFeedback.impactOccurred()
            } else {
                // If multiple cards are selected, deselect all
                selectedCards.removeAll()
                selectedCardPositions.removeAll()
                deselectionFeedback.impactOccurred()
            }
            updateEligibleCards()
            updateCurrentHandText()
        } else if isCardEligibleForSelection(card) && selectedCards.count < 5 {
            selectedCards.insert(card)
            if let position = findCardPosition(card) {
                selectedCardPositions.append(position)
            }
            selectionFeedback.selectionChanged()
            updateEligibleCards()
            updateCurrentHandText()
        } else if !selectedCards.isEmpty {
            // If tapping an ineligible card with cards selected, unselect all
            unselectAllCards()
        } else {
            // Invalid selection - play error feedback
            errorFeedback.notificationOccurred(.error)
        }
    }
    
    /// Unselects all currently selected cards and resets the selection state
    func unselectAllCards() {
        selectedCards.removeAll()
        selectedCardPositions.removeAll()
        currentHandText = nil
        deselectionFeedback.impactOccurred()
        updateEligibleCards()
    }
    
    private func isCardEligibleForSelection(_ card: Card) -> Bool {
        if selectedCards.isEmpty { return true }
        
        guard let cardPosition = findCardPosition(card) else { return false }
        
        // Check if the card is adjacent to any of the currently selected cards
        for position in selectedCardPositions {
            if isAdjacent(position1: cardPosition, position2: position) {
                return true
            }
        }
        
        return false
    }
    
    private func isAdjacent(position1: (row: Int, col: Int), position2: (row: Int, col: Int)) -> Bool {
        let rowDiff = abs(position1.row - position2.row)
        let colDiff = abs(position1.col - position2.col)
        
        // If cards are in the same column, they're adjacent if they're one row apart
        if position1.col == position2.col {
            return rowDiff <= 1
        }
        
        // If cards are in adjacent columns (no empty columns between them)
        if colDiff == 1 {
            // Check if there are any cards in the columns between these positions
            let minCol = min(position1.col, position2.col)
            let maxCol = max(position1.col, position2.col)
            
            // For each column between the cards, check if it has any cards
            for col in (minCol + 1)..<maxCol {
                if !cardPositions.contains(where: { $0.currentCol == col }) {
                    return false
                }
            }
            
            // If no empty columns between them, they're adjacent if they're one row apart
            return rowDiff <= 1
        }
        
        // If cards are not in adjacent columns, they're not adjacent
        return false
    }
    
    private func updateEligibleCards() {
        eligibleCards.removeAll()
        
        if selectedCards.isEmpty {
            // If no cards are selected, all cards are eligible
            for position in cardPositions {
                eligibleCards.insert(position.card)
            }
            return
        }
        
        // Find all cards adjacent to any selected card
        for position in cardPositions {
            if isCardEligibleForSelection(position.card) {
                eligibleCards.insert(position.card)
            }
        }
        
        // Remove any selected cards from eligible cards
        eligibleCards.subtract(selectedCards)
    }
    
    private func findCardPosition(_ card: Card) -> (row: Int, col: Int)? {
        return cardPositions.first { $0.card.id == card.id }
            .map { ($0.currentRow, $0.currentCol) }
    }
    
    private func updateCurrentHandText() {
        guard !selectedCards.isEmpty else {
            currentHandText = nil
            return
        }
        
        let selectedCardsArray = Array(selectedCards)
        if let handType = PokerHandDetector.detectHand(cards: selectedCardsArray) {
            currentHandText = "\(handType.displayName) +\(handType.rawValue)"
        } else {
            currentHandText = nil
        }
    }
    
    /// Plays the currently selected hand and updates the game state
    func playHand() {
        let selectedCardsArray = Array(selectedCards)
        
        // Detect the poker hand
        if let handType = PokerHandDetector.detectHand(cards: selectedCardsArray) {
            lastPlayedHand = handType
            score += handType.rawValue
            successFeedback.notificationOccurred(.success)
            
            // Animate the hand text before proceeding
            isAnimatingHandText = true
            currentHandText = "\(handType.displayName) +\(handType.rawValue)"
            
            // Clear selection state immediately to prevent button from reappearing
            selectedCards.removeAll()
            selectedCardPositions.removeAll()
            
            // Get positions of selected cards
            let emptyPositions = selectedCardsArray.compactMap { card in
                cardPositions.first { $0.card.id == card.id }
                    .map { ($0.currentRow, $0.currentCol) }
            }
            
            print("🔍 Debug: Selected cards positions to remove: \(emptyPositions)")
            
            // Remove selected cards
            cardPositions.removeAll { position in
                selectedCardsArray.contains(position.card)
            }
            
            print("🔍 Debug: Remaining cards after removal: \(cardPositions.count)")
            
            // First, shift existing cards down
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7), ({
                shiftFeedback.impactOccurred()
                
                // For each column, handle card shifting independently
                for col in 0..<5 {
                    // Get all cards in this column, sorted from bottom to top
                    let columnCards = cardPositions.filter { $0.currentCol == col }
                        .sorted { $0.currentRow > $1.currentRow }
                    
                    // Get empty positions in this column
                    let columnEmptyPositions = emptyPositions.filter { $0.1 == col }
                        .map { $0.0 }
                        .sorted()
                    
                    if !columnEmptyPositions.isEmpty {
                        print("🔍 Debug: Processing column \(col) with \(columnCards.count) cards and \(columnEmptyPositions.count) empty positions")
                        
                        // Skip processing if column is empty
                        guard !columnCards.isEmpty else {
                            print("🔍 Debug: Column \(col) is empty, skipping processing")
                            continue
                        }
                        
                        // Calculate the total number of empty positions below each card
                        var emptyPositionsBelow: [UUID: Int] = [:]
                        for cardPosition in columnCards {
                            let emptyCount = columnEmptyPositions.filter { $0 > cardPosition.currentRow }.count
                            emptyPositionsBelow[cardPosition.id] = emptyCount
                        }
                        
                        // Shift cards down based on empty positions below them
                        for cardPosition in columnCards {
                            if let cardIndex = cardPositions.firstIndex(where: { $0.id == cardPosition.id }),
                               let emptyCount = emptyPositionsBelow[cardPosition.id],
                               emptyCount > 0 {
                                let newRow = cardPosition.currentRow + emptyCount
                                print("🔍 Debug: Shifting card in column \(col) from row \(cardPosition.currentRow) to \(newRow)")
                                cardPositions[cardIndex].targetRow = newRow
                            }
                        }
                        
                        // After shifting, verify no gaps remain in this column
                        let columnCardsAfterShift = cardPositions.filter { $0.currentCol == col }
                            .sorted { $0.currentRow > $1.currentRow }
                        
                        // Only check for gaps if we have at least 2 cards
                        if columnCardsAfterShift.count >= 2 {
                            // Check for gaps between cards
                            for i in 0..<(columnCardsAfterShift.count - 1) {
                                let currentRow = columnCardsAfterShift[i].currentRow
                                let nextRow = columnCardsAfterShift[i + 1].currentRow
                                if nextRow - currentRow > 1 {
                                    print("🔍 Debug: Found gap in column \(col) between rows \(currentRow) and \(nextRow)")
                                    // Shift all cards above the gap down
                                    for j in (i + 1)..<columnCardsAfterShift.count {
                                        if let cardIndex = cardPositions.firstIndex(where: { $0.id == columnCardsAfterShift[j].id }) {
                                            let shiftAmount = nextRow - currentRow - 1
                                            let newRow = columnCardsAfterShift[j].currentRow - shiftAmount
                                            print("🔍 Debug: Shifting card in column \(col) from row \(columnCardsAfterShift[j].currentRow) to \(newRow)")
                                            cardPositions[cardIndex].targetRow = newRow
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Update current positions to match target positions
                for index in cardPositions.indices {
                    cardPositions[index].currentRow = cardPositions[index].targetRow
                    cardPositions[index].currentCol = cardPositions[index].targetCol
                }
                
                // Verify grid is complete
                let expectedCardCount = 25
                if cardPositions.count != expectedCardCount {
                    print("🔍 Debug: Grid incomplete after shifting. Expected \(expectedCardCount) cards, got \(cardPositions.count)")
                }
            }))
            
            // Calculate new empty positions at the top of each column
            var newEmptyPositions: [(Int, Int)] = []
            
            // Get all current positions that have cards
            let currentPositions = Set(cardPositions.map { GridPosition(row: $0.currentRow, col: $0.currentCol) })
            
            // For each column, find empty positions from bottom to top
            for col in 0..<5 {
                // First, find empty positions from bottom to top (excluding row 0)
                for row in (1..<5).reversed() {
                    if !currentPositions.contains(GridPosition(row: row, col: col)) {
                        newEmptyPositions.append((row, col))
                    }
                }
                
                // If row 0 is empty, add it last
                if !currentPositions.contains(GridPosition(row: 0, col: col)) {
                    newEmptyPositions.append((0, col))
                }
            }
            
            // Sort empty positions by column then row to ensure consistent filling
            newEmptyPositions.sort { (pos1, pos2) in
                if pos1.1 == pos2.1 {
                    return pos1.0 > pos2.0  // Sort rows in descending order (bottom to top)
                }
                return pos1.1 < pos2.1
            }
            
            // Then, after animation completes, add new cards to the new empty positions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7), ({
                    self.newCardFeedback.impactOccurred()
                    print("🔍 Debug: Starting to add new cards")
                    print("🔍 Debug: Remaining cards in deck: \(self.deck.count)")
                    print("🔍 Debug: New empty positions: \(newEmptyPositions)")
                    
                    // Add new cards from the deck to the empty positions at the top
                    for position in newEmptyPositions {
                        if let card = self.deck.popLast() {
                            print("🔍 Debug: Adding new card at row \(position.0), col \(position.1)")
                            self.cardPositions.append(CardPosition(card: card, row: position.0, col: position.1))
                        } else {
                            print("🔍 Debug: No more cards in deck to add")
                            break
                        }
                    }
                    
                    print("🔍 Debug: Final card count: \(self.cardPositions.count)")
                    
                    // Update eligible cards after adding new cards
                    self.updateEligibleCards()
                    
                    // Check if game is over after all cards are in place
                    self.checkGameOver()
                }))
            }
            
            // Reset animation state and clear hand text after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isAnimatingHandText = false
                    self.currentHandText = nil
                }
                self.updateEligibleCards()
            }
        } else {
            lastPlayedHand = nil
            errorFeedback.notificationOccurred(.error)
        }
    }
    
    private func checkGameOver() {
        // Check if there are any valid poker hands possible in the current grid
        let allCards = cardPositions.map { $0.card }
        print("🔍 Debug: Checking for valid poker hands with \(allCards.count) cards")
        
        // If we have no cards in the deck and less than 25 cards in the grid,
        // we should check if any valid hands are possible with the remaining cards
        if deck.isEmpty && cardPositions.count < 25 {
            print("🔍 Debug: No more cards in deck, checking remaining cards for valid hands")
            
            // Check all possible combinations of 2-5 cards
            for size in 2...5 {
                let combinations = allCards.combinations(ofCount: size)
                print("🔍 Debug: Checking combinations of size \(size), found \(combinations.count) combinations")
                
                for cards in combinations {
                    // First check if these cards can be selected according to adjacency rules
                    var canBeSelected = true
                    var selectedPositions: [(row: Int, col: Int)] = []
                    
                    // Try to select the first card
                    if let firstPosition = findCardPosition(cards[0]) {
                        selectedPositions.append(firstPosition)
                        
                        // Try to select each subsequent card
                        for i in 1..<cards.count {
                            if let position = findCardPosition(cards[i]) {
                                // Check if this card is adjacent to any already selected card
                                var isAdjacentToAny = false
                                for selectedPosition in selectedPositions {
                                    if isAdjacent(position1: position, position2: selectedPosition) {
                                        isAdjacentToAny = true
                                        break
                                    }
                                }
                                
                                if isAdjacentToAny {
                                    selectedPositions.append(position)
                                } else {
                                    canBeSelected = false
                                    break
                                }
                            }
                        }
                    }
                    
                    // If we can select all cards and they form a valid hand, game is not over
                    if canBeSelected, let handType = PokerHandDetector.detectHand(cards: cards) {
                        print("🔍 Debug: Found valid hand: \(handType.displayName)")
                        isGameOver = false
                        return
                    }
                }
            }
            
            print("🔍 Debug: No valid poker hands found with remaining cards, game is over")
            isGameOver = true
            return
        }
        
        // Normal case: check all possible combinations
        for size in 2...5 {
            let combinations = allCards.combinations(ofCount: size)
            print("🔍 Debug: Checking combinations of size \(size), found \(combinations.count) combinations")
            
            for cards in combinations {
                // First check if these cards can be selected according to adjacency rules
                var canBeSelected = true
                var selectedPositions: [(row: Int, col: Int)] = []
                
                // Try to select the first card
                if let firstPosition = findCardPosition(cards[0]) {
                    selectedPositions.append(firstPosition)
                    
                    // Try to select each subsequent card
                    for i in 1..<cards.count {
                        if let position = findCardPosition(cards[i]) {
                            // Check if this card is adjacent to any already selected card
                            var isAdjacentToAny = false
                            for selectedPosition in selectedPositions {
                                if isAdjacent(position1: position, position2: selectedPosition) {
                                    isAdjacentToAny = true
                                    break
                                }
                            }
                            
                            if isAdjacentToAny {
                                selectedPositions.append(position)
                            } else {
                                canBeSelected = false
                                break
                            }
                        }
                    }
                }
                
                // If we can select all cards and they form a valid hand, game is not over
                if canBeSelected, let handType = PokerHandDetector.detectHand(cards: cards) {
                    print("🔍 Debug: Found valid hand: \(handType.displayName)")
                    isGameOver = false
                    return
                }
            }
        }
        
        print("🔍 Debug: No valid poker hands found, game is over")
        isGameOver = true
    }
    
    /// Resets the game to its initial state
    func resetGame() {
        cardPositions.removeAll()
        selectedCards.removeAll()
        eligibleCards.removeAll()
        score = 0
        isGameOver = false
        lastPlayedHand = nil
        setupDeck()
        dealInitialCards()
    }
}
