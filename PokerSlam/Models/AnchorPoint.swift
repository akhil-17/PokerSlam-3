import SwiftUI

/// Represents an anchor point on a card for drawing connection lines
struct AnchorPoint: Equatable {
    /// The position of the anchor point on the card
    enum Position: String, CaseIterable {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
    }
    
    /// The position type of this anchor point
    let position: Position
    
    /// The actual point coordinates in the card's coordinate space
    let point: CGPoint
    
    /// Creates an anchor point with the specified position and coordinates
    init(position: Position, point: CGPoint) {
        self.position = position
        self.point = point
    }
} 