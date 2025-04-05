# PokerSlam Technical Documentation

## Project Technical Specifications

### Development Environment
- **Platform**: iOS 15.0+ (with enhanced features for iOS 18.0+)
- **Language**: Swift 5.5+
- **IDE**: Xcode 13.0+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **State Management**: SwiftUI's native state management system

### Project Structure
```
PokerSlam/
├── Views/                 # SwiftUI Views
│   ├── GameView.swift     # Main game interface
│   ├── Components/        # Reusable UI components
│   │   ├── SharedUI.swift # Shared UI components including MeshGradientBackground
│   │   ├── ConnectionLineView.swift # Connection line rendering
│   │   └── ConnectionLinesLayer.swift # Connection lines management
│   └── ...
├── ViewModels/           # View Models
├── Models/               # Data Models
│   ├── Card.swift        # Card model
│   ├── Connection.swift  # Connection between cards
│   ├── AnchorPoint.swift # Anchor point for connections
│   └── ...
├── Extensions/          # Swift Extensions
│   └── Color+Hex.swift  # Color extension for hex color support
├── Resources/           # Assets and Resources
└── Tests/               # Test Suites
```

## Feature Technical Specifications

### 1. Card Grid System

#### Grid Layout
```swift
struct CardGridView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { col in
                        // Card rendering logic
                    }
                }
                .frame(height: 94)
            }
        }
    }
}
```
- 5x5 grid layout
- Fixed card dimensions (64x94)
- 8-point spacing between cards
- Dynamic card positioning
- Spring animations for movement

#### Card Positioning
- Uses `CardPosition` struct for tracking
- Supports current and target positions
- Implements smooth transitions
- Handles empty space management
- Manages card shifting and filling

### 2. Card Selection System

#### Selection Logic
```swift
func selectCard(_ card: Card) {
    guard areCardsInteractive else { return }
    
    if selectedCards.contains(card) {
        // Deselection logic
    } else if isCardEligibleForSelection(card) {
        // Selection logic
    }
}
```
- Supports multiple card selection
- Validates selection eligibility
- Implements deselection logic
- Provides haptic feedback

#### Selection Rules
- Cards must be adjacent
- Adjacent means:
  - Same column, one row apart
  - Adjacent columns, one row apart (with no empty columns between)
- Empty columns break adjacency
- Maximum 5 cards per selection
- Real-time validation

### 3. Connection Lines System

#### Connection Model
```swift
struct Connection: Identifiable, Equatable {
    let id = UUID()
    let fromCard: Card
    let toCard: Card
    let fromPosition: AnchorPoint.Position
    let toPosition: AnchorPoint.Position
}
```
- Represents a connection between two cards
- Tracks source and destination cards
- Specifies anchor points for line drawing
- Implements `Identifiable` for unique identification
- Implements `Equatable` for comparison

#### Anchor Point Model
```swift
struct AnchorPoint: Equatable {
    enum Position: String, CaseIterable {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
    }
    
    let position: Position
    let point: CGPoint
}
```
- Defines anchor positions on cards
- Supports 8 anchor points (corners and midpoints)
- Accounts for card rounded corners
- Provides point coordinates for line drawing

#### Connection Line Rendering
```swift
struct ConnectionLineView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let lineWidth: CGFloat
    let isAnimated: Bool
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        Path { path in
            // Calculate the current end point based on animation progress
            let currentEndPoint = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * animationProgress,
                y: startPoint.y + (endPoint.y - startPoint.y) * animationProgress
            )
            
            path.move(to: startPoint)
            path.addLine(to: currentEndPoint)
        }
        .stroke(color, lineWidth: lineWidth)
        .onAppear {
            if isAnimated {
                // Reset animation progress
                animationProgress = 0
                
                // Animate the line drawing
                withAnimation(.easeInOut(duration: 0.3)) {
                    animationProgress = 1
                }
            } else {
                // If not animated, set progress to 1 immediately
                animationProgress = 1
            }
        }
    }
}
```
- Renders connection lines between cards
- Implements line draw animation
- Supports customizable appearance
- Handles animation state management
- Provides smooth visual feedback

#### Connection Lines Layer
```swift
struct ConnectionLinesLayer: View {
    @ObservedObject var viewModel: GameViewModel
    let cardFrames: [UUID: CGRect]
    let isAnimated: Bool
    
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
                        color: Color(hex: "#d4d4d4"),
                        lineWidth: 2,
                        isAnimated: isAnimated
                    )
                }
            }
        }
    }
    
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
```
- Manages all connection lines in the game
- Calculates anchor points for connections
- Handles card frame tracking
- Supports animation state management
- Accounts for card rounded corners

#### Connection Graph System
```swift
private struct ConnectionGraph {
    var nodes: Set<ConnectionNode>
    var edges: Set<ConnectionEdge>
    
    func findMinimumSpanningTree() -> Set<ConnectionEdge> {
        // Use Kruskal's algorithm to find the minimum spanning tree
        // that minimizes diagonal connections
    }
}
```
- Creates a graph representation of card connections
- Uses Kruskal's algorithm for minimum spanning tree
- Prioritizes straight connections over diagonal ones
- Optimizes connection paths between selected cards
- Ensures all cards are connected with minimal lines

### 4. Card Shifting System

#### Shifting Logic
```swift
// Process each column independently
for col in 0..<5 {
    let columnCards = cardPositions.filter { $0.currentCol == col }
        .sorted { $0.currentRow > $1.currentRow }
    
    // Calculate empty positions
    let emptyPositions = columnEmptyPositions.filter { $0 > cardPosition.currentRow }
    
    // Shift cards down
    for cardPosition in columnCards {
        if let cardIndex = cardPositions.firstIndex(where: { $0.id == cardPosition.id }) {
            let newRow = cardPosition.currentRow + emptyCount
            cardPositions[cardIndex].targetRow = newRow
        }
    }
}
```
- Processes columns independently
- Sorts cards from bottom to top
- Calculates empty positions
- Shifts cards down to fill gaps
- Maintains column integrity

#### New Card Filling
- Adds new cards from the top
- Fills empty positions in order
- Maintains grid completeness
- Handles deck exhaustion

### 5. Game Over Detection

#### End Game Logic
```swift
private func checkGameOver() {
    // Check if there are any valid poker hands possible
    let allCards = cardPositions.map { $0.card }
    
    // If deck is empty and grid is incomplete
    if deck.isEmpty && cardPositions.count < 25 {
        // Check all possible combinations
        for size in 2...5 {
            let combinations = allCards.combinations(ofCount: size)
            for cards in combinations {
                // Check if cards can be selected according to adjacency rules
                if canSelectCards(cards), let handType = PokerHandDetector.detectHand(cards: cards) {
                    isGameOver = false
                    return
                }
            }
        }
        isGameOver = true
    }
}
```
- Checks for valid hands
- Considers adjacency rules
- Handles empty deck scenario
- Validates remaining cards

### 6. Hand Recognition System

#### Hand Types
- Pair
- Three of a Kind
- Straight
- Flush
- Full House
- Four of a Kind
- Straight Flush
- Royal Flush

#### Validation Logic
- Real-time hand checking
- Score calculation
- Hand ranking system
- Visual feedback

### 7. Scoring System

#### Score Calculation
```swift
class GameState: ObservableObject {
    @Published var currentScore: Int
    @Published var highScore: Int
    
    func updateHighScore() {
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
}
```
- Points based on hand type
- High score tracking
- Persistent storage
- Real-time updates

### 8. Animation System

#### Card Animations
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.targetRow)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardPosition.targetCol)
```
- Spring-based movement
- Smooth transitions
- Performance optimized
- Coordinated animations

#### UI Animations
- Scale effects
- Opacity transitions
- Position updates
- Layout changes

### 9. Mesh Gradient Background System

#### MeshGradientBackground
```swift
struct MeshGradientBackground: View {
    // MARK: - Types
    
    /// Represents the different positions for the mesh gradient animation
    private enum MeshPosition {
        case first
        case second
        case third
        case fourth
    }
    
    // MARK: - Properties
    
    @State private var currentPosition: MeshPosition = .first
    
    private let gradientColors: [Color] = [
        Color(hex: "#260846"),
        Color(hex: "#35088A"),
        Color(hex: "#12196F"),
        Color(hex: "#3E00B9"),
        Color(hex: "#0D092B"),
        Color(hex: "#132A73"),
        Color(hex: "#260846"),
        Color(hex: "#1A196A"),
        Color(hex: "#12196F")
    ]
    
    private let backgroundColor = Color(hex: "#0D092B")
    
    // MARK: - Position Arrays
    
    private let firstPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.25, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.25, 0.25), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.75, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    // Additional position arrays...
    
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: currentPoints,
                colors: gradientColors,
                background: backgroundColor,
                smoothsColors: true
            )
            .ignoresSafeArea()
            .onAppear {
                cyclePosition()
            }
        } else {
            // Fallback for iOS versions before 18.0
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    private func cyclePosition() {
        withAnimation(.easeInOut(duration: 5)) {
            switch currentPosition {
            case .first: currentPosition = .second
            case .second: currentPosition = .fourth
            case .third: currentPosition = .first
            case .fourth: currentPosition = .third
            }
        }
        
        // Schedule the next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            cyclePosition()
        }
    }
}
```
- Uses iOS 18.0+ MeshGradient for advanced visual effects
- Implements position-based animation with four distinct positions
- Provides fallback to LinearGradient for earlier iOS versions
- Uses SIMD2<Float> for efficient vector operations
- Supports customizable animation timing and curves
- Implements recursive animation cycle for continuous motion

## Established Patterns

### 1. View Composition Pattern

#### Component Structure
```swift
struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var gameState: GameState
    
    var body: some View {
        GameContainer(
            viewModel: viewModel,
            gameState: gameState,
            showingHandReference: $showingHandReference,
            dismiss: dismiss
        )
    }
}
```
- Hierarchical view structure
- Clear component boundaries
- Reusable components
- State propagation

### 2. State Management Pattern

#### State Properties
```swift
@Published private(set) var cardPositions: [CardPosition]
@Published private(set) var selectedCards: Set<Card>
@Published private(set) var eligibleCards: Set<Card>
```
- Private setters
- Public getters
- Observable properties
- State encapsulation

### 3. Event Handling Pattern

#### User Interaction
```swift
Button(action: { 
    if viewModel.score > gameState.currentScore {
        gameState.currentScore = viewModel.score
    }
    viewModel.resetGame()
}) {
    Text("Play Again")
        .font(.headline)
        .foregroundColor(.white)
}
```
- Action-based callbacks
- State updates
- UI feedback
- Error handling

### 4. Layout Pattern

#### Responsive Design
```swift
VStack(spacing: 0) {
    // Header
    // Content
    // Footer
}
.frame(height: 60)
```
- Fixed dimensions
- Flexible spacing
- Adaptive layouts
- Safe area handling

### 5. Data Flow Pattern

#### State Updates
```swift
.onChange(of: viewModel.selectedCards.count) { oldValue, newValue in
    if newValue > 0 {
        showIntroMessage = false
    }
}
```
- Reactive updates
- State observation
- UI synchronization
- Performance optimization

### 6. Animation Pattern

#### Position-Based Animation
```swift
private func cyclePosition() {
    withAnimation(.easeInOut(duration: 5)) {
        switch currentPosition {
        case .first: currentPosition = .second
        case .second: currentPosition = .fourth
        case .third: currentPosition = .first
        case .fourth: currentPosition = .third
        }
    }
    
    // Schedule the next animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        cyclePosition()
    }
}
```
- Position-based state transitions
- Recursive animation scheduling
- Customizable timing and curves
- Continuous animation cycles

## Technical Requirements

### 1. Performance Requirements
- 60 FPS animations
- < 100ms response time
- Efficient memory usage
- Smooth transitions

### 2. Memory Requirements
- < 50MB app size
- Efficient resource loading
- Proper cleanup
- Memory leak prevention

### 3. UI Requirements
- Support all iOS devices
- Dark mode support
- Dynamic type
- Accessibility features
- iOS 18.0+ feature detection

### 4. Testing Requirements
- Unit test coverage > 80%
- UI test automation
- Performance testing
- Memory leak testing

## Implementation Guidelines

### 1. Code Style
- Swift style guide compliance
- Clear naming conventions
- Proper documentation
- Consistent formatting

### 2. Error Handling
- Graceful degradation
- User feedback
- Error logging
- Recovery mechanisms

### 3. Performance Optimization
- Lazy loading
- Efficient algorithms
- Resource management
- Cache utilization
- SIMD2 for vector operations

### 4. Security
- Data validation
- Input sanitization
- Secure storage
- Privacy compliance

## Future Technical Considerations

### 1. Scalability
- Modular architecture
- Feature isolation
- Performance monitoring
- Resource optimization

### 2. Maintainability
- Code documentation
- Testing coverage
- Dependency management
- Version control

### 3. Integration
- Analytics integration
- Social features
- Cloud sync
- Push notifications 