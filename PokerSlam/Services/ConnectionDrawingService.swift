import Foundation
import SwiftUI // For @MainActor, @Published, AnchorPoint

// MARK: - Helper Structs (Internal to this Service)

private struct GridPosition: Hashable { // Also used by GameStateManager, consider moving to Models?
    let row: Int
    let col: Int
}

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

private struct ConnectionGraph {
    var nodes: Set<ConnectionNode>
    var edges: Set<ConnectionEdge>

    /// Finds the minimum spanning tree that minimizes diagonal connections using Kruskal's algorithm.
    func findMinimumSpanningTree() -> Set<ConnectionEdge> {
        var result: Set<ConnectionEdge> = []
        var parent: [UUID: UUID] = [:]
        var rank: [UUID: Int] = [:]

        for node in nodes {
            parent[node.cardId] = node.cardId
            rank[node.cardId] = 0
        }

        let sortedEdges = edges.sorted { $0.weight < $1.weight }

        for edge in sortedEdges {
            let fromRoot = findRoot(of: edge.from.cardId, in: &parent)
            let toRoot = findRoot(of: edge.to.cardId, in: &parent)

            if fromRoot != toRoot {
                result.insert(edge)
                union(fromRoot, toRoot, in: &parent, rank: &rank)
            }
        }
        return result
    }

    private func findRoot(of nodeId: UUID, in parent: inout [UUID: UUID]) -> UUID {
        guard parent[nodeId] != nil else { return nodeId } // Avoid force unwrap if node somehow not in parent
        if parent[nodeId] == nodeId {
            return nodeId
        }
        parent[nodeId] = findRoot(of: parent[nodeId]!, in: &parent)
        return parent[nodeId]!
    }

    private func union(_ x: UUID, _ y: UUID, in parent: inout [UUID: UUID], rank: inout [UUID: Int]) {
        let xRoot = findRoot(of: x, in: &parent)
        let yRoot = findRoot(of: y, in: &parent)

        if xRoot == yRoot { return }

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

// MARK: - Connection Drawing Service

@MainActor
final class ConnectionDrawingService: ObservableObject {
    @Published private(set) var connections: [Connection] = []

    // Dependencies
    private let gameStateManager: GameStateManager
    private let cardSelectionManager: CardSelectionManager

    init(gameStateManager: GameStateManager, cardSelectionManager: CardSelectionManager) {
        self.gameStateManager = gameStateManager
        self.cardSelectionManager = cardSelectionManager
    }

    // MARK: - Connection Update Logic

    func updateConnections() {
        let selectionOrder = cardSelectionManager.selectionOrder
        let selectedCards = cardSelectionManager.selectedCards
        let cardPositions = gameStateManager.cardPositions

        connections.removeAll()

        guard selectionOrder.count >= 2 else { return }

        // Create map for quick lookup
        var cardPositionMap: [UUID: (row: Int, col: Int)] = [:]
        for position in cardPositions {
            cardPositionMap[position.card.id] = (position.currentRow, position.currentCol)
        }

        let selectedCardIds = Set(selectedCards.map { $0.id })

        // Ensure all selected cards have positions before proceeding
        guard selectedCards.allSatisfy({ cardPositionMap[$0.id] != nil }) else {
             assertionFailure("ConnectionDrawingService: Not all selected cards have positions in the map.")
             return
        }

        let graph = createConnectionGraph(
            selectionOrder: selectionOrder,
            cardPositionMap: cardPositionMap,
            selectedCardIds: selectedCardIds
        )

        let optimalConnections = graph.findMinimumSpanningTree()

        // Add optimal connections (MST edges)
        for edge in optimalConnections {
            guard let fromCard = selectionOrder.first(where: { $0.id == edge.from.cardId }),
                  let toCard = selectionOrder.first(where: { $0.id == edge.to.cardId }) else { continue }
            
            let (fromAnchor, toAnchor) = determineAnchorPoints(from: edge.from.position, to: edge.to.position)
            connections.append(Connection(fromCard: fromCard, toCard: toCard, fromPosition: fromAnchor, toPosition: toAnchor))
        }

        // Post-processing (kept from original logic)
        replaceDiagonalWithStraightPaths(selectionOrder: selectionOrder, cardPositionMap: cardPositionMap)
        validateAllCardsConnected(selectionOrder: selectionOrder, cardPositionMap: cardPositionMap, selectedCardIds: selectedCardIds)
        
        // print("🔗 Connections updated. Count: \(connections.count)") // Removed
    }

    func resetConnections() {
        // print("🔄 Resetting Connections...") // Removed
        connections.removeAll()
    }

    // MARK: - Private Connection Helpers (Moved from GameViewModel)

    private func createConnectionGraph(
        selectionOrder: [Card],
        cardPositionMap: [UUID: (row: Int, col: Int)],
        selectedCardIds: Set<UUID>
    ) -> ConnectionGraph {
        var nodes: Set<ConnectionNode> = []
        var edges: Set<ConnectionEdge> = []

        for card in selectionOrder {
            guard let position = cardPositionMap[card.id] else { continue }
            nodes.insert(ConnectionNode(cardId: card.id, position: position))
        }

        let selectionArray = selectionOrder // Use the ordered array
        for i in 0..<selectionArray.count {
            let fromCard = selectionArray[i]
            guard let fromPosition = cardPositionMap[fromCard.id] else { continue }
            let fromNode = ConnectionNode(cardId: fromCard.id, position: fromPosition)

            for j in (i + 1)..<selectionArray.count {
                let toCard = selectionArray[j]
                guard let toPosition = cardPositionMap[toCard.id] else { continue }
                let toNode = ConnectionNode(cardId: toCard.id, position: toPosition)

                // Use GameStateManager's adjacency check
                if gameStateManager.isAdjacent(position1: fromPosition, position2: toPosition) {
                    let isStraight = isStraightConnection(from: fromPosition, to: toPosition)
                    let weight = isStraight ? 0 : 1
                    edges.insert(ConnectionEdge(from: fromNode, to: toNode, weight: weight, isStraight: isStraight))
                }
            }
        }
        return ConnectionGraph(nodes: nodes, edges: edges)
    }

    private func replaceDiagonalWithStraightPaths(
        selectionOrder: [Card],
        cardPositionMap: [UUID: (row: Int, col: Int)]
    ) {
        var diagonalConnectionsIndicesToRemove: [Int] = []
        var connectionsToAdd: [Connection] = []

        for (index, connection) in connections.enumerated() {
            guard let fromPos = cardPositionMap[connection.fromCard.id],
                  let toPos = cardPositionMap[connection.toCard.id],
                  !isStraightConnection(from: fromPos, to: toPos) else {
                continue // Skip straight connections
            }

            let fromCard = connection.fromCard
            let toCard = connection.toCard

            // Find intermediate cards that are adjacent to BOTH ends of the diagonal
            let possibleIntermediateCards = selectionOrder.filter { intermediateCard in
                guard intermediateCard.id != fromCard.id && intermediateCard.id != toCard.id,
                      let intermediatePos = cardPositionMap[intermediateCard.id] else {
                    return false
                }
                // Check adjacency using GameStateManager's method
                return gameStateManager.isAdjacent(position1: fromPos, position2: intermediatePos) &&
                       gameStateManager.isAdjacent(position1: toPos, position2: intermediatePos)
            }

            if let bestIntermediateCard = possibleIntermediateCards.first { // Simplification: Just take the first found
                 guard let intermediatePos = cardPositionMap[bestIntermediateCard.id] else { continue }
                 
                 // Mark original diagonal for removal
                 diagonalConnectionsIndicesToRemove.append(index)
                 
                 // Create two new straight connections
                 let (anchor1a, anchor1b) = determineAnchorPoints(from: fromPos, to: intermediatePos)
                 let (anchor2a, anchor2b) = determineAnchorPoints(from: intermediatePos, to: toPos)
                 
                 connectionsToAdd.append(Connection(fromCard: fromCard, toCard: bestIntermediateCard, fromPosition: anchor1a, toPosition: anchor1b))
                 connectionsToAdd.append(Connection(fromCard: bestIntermediateCard, toCard: toCard, fromPosition: anchor2a, toPosition: anchor2b))
                 
                 // Optimization: Break if we replaced this diagonal? Or allow multiple replacements?
                 // Original logic implies only one replacement per diagonal was likely intended.
                 break // Assuming we only replace a diagonal once
            }
        }
        
        // Apply changes (remove marked diagonals, add new straights)
        // Remove in reverse order to preserve indices
        for index in diagonalConnectionsIndicesToRemove.sorted().reversed() {
            connections.remove(at: index)
        }
        connections.append(contentsOf: connectionsToAdd)
    }

    private func validateAllCardsConnected(
        selectionOrder: [Card],
        cardPositionMap: [UUID: (row: Int, col: Int)],
        selectedCardIds: Set<UUID>
    ) {
        var connectionCounts: [UUID: Int] = Dictionary(uniqueKeysWithValues: selectedCardIds.map { ($0, 0) })
        for connection in connections {
            connectionCounts[connection.fromCard.id]? += 1
            connectionCounts[connection.toCard.id]? += 1
        }

        let unconnectedCards = selectionOrder.filter { connectionCounts[$0.id] ?? 0 == 0 }
        guard !unconnectedCards.isEmpty else { return } // Exit early if all connected
        
        var connectionsToAdd: [Connection] = []

        for card in unconnectedCards {
            guard let cardPos = cardPositionMap[card.id] else { continue }

            var possibleConnections: [(targetCard: Card, targetPos: (row: Int, col: Int), isStraight: Bool)] = []
            for otherCard in selectionOrder where otherCard.id != card.id {
                guard let otherPos = cardPositionMap[otherCard.id] else { continue }
                // Use GameStateManager's adjacency check
                if gameStateManager.isAdjacent(position1: cardPos, position2: otherPos) {
                    let isStraight = isStraightConnection(from: cardPos, to: otherPos)
                    possibleConnections.append((targetCard: otherCard, targetPos: otherPos, isStraight: isStraight))
                }
            }

            // Find best connection (prefer straight)
            if let bestConnection = possibleConnections.min(by: { ($0.isStraight ? 0 : 1) < ($1.isStraight ? 0 : 1) }) {
                let (fromAnchor, toAnchor) = determineAnchorPoints(from: cardPos, to: bestConnection.targetPos)
                 // Avoid adding duplicate connections if validation runs multiple times?
                 let newConnection = Connection(fromCard: card, toCard: bestConnection.targetCard, fromPosition: fromAnchor, toPosition: toAnchor)
                 if !connections.contains(where: { ($0.fromCard == newConnection.fromCard && $0.toCard == newConnection.toCard) || ($0.fromCard == newConnection.toCard && $0.toCard == newConnection.fromCard) }) {
                    connectionsToAdd.append(newConnection)
                 }
            }
        }
        connections.append(contentsOf: connectionsToAdd)
    }

    private func determineAnchorPoints(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int)
    ) -> (AnchorPoint.Position, AnchorPoint.Position) {
        if from.col == to.col { // Same column
            return from.row < to.row ? (.bottom, .top) : (.top, .bottom)
        }
        if from.row == to.row { // Same row
            return from.col < to.col ? (.right, .left) : (.left, .right)
        }
        // Diagonal
        let isDiagonalUp = from.row > to.row
        let isDiagonalRight = from.col < to.col
        let fromAnchor: AnchorPoint.Position = isDiagonalUp ? (isDiagonalRight ? .topRight : .topLeft) : (isDiagonalRight ? .bottomRight : .bottomLeft)
        let toAnchor: AnchorPoint.Position = isDiagonalUp ? (isDiagonalRight ? .bottomLeft : .bottomRight) : (isDiagonalRight ? .topLeft : .topRight)
        return (fromAnchor, toAnchor)
    }

    private func isStraightConnection(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int)
    ) -> Bool {
        return from.row == to.row || from.col == to.col
    }
} 