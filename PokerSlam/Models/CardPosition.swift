import Foundation

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