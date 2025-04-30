import SwiftUI

/// A view that renders connection lines between selected cards
struct ConnectionLinesLayer: View {
    /// The view model containing connection data
    @ObservedObject var viewModel: GameViewModel
    
    /// The card frames dictionary mapping card IDs to their frames
    let cardFrames: [UUID: CGRect]
    
    /// Whether the connection lines should be animated
    let isAnimated: Bool
    
    /// Creates a connection lines layer with the specified parameters
    init(
        viewModel: GameViewModel,
        cardFrames: [UUID: CGRect],
        isAnimated: Bool = true
    ) {
        self.viewModel = viewModel
        self.cardFrames = cardFrames
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            ForEach(viewModel.connections) { connection in
                if let fromFrame = cardFrames[connection.fromCard.id],
                   let toFrame = cardFrames[connection.toCard.id] {
                    let fromPoint = calculateAnchorPoint(frame: fromFrame, position: connection.fromPosition)
                    let toPoint = calculateAnchorPoint(frame: toFrame, position: connection.toPosition)
                    
                    ConnectionLineView(
                        startPoint: fromPoint,
                        endPoint: toPoint,
                        color: Color(hex: "#FFD302"),
                        lineWidth: 2,
                        isAnimated: isAnimated
                    )
                }
            }
        }
    }
    
    /// Calculates the anchor point for a card based on its frame and anchor position
    private func calculateAnchorPoint(frame: CGRect, position: AnchorPoint.Position) -> CGPoint {
        // Define the corner radius offset (assuming cards have rounded corners)
        let cornerRadius: CGFloat = 8.0
        
        switch position {
        case .top:
            return CGPoint(x: frame.midX, y: frame.minY)
        case .right:
            return CGPoint(x: frame.maxX, y: frame.midY)
        case .bottom:
            return CGPoint(x: frame.midX, y: frame.maxY)
        case .left:
            return CGPoint(x: frame.minX, y: frame.midY)
        case .topLeft:
            // Adjust for rounded corner by moving the point inward
            return CGPoint(x: frame.minX + cornerRadius, y: frame.minY + cornerRadius)
        case .topRight:
            // Adjust for rounded corner by moving the point inward
            return CGPoint(x: frame.maxX - cornerRadius, y: frame.minY + cornerRadius)
        case .bottomLeft:
            // Adjust for rounded corner by moving the point inward
            return CGPoint(x: frame.minX + cornerRadius, y: frame.maxY - cornerRadius)
        case .bottomRight:
            // Adjust for rounded corner by moving the point inward
            return CGPoint(x: frame.maxX - cornerRadius, y: frame.maxY - cornerRadius)
        }
    }
}

#if DEBUG
struct ConnectionLinesLayer_Previews: PreviewProvider {
    static var previews: some View {
        // Create dummy instances for preview
        // Ensure DummyHapticsManager exists (defined below)
        let dummyHaptics = DummyHapticsManager()
        let dummyGameState = GameStateManager(hapticsManager: dummyHaptics)
        let dummySelection = CardSelectionManager(gameStateManager: dummyGameState, hapticsManager: dummyHaptics)
        let dummyConnections = ConnectionDrawingService(gameStateManager: dummyGameState, cardSelectionManager: dummySelection)
        let dummyScoreAnimator = ScoreAnimator() // Create dummy animator
        let dummyViewModel = GameViewModel(
            gameStateManager: dummyGameState,
            cardSelectionManager: dummySelection,
            connectionDrawingService: dummyConnections,
            scoreAnimator: dummyScoreAnimator, // Pass animator
            hapticsManager: dummyHaptics
        )
        
        // Avoid setting private state directly. 
        // The preview will show an empty state, which is acceptable.
        /* 
        // Example: Populate with some dummy cards and connections for preview
        let card1 = Card(suit: .hearts, rank: .ace)
        let card2 = Card(suit: .hearts, rank: .king)
        dummyGameState.cardPositions = [
            CardPosition(card: card1, row: 1, col: 1),
            CardPosition(card: card2, row: 1, col: 2)
        ]
        dummySelection.selectCard(card1)
        dummySelection.selectCard(card2)
        dummyConnections.updateConnections() // Trigger connection update
        */

        return ConnectionLinesLayer(
            viewModel: dummyViewModel,
            // Pass empty frames for basic preview
            cardFrames: [:],
            isAnimated: true
        )
        .background(Color.black) // Add background for visibility
    }
}
#endif

// Define DummyHapticsManager for Preview - DO NOT INHERIT
#if DEBUG
class DummyHapticsManager: HapticsManaging { // Conform to protocol
    // Implement required methods (can be empty)
    func playSuccess() {}
    func playError() {}
    func playWarning() {}
    func playSelectionChanged() {}
    func playImpact(intensity: CGFloat) {}
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {}
    func prepare() {}
    func playShiftImpact() {}
    func playNewCardImpact() {}
    func playDeselectionImpact() {}
    func playSuccessNotification() {}
    func playErrorNotification() {}
    func playResetNotification() {}
}
#endif 