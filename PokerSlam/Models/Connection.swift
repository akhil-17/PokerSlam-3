import Foundation

/// Represents a connection between two cards
struct Connection: Identifiable, Equatable {
    /// Unique identifier for the connection
    let id = UUID()
    
    /// The card where the connection starts
    let fromCard: Card
    
    /// The card where the connection ends
    let toCard: Card
    
    /// The anchor position on the starting card
    let fromPosition: AnchorPoint.Position
    
    /// The anchor position on the ending card
    let toPosition: AnchorPoint.Position
    
    /// Creates a connection between two cards with specified anchor positions
    init(
        fromCard: Card,
        toCard: Card,
        fromPosition: AnchorPoint.Position,
        toPosition: AnchorPoint.Position
    ) {
        self.fromCard = fromCard
        self.toCard = toCard
        self.fromPosition = fromPosition
        self.toPosition = toPosition
    }
    
    /// Checks if two connections are equal
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        return lhs.fromCard.id == rhs.fromCard.id &&
               lhs.toCard.id == rhs.toCard.id &&
               lhs.fromPosition == rhs.fromPosition &&
               lhs.toPosition == rhs.toPosition
    }
} 