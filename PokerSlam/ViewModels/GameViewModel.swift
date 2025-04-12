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

/// Represents a node in the connection graph
private struct ConnectionNode: Hashable {
    let cardId: UUID
    let position: (row: Int, col: Int)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cardId)
    }
    
    static func == (lhs: ConnectionNode, rhs: ConnectionNode) -> Bool {
        return lhs.cardId == rhs.cardId
    }
}

/// Represents an edge in the connection graph
private struct ConnectionEdge: Hashable {
    let from: ConnectionNode
    let to: ConnectionNode
    let weight: Int // Lower weight means higher priority (straight connections have lower weight)
    let isStraight: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(from.cardId)
        hasher.combine(to.cardId)
    }
    
    static func == (lhs: ConnectionEdge, rhs: ConnectionEdge) -> Bool {
        return lhs.from.cardId == rhs.from.cardId && lhs.to.cardId == rhs.to.cardId
    }
}

/// Represents a graph of possible connections between cards
private struct ConnectionGraph {
    var nodes: Set<ConnectionNode>
    var edges: Set<ConnectionEdge>
    
    init(nodes: Set<ConnectionNode>, edges: Set<ConnectionEdge>) {
        self.nodes = nodes
        self.edges = edges
    }
    
    /// Finds the minimum spanning tree that minimizes diagonal connections
    func findMinimumSpanningTree() -> Set<ConnectionEdge> {
        // Use Kruskal's algorithm to find the minimum spanning tree
        var result: Set<ConnectionEdge> = []
        var parent: [UUID: UUID] = [:]
        var rank: [UUID: Int] = [:]
        
        // Initialize the disjoint set
        for node in nodes {
            parent[node.cardId] = node.cardId
            rank[node.cardId] = 0
        }
        
        // Sort edges by weight (straight connections first)
        let sortedEdges = edges.sorted { $0.weight < $1.weight }
        
        // Process each edge
        for edge in sortedEdges {
            let fromId = edge.from.cardId
            let toId = edge.to.cardId
            
            // Find the root of the sets containing from and to
            let fromRoot = findRoot(of: fromId, in: &parent)
            let toRoot = findRoot(of: toId, in: &parent)
            
            // If they're in different sets, add the edge and union the sets
            if fromRoot != toRoot {
                result.insert(edge)
                union(fromRoot, toRoot, in: &parent, rank: &rank)
            }
        }
        
        return result
    }
    
    /// Finds the root of the set containing the given node
    private func findRoot(of nodeId: UUID, in parent: inout [UUID: UUID]) -> UUID {
        if parent[nodeId] == nodeId {
            return nodeId
        }
        
        // Path compression
        parent[nodeId] = findRoot(of: parent[nodeId]!, in: &parent)
        return parent[nodeId]!
    }
    
    /// Unions two sets
    private func union(_ x: UUID, _ y: UUID, in parent: inout [UUID: UUID], rank: inout [UUID: Int]) {
        let xRoot = findRoot(of: x, in: &parent)
        let yRoot = findRoot(of: y, in: &parent)
        
        if xRoot == yRoot {
            return
        }
        
        // Union by rank
        if rank[xRoot]! < rank[yRoot]! {
            parent[xRoot] = yRoot
        } else if rank[xRoot]! > rank[yRoot]! {
            parent[yRoot] = xRoot
        } else {
            parent[yRoot] = xRoot
            rank[xRoot]! += 1
        }
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
    @Published private(set) var connections: [Connection] = []
    @Published private(set) var isErrorState = false
    @Published private(set) var errorAnimationTimestamp: Date?
    @Published private(set) var isSuccessState = false
    @Published private(set) var isResetting = false
    
    // Track the order in which cards were selected
    private var selectionOrder: [Card] = []
    
    private var deck: [Card] = []
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let deselectionFeedback = UIImpactFeedbackGenerator(style: .light)
    private let errorFeedback = UINotificationFeedbackGenerator()
    private let successFeedback = UINotificationFeedbackGenerator()
    private let shiftFeedback = UIImpactFeedbackGenerator(style: .light)
    private let newCardFeedback = UIImpactFeedbackGenerator(style: .soft)
    private let resetGameFeedback = UINotificationFeedbackGenerator()
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
                selectionOrder.removeAll()
                deselectionFeedback.impactOccurred()
            } else {
                // If multiple cards are selected, deselect all
                selectedCards.removeAll()
                selectedCardPositions.removeAll()
                selectionOrder.removeAll()
                deselectionFeedback.impactOccurred()
            }
            updateEligibleCards()
            updateCurrentHandText()
            updateConnections()
        } else if isCardEligibleForSelection(card) && selectedCards.count < 5 {
            selectedCards.insert(card)
            if let position = findCardPosition(card) {
                selectedCardPositions.append(position)
            }
            // Add the card to the selection order
            selectionOrder.append(card)
            selectionFeedback.selectionChanged()
            updateEligibleCards()
            updateCurrentHandText()
            updateConnections()
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
        selectionOrder.removeAll()
        currentHandText = nil
        deselectionFeedback.impactOccurred()
        updateEligibleCards()
        updateConnections()
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
        
        // If 5 cards are already selected, no other cards should be eligible
        if selectedCards.count >= 5 {
            return
        }
        
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
    
    /// Updates the connections between selected cards
    private func updateConnections() {
        connections.removeAll()
        
        // If we have less than 2 cards selected, no connections needed
        guard selectionOrder.count >= 2 else { return }
        
        // Create a map of card positions for quick lookup
        var cardPositionMap: [UUID: (row: Int, col: Int)] = [:]
        for position in cardPositions {
            cardPositionMap[position.card.id] = (position.currentRow, position.currentCol)
        }
        
        // Create a set of all selected card IDs for quick lookup
        let selectedCardIds = Set(selectedCards.map { $0.id })
        
        // Create the connection graph
        let graph = createConnectionGraph(
            cardPositionMap: cardPositionMap,
            selectedCardIds: selectedCardIds
        )
        
        // Find the minimum spanning tree that minimizes diagonal connections
        let optimalConnections = graph.findMinimumSpanningTree()
        
        // Add the optimal connections
        for edge in optimalConnections {
            let fromCard = selectionOrder.first { $0.id == edge.from.cardId }!
            let toCard = selectionOrder.first { $0.id == edge.to.cardId }!
            
            // Determine anchor points for the connection
            let (fromAnchor, toAnchor) = determineAnchorPoints(
                from: edge.from.position,
                to: edge.to.position
            )
            
            // Add the connection
            connections.append(Connection(
                fromCard: fromCard,
                toCard: toCard,
                fromPosition: fromAnchor,
                toPosition: toAnchor
            ))
        }
        
        // Replace diagonal connections with straight paths where possible
        replaceDiagonalWithStraightPaths(
            cardPositionMap: cardPositionMap,
            selectedCardIds: selectedCardIds
        )
        
        // Validate that all cards have at least one connection
        validateAllCardsConnected(
            cardPositionMap: cardPositionMap,
            selectedCardIds: selectedCardIds
        )
    }
    
    /// Creates a graph of possible connections between selected cards
    private func createConnectionGraph(
        cardPositionMap: [UUID: (row: Int, col: Int)],
        selectedCardIds: Set<UUID>
    ) -> ConnectionGraph {
        var nodes: Set<ConnectionNode> = []
        var edges: Set<ConnectionEdge> = []
        
        // Create nodes for each selected card
        for card in selectionOrder {
            guard let position = cardPositionMap[card.id] else { continue }
            nodes.insert(ConnectionNode(cardId: card.id, position: position))
        }
        
        // Create edges for all possible connections
        for i in 0..<selectionOrder.count {
            let fromCard = selectionOrder[i]
            guard let fromPosition = cardPositionMap[fromCard.id] else { continue }
            let fromNode = ConnectionNode(cardId: fromCard.id, position: fromPosition)
            
            for j in (i+1)..<selectionOrder.count {
                let toCard = selectionOrder[j]
                guard let toPosition = cardPositionMap[toCard.id] else { continue }
                let toNode = ConnectionNode(cardId: toCard.id, position: toPosition)
                
                // Check if cards are adjacent
                if isAdjacent(position1: fromPosition, position2: toPosition) {
                    // Determine if this is a straight connection
                    let isStraight = isStraightConnection(from: fromPosition, to: toPosition)
                    
                    // Create the edge with appropriate weight (straight connections have lower weight)
                    let weight = isStraight ? 0 : 1
                    edges.insert(ConnectionEdge(
                        from: fromNode,
                        to: toNode,
                        weight: weight,
                        isStraight: isStraight
                    ))
                }
            }
        }
        
        return ConnectionGraph(nodes: nodes, edges: edges)
    }
    
    /// Replaces diagonal connections with straight paths where possible
    private func replaceDiagonalWithStraightPaths(
        cardPositionMap: [UUID: (row: Int, col: Int)],
        selectedCardIds: Set<UUID>
    ) {
        // Find all diagonal connections
        var diagonalConnections: [(connection: Connection, fromPos: (row: Int, col: Int), toPos: (row: Int, col: Int))] = []
        
        for connection in connections {
            guard let fromPos = cardPositionMap[connection.fromCard.id],
                  let toPos = cardPositionMap[connection.toCard.id] else {
                continue
            }
            
            let isStraight = isStraightConnection(from: fromPos, to: toPos)
            if !isStraight {
                diagonalConnections.append((connection: connection, fromPos: fromPos, toPos: toPos))
            }
        }
        
        // For each diagonal connection, check if a straight path is possible
        for diagonalConnection in diagonalConnections {
            let fromCard = diagonalConnection.connection.fromCard
            let toCard = diagonalConnection.connection.toCard
            let fromPos = diagonalConnection.fromPos
            let toPos = diagonalConnection.toPos
            
            // Check if there's a card in the same row or column that could form a straight path
            let possibleIntermediateCards = selectionOrder.filter { card in
                guard let pos = cardPositionMap[card.id],
                      card.id != fromCard.id && card.id != toCard.id else {
                    return false
                }
                
                // Check if the card is in the same row or column as either the from or to card
                let inSameRowAsFrom = pos.row == fromPos.row
                let inSameColAsFrom = pos.col == fromPos.col
                let inSameRowAsTo = pos.row == toPos.row
                let inSameColAsTo = pos.col == toPos.col
                
                // Check if the card is adjacent to both the from and to cards
                let adjacentToFrom = isAdjacent(position1: fromPos, position2: pos)
                let adjacentToTo = isAdjacent(position1: toPos, position2: pos)
                
                return (inSameRowAsFrom || inSameColAsFrom || inSameRowAsTo || inSameColAsTo) &&
                       adjacentToFrom && adjacentToTo
            }
            
            // If we found possible intermediate cards, replace the diagonal connection with straight ones
            if !possibleIntermediateCards.isEmpty {
                // Choose the best intermediate card (prefer one that forms straight connections)
                let bestIntermediateCard = possibleIntermediateCards.first!
                guard let intermediatePos = cardPositionMap[bestIntermediateCard.id] else { continue }
                
                // Remove the diagonal connection
                connections.removeAll { $0.id == diagonalConnection.connection.id }
                
                // Add two straight connections
                let (fromAnchor1, toAnchor1) = determineAnchorPoints(
                    from: fromPos,
                    to: intermediatePos
                )
                
                let (fromAnchor2, toAnchor2) = determineAnchorPoints(
                    from: intermediatePos,
                    to: toPos
                )
                
                connections.append(Connection(
                    fromCard: fromCard,
                    toCard: bestIntermediateCard,
                    fromPosition: fromAnchor1,
                    toPosition: toAnchor1
                ))
                
                connections.append(Connection(
                    fromCard: bestIntermediateCard,
                    toCard: toCard,
                    fromPosition: fromAnchor2,
                    toPosition: toAnchor2
                ))
            }
        }
    }
    
    /// Validates that all selected cards have at least one connection
    private func validateAllCardsConnected(
        cardPositionMap: [UUID: (row: Int, col: Int)],
        selectedCardIds: Set<UUID>
    ) {
        // Count how many connections each card has
        var connectionCounts: [UUID: Int] = [:]
        for cardId in selectedCardIds {
            connectionCounts[cardId] = 0
        }
        
        for connection in connections {
            connectionCounts[connection.fromCard.id] = (connectionCounts[connection.fromCard.id] ?? 0) + 1
            connectionCounts[connection.toCard.id] = (connectionCounts[connection.toCard.id] ?? 0) + 1
        }
        
        // Find cards that don't have any connections
        let unconnectedCards = selectionOrder.filter { connectionCounts[$0.id] ?? 0 == 0 }
        
        // For each unconnected card, find the best card to connect to
        for card in unconnectedCards {
            guard let cardPos = cardPositionMap[card.id] else { continue }
            
            // Find all adjacent selected cards
            var possibleConnections: [(card: Card, isStraight: Bool)] = []
            
            for otherCard in selectionOrder {
                let otherCardId = otherCard.id
                
                // Skip if it's the same card
                if otherCardId == card.id {
                    continue
                }
                
                guard let otherPos = cardPositionMap[otherCardId] else { continue }
                
                // Check if cards are adjacent
                if isAdjacent(position1: cardPos, position2: otherPos) {
                    // Determine if this is a straight connection
                    let isStraight = isStraightConnection(from: cardPos, to: otherPos)
                    
                    possibleConnections.append((card: otherCard, isStraight: isStraight))
                }
            }
            
            // If we found possible connections, choose the best one
            if !possibleConnections.isEmpty {
                // Prioritize straight connections over diagonal ones
                let sortedConnections = possibleConnections.sorted { $0.isStraight && !$1.isStraight }
                
                if let bestConnection = sortedConnections.first {
                    let bestCard = bestConnection.card
                    guard let bestPos = cardPositionMap[bestCard.id] else { continue }
                    
                    // Determine anchor points for the connection
                    let (fromAnchor, toAnchor) = determineAnchorPoints(
                        from: cardPos,
                        to: bestPos
                    )
                    
                    // Add the connection
                    connections.append(Connection(
                        fromCard: card,
                        toCard: bestCard,
                        fromPosition: fromAnchor,
                        toPosition: toAnchor
                    ))
                }
            }
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
            
            // Set success state before animations
            print("🎮 Setting success state to true")
            isSuccessState = true
            
            // Animate the hand text before proceeding
            isAnimatingHandText = true
            currentHandText = "\(handType.displayName) +\(handType.rawValue)"
            
            // Clear selection state immediately to prevent the button from reappearing
            selectedCards.removeAll()
            selectedCardPositions.removeAll()
            selectionOrder.removeAll()
            connections.removeAll()
            
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
            
            // Reset success state after the animation sequence completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🎮 Setting success state to false")
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isSuccessState = false
                    self.isAnimatingHandText = false
                    self.currentHandText = nil
                }
                self.updateEligibleCards()
            }
        } else {
            lastPlayedHand = nil
            errorFeedback.notificationOccurred(.error)
            
            // Set error state to trigger animation
            isErrorState = true
            errorAnimationTimestamp = Date()
            
            // Reset error state after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.isErrorState = false
                self.errorAnimationTimestamp = nil
            }
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
        isResetting = true
        resetGameFeedback.notificationOccurred(.success)
        cardPositions.removeAll()
        selectedCards.removeAll()
        eligibleCards.removeAll()
        selectionOrder.removeAll()
        connections.removeAll()
        score = 0
        isGameOver = false
        lastPlayedHand = nil
        isErrorState = false
        errorAnimationTimestamp = nil
        isSuccessState = false
        setupDeck()
        dealInitialCards()

        // Reset animation state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isResetting = false
        }
    }
    
    /// Determines the appropriate anchor points for connecting two cards
    private func determineAnchorPoints(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int)
    ) -> (AnchorPoint.Position, AnchorPoint.Position) {
        // Same column
        if from.col == to.col {
            return from.row < to.row ? 
                (.bottom, .top) : 
                (.top, .bottom)
        }
        
        // Same row
        if from.row == to.row {
            return from.col < to.col ? 
                (.right, .left) : 
                (.left, .right)
        }
        
        // Diagonal
        let isDiagonalUp = from.row > to.row
        let isDiagonalRight = from.col < to.col
        
        return (
            isDiagonalUp ? 
                (isDiagonalRight ? .topRight : .topLeft) : 
                (isDiagonalRight ? .bottomRight : .bottomLeft),
            isDiagonalUp ? 
                (isDiagonalRight ? .bottomLeft : .bottomRight) : 
                (isDiagonalRight ? .topLeft : .topRight)
        )
    }
    
    /// Determines if a connection between two positions is straight (same row or column) or diagonal
    private func isStraightConnection(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int)
    ) -> Bool {
        return from.row == to.row || from.col == to.col
    }
}
