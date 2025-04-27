# PokerSlam Technical Documentation

## Project Technical Specifications

### Development Environment
- **Platform**: iOS 15.0+ (with enhanced features for iOS 18.0+)
- **Language**: Swift 5.5+
- **IDE**: Xcode 13.0+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Service Layer
- **State Management**: SwiftUI's native state management (`@State`, `@StateObject`, `@Published`), `ObservableObject` protocol, Callbacks.

### Project Structure
```
PokerSlam/
├── Views/                 # SwiftUI Views
│   ├── GameView.swift     # Main game container view (handles transitions, overlays)
│   ├── Components/        # Reusable UI components (Buttons, Gradients, Text Effects, etc.)
│   │   ├── CardView.swift # Individual card view (includes regular and mini styles)
│   │   ├── FallingRanksView.swift # Main menu background animation
│   │   ├── HandReferenceView.swift # Hand reference overlay content
│   │   └── ...              # Other components (e.g., PrimaryButton, CircularIconButton)
│   └── ...
├── ViewModels/           # View Models
│   └── GameViewModel.swift # Orchestrates Services, manages UI state for GameView
├── Models/               # Data Models
│   ├── Card.swift        # Card model (Suit, Rank)
│   ├── HandType.swift    # Poker hand types and scoring
│   ├── CardPosition.swift # Tracks card row, column, and target positions
│   ├── Connection.swift  # Represents a visual connection between cards
│   └── ...
├── Services/             # Core Logic and State Managers
│   ├── GameStateManager.swift # Manages deck, card layout, scoring, game over logic
│   ├── CardSelectionManager.swift # Handles card selection, eligibility, hand text state
│   ├── ConnectionDrawingService.swift # Calculates connection line paths
│   ├── ScoreAnimator.swift # Manages score display animation logic
│   ├── HapticsManager.swift # Centralizes haptic feedback
│   └── PokerHandDetector.swift # Contains logic for detecting all hand types
├── Extensions/          # Swift Extensions
│   └── Color+Hex.swift  # Color utility
├── Resources/           # Assets (Images, Fonts)
├── PokerSlamApp.swift   # App Entry Point
├── Tests/               # Unit and UI Tests
└── docs/                # Project Documentation
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
- Pair (15 points)
- Mini Straight (25 points)
- Mini Flush (30 points)
- Mini Straight Flush (35 points)
- Mini Royal Flush (40 points)
- Three of a Kind (45 points)
- Two Pair (50 points)
- Nearly Straight (55 points)
- Nearly Flush (60 points)
- Nearly Straight Flush (65 points)
- Nearly Royal Flush (70 points)
- Four of a Kind (75 points)
- Straight (80 points)
- Flush (85 points)
- Full House (90 points)
- Straight Flush (95 points)
- Royal Flush (100 points)

#### Validation Logic
- Real-time hand checking
- Score calculation
- Hand ranking system
- Visual feedback
- Prioritized hand detection (higher-ranking hands detected before lower-ranking ones)
- Proper handling of overlapping hand types (e.g., straight flush detected before flush)

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
- Comprehensive scoring for all hand types including mini straight flushes and nearly straight flushes

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

#### Glyph-by-glyph Animation
```swift
struct GlyphAnimatedText: View {
    let text: String
    let animationDelay: Double // Optional delay for sequencing
    @State private var visibleGlyphs: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < visibleGlyphs ? 1 : 0)
                    .offset(y: index < visibleGlyphs ? 0 : 20)
                    .blur(radius: index < visibleGlyphs ? 0 : 5)
            }
        }
        .onAppear {
            // Animate each glyph sequentially
            for i in 0..<text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        visibleGlyphs = i + 1
                    }
                }
            }
        }
    }

    private func animateGlyphs() { /* ... */ }
    private func resetAndAnimateGlyphs() { /* ... */ }
}
```
- Implements glyph-by-glyph text animation
- Uses sequential animation with configurable delay (`animationDelay`)
- Applies spring animation for each character
- Combines opacity, offset, and blur transitions
- Provides customizable animation timing
- Replays animation when `text` changes via `.onChange` and `.id`

#### Glyph Wave Animation
- Uses `WaveEffectModifier` applied to each character in `GlyphAnimatedText`.
- Creates a continuous, subtle vertical wave motion across the text.
- Animation syncs with the `TimelineView` when `isWaveAnimating` is true.
- Wave ramps up/down smoothly when the animation starts/stops.

#### Falling Rank Symbol Effect
- Uses `FallingRankSymbolEffectModifier` applied to symbols in `FallingRanksView`.
- Leverages `.symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))` for iOS 17+.
- Provides a continuous pulsing effect to the falling ranks.
- Gracefully degrades (no effect) on older iOS versions.

### 9. Mesh Gradient Background System

#### MeshGradientBackground
```swift
struct MeshGradientBackground: View {
    // MARK: - Properties
    
    private let gradientColors: [Color] = [
        Color(hex: "#260846"),
        Color(hex: "#35088A"),
        Color(hex: "#12196F"),
        Color(hex: "#3E00B9"),
        Color(hex: "#8053DF"),
        Color(hex: "#132A73"),
        Color(hex: "#260846"),
        Color(hex: "#1A196A"),
        Color(hex: "#12196F")
    ]
    
    private let backgroundColor = Color(hex: "#0D092B")
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation) { timeline in
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedPositions(for: timeline.date),
                    colors: gradientColors,
                    background: backgroundColor,
                    smoothsColors: true
                )
                .ignoresSafeArea()
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
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}
```
- Uses iOS 18.0+ MeshGradient for advanced visual effects
- Implements TimelineView for continuous animation
- Uses cosine-based animation for organic movement
- Provides fallback to LinearGradient for earlier iOS versions
- Uses SIMD2<Float> for efficient vector operations
- Supports customizable animation timing and curves

#### Customizable Color Palette
- Allows for different color combinations
- Enhances visual appeal
- Supports dynamic theme changes

#### Mesh Gradient Text Effects
- Applies mesh gradient effects to text
- Creates visually appealing text effects
- Supports sequential glyph animation
- Enhances text readability

### 10. Button Animation System

#### PrimaryButton
```swift
struct PrimaryButton: View {
    // MARK: - Properties
    
    let title: String
    let icon: String?
    let action: () -> Void
    let isAnimated: Bool
    @State private var isVisible: Bool = false
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                // Text with mesh gradient effect and sequential animation
                ButtonTextLabel(text: title)
                    .transition(TextTransition())
                    .offset(y: isVisible ? 0 : textOffset)
                    .opacity(isVisible ? 1 : 0)
                    .blur(radius: isVisible ? 0 : 5)
                
                if let icon = icon {
                    // Icon with mesh gradient effect
                    ButtonIconLabel(systemName: icon, isAnimated: isAnimated)
                        .offset(y: isVisible ? 0 : textOffset)
                        .opacity(isVisible ? 1 : 0)
                        .blur(radius: isVisible ? 0 : 5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 4)
            .background(
                MeshGradientBackground2()
                    .mask(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.60), lineWidth: 16)
                            .blur(radius: 4)
                            .blendMode(.overlay)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.25), lineWidth: 2)
                            .blur(radius: 12)
                            .blendMode(.hardLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                            .blur(radius: 1)
                            .blendMode(.multiply)
                    )
            )
            .background(Color(hex: "#0D092B"))
            .cornerRadius(40)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(.black.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 20)
        }
        .padding()
        .modifier(PrimaryButtonAnimationModifier(action: action))
    }
}
```
- Implements a primary action button with consistent styling
- Uses mesh gradient background with masking and overlays
- Applies sequential text animation with glyph-by-glyph reveal
- Supports optional icon with mesh gradient effect
- Implements entrance and exit animations
- Provides visual feedback for user interactions
- Applies shared success animation (scale/glow) via SuccessAnimationModifier based on state
- Applies error wiggle animation based on state

#### ButtonTextLabel
```swift
struct ButtonTextLabel: View {
    let text: String
    
    var body: some View {
        GlyphAnimatedText(text: text)
            .font(.mainButton)
            .foregroundStyle(.clear)
            .background(
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: animatedPositions(for: timeline.date),
                        colors: [
                            Color(hex: "#D5602B"),
                            Color(hex: "#D45F2B"),
                            Color(hex: "#AAAAAA"),
                            Color(hex: "#4883D3"),
                            Color(hex: "#FFD302"),
                            Color(hex: "#AAAAAA"),
                            Color(hex: "#4883D3"),
                            Color(hex: "#50803A"),
                            Color(hex: "#50803A")
                        ],
                        background: Color.clear,
                        smoothsColors: true
                    )
                }
            )
            .mask(
                GlyphAnimatedText(text: text)
                    .font(.mainButton)
            )
    }
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}
```
- Applies mesh gradient effect to text
- Uses TimelineView for continuous animation
- Implements cosine-based animation for organic movement
- Masks the gradient to the text shape
- Supports customizable animation timing and curves

#### ButtonIconLabel
```swift
struct ButtonIconLabel: View {
    let systemName: String
    let isAnimated: Bool
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(.clear)
            .background(
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: animatedPositions(for: timeline.date),
                        colors: [
                            Color(hex: "#D5602B"),
                            Color(hex: "#D45F2B"),
                            Color(hex: "#AAAAAA"),
                            Color(hex: "#4883D3"),
                            Color(hex: "#FFD302"),
                            Color(hex: "#AAAAAA"),
                            Color(hex: "#4883D3"),
                            Color(hex: "#50803A"),
                            Color(hex: "#50803A")
                        ],
                        background: Color.clear,
                        smoothsColors: true
                    )
                }
            )
            .mask(
                Image(systemName: systemName)
                    .font(.system(size: 16))
            )
            .if(isAnimated) { view in
                view.modifier(PulsingAnimationModifier())
            }
    }
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}
```
- Applies mesh gradient effect to SF Symbols
- Uses TimelineView for continuous animation
- Implements cosine-based animation for organic movement
- Masks the gradient to the icon shape
- Supports optional pulsing animation
- Provides customizable animation timing and curves

#### TextTransition
```swift
struct TextTransition: Transition {
    static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }

    func body(content: Content, phase: TransitionPhase) -> some View {
        let duration = 0.9
        let elapsedTime = phase.isIdentity ? duration : 0
        let renderer = AppearanceEffectRenderer(
            elapsedTime: elapsedTime,
            totalDuration: duration
        )

        content.transaction { transaction in
            // Force the animation of `elapsedTime` to pace linearly and
            // drive per-glyph springs based on its value.
            if !transaction.disablesAnimations {
                transaction.animation = .linear(duration: duration)
            }
        } body: { view in
            view.textRenderer(renderer)
        }
    }
}
```
- Implements a custom transition for text
- Uses AppearanceEffectRenderer for glyph animation
- Supports spring-based animation for each character
- Combines opacity, offset, and blur transitions
- Provides customizable animation timing and curves

#### AppearanceEffectRenderer
```swift
struct AppearanceEffectRenderer: TextRenderer, Animatable {
    /// The amount of time that passes from the start of the animation.
    /// Animatable.
    var elapsedTime: TimeInterval

    /// The amount of time the app spends animating an individual element.
    var elementDuration: TimeInterval

    /// The amount of time the entire animation takes.
    var totalDuration: TimeInterval

    var spring: Spring {
        .snappy(duration: elementDuration - 0.05, extraBounce: 0.4)
    }

    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    init(elapsedTime: TimeInterval, elementDuration: Double = 0.4, totalDuration: TimeInterval) {
        self.elapsedTime = min(elapsedTime, totalDuration)
        self.elementDuration = min(elementDuration, totalDuration)
        self.totalDuration = totalDuration
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for run in layout.flattenedRuns {
            if run[EmphasisAttribute.self] != nil {
                let delay = elementDelay(count: run.count)

                for (index, slice) in run.enumerated() {
                    // The time that the current element starts animating,
                    // relative to the start of the animation.
                    let timeOffset = TimeInterval(index) * delay

                    // The amount of time that passes for the current element.
                    let elementTime = max(0, min(elapsedTime - timeOffset, elementDuration))

                    // Make a copy of the context so that individual slices
                    // don't affect each other.
                    var copy = context
                    draw(slice, at: elementTime, in: &copy)
                }
            } else {
                // Make a copy of the context so that individual slices
                // don't affect each other.
                var copy = context
                // Runs that don't have a tag of `EmphasisAttribute` quickly
                // fade in.
                copy.opacity = UnitCurve.easeIn.value(at: elapsedTime / 0.2)
                copy.draw(run)
            }
        }
    }

    func draw(_ slice: Text.Layout.RunSlice, at time: TimeInterval, in context: inout GraphicsContext) {
        // Calculate a progress value in unit space for blur and
        // opacity, which derive from `UnitCurve`.
        let progress = time / elementDuration

        let opacity = UnitCurve.easeIn.value(at: 1.4 * progress)

        let blurRadius =
            slice.typographicBounds.rect.height / 16 *
            UnitCurve.easeIn.value(at: 1 - progress)

        // The y-translation derives from a spring, which requires a
        // time in seconds.
        let translationY = spring.value(
            fromValue: -slice.typographicBounds.descent,
            toValue: 0,
            initialVelocity: 0,
            time: time)

        context.translateBy(x: 0, y: translationY)
        context.addFilter(.blur(radius: blurRadius))
        context.opacity = opacity
        context.draw(slice, options: .disablesSubpixelQuantization)
    }

    /// Calculates how much time passes between the start of two consecutive
    /// element animations.
    func elementDelay(count: Int) -> TimeInterval {
        let count = TimeInterval(count)
        let remainingTime = totalDuration - count * elementDuration

        return max(remainingTime / (count + 1), (totalDuration - elementDuration) / count)
    }
}
```
- Implements a custom text renderer for glyph animation
- Uses spring-based animation for each character
- Combines opacity, offset, and blur transitions
- Provides customizable animation timing and curves
- Supports emphasis attribute for selective animation

### 11. Haptic Feedback System
- `UISelectionFeedbackGenerator`: Used for card selection changes.
- `UIImpactFeedbackGenerator`: Used for deselection (.light), card shifting (.light), new card appearance (.soft).
- `UINotificationFeedbackGenerator`: Used for success hand play (.success), error hand play (.error), and game reset (.success).

### 12. Falling Ranks Animation System

#### FallingRanksView
```swift
struct FallingRanksView: View {
    @State private var ranks: [FallingRank] = []
    private let spawnInterval: TimeInterval = 0.5
    @State private var lastSpawnTime: Date = Date()
    private let fixedRankSize: CGFloat = 30.0
    private let fixedSpeed: CGFloat = 1.0
    // ... suit definitions ...

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.016)) { timeline in
                Canvas { context, size in
                    // Draw ranks using context.resolveSymbol
                } symbols: {
                    ForEach(ranks) { rank in
                         Image(systemName: rank.symbol)
                             .tag(rank.id)
                             .font(.system(size: fixedRankSize))
                             .foregroundStyle(rank.color.opacity(0.5))
                             .modifier(FallingRankSymbolEffectModifier()) // iOS 17+
                     }
                }
                .onChange(of: timeline.date) { _, newDate in
                     // Update positions
                     updateRankPositions(date: newDate, size: geometry.size)
                     // Spawn new ranks
                     if newDate.timeIntervalSince(lastSpawnTime) >= spawnInterval {
                         spawnNewRank(in: geometry.size)
                         lastSpawnTime = newDate
                     }
                 }
                // ... other modifiers (.clipped, .allowsHitTesting, .mask) ...
            }
        }
        // ...
    }

    private func updateRankPositions(date: Date, size: CGSize) { /* ... modifies ranks array ... */ }
    private func spawnNewRank(in size: CGSize) { /* ... adds new rank, checks spacing ... */ }
}
```
- Creates a background animation of falling suit symbols for the main menu.
- Uses `TimelineView` and `Canvas` for efficient drawing and animation updates.
- Manages rank positions and spawning using `@State` variables (`ranks`, `lastSpawnTime`).
- Implements logic (`spawnNewRank`) to ensure ranks are horizontally spaced out near the top, preventing overlap.
- Ranks fall at a consistent speed (`fixedSpeed`) and maintain a consistent size (`fixedRankSize`).
- State updates (`updateRankPositions`) are performed within `.onChange` to ensure proper separation from the `Canvas` drawing phase, resolving potential state update issues.
- Applies a `FallingRankSymbolEffectModifier` for a continuous pulse effect (iOS 17+).
- Uses a `LinearGradient` mask for a fade-out effect at the bottom.

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

### Main Menu View
- Simplified interface: Displays only the title "Poker Slam" and "tap to start" text.
- Interaction: Tapping anywhere on the screen transitions the user directly to the `GameView`.
- Styling: Uses `GradientText` for the title with `.appTitle` font and mesh gradient. Uses `IntroMessageTextStyle` modifier for the "tap to start" text.

### Game View Header
- Displays the current score, animating changes with a tally effect and gradient flash.
- Indicates when a new high score is achieved.
- Provides an exit button (X icon) to return to the main menu (updates high score on exit).
- Provides a help button (? icon) to show the `HandReferenceView` as a sheet.
- Displays a help button (? icon) using `CircularIconButton` to toggle the `HandReferenceView` overlay.

### Hand Reference View
- **Presentation:** Displayed as an overlay within `GameView` controlled by `@State var showingHandReference`.
- **Transition:** Uses `.transition(.opacity)` for fade-in/out.
- **Background:** Applied using `.background(.ultraThinMaterial)` with corner radius and shadow.
- **Header:** Custom header with `CircularIconButton` (`xmark`) for dismissal.
- **Content Structure:** Uses `ScrollView`, `SectionHeader`, and `HandReferenceRow` for layout.
- **Custom Fonts:** Utilizes fonts defined in `SharedUI.swift` (e.g., `.handReferenceInstruction`, `.handReferenceRowTitle`).
- **Mini Card Previews:** `HandReferenceRow` parses example hand strings (e.g., "(e.g., 5♠ 5♥)") using `parseExampleCards` helper and displays corresponding `CardView` instances with `style: .mini`.
- **CardView Mini Style:** A new style in `CardView` reducing size and font size for preview purposes.
- **Bottom Fade:** Uses a `Rectangle` masked with a `LinearGradient` to create a fade effect at the bottom of the scroll view.
- **Dismissal:** Controlled via `dismissAction` closure passed from `GameView`. 

### 5. Poker Hand Detection

#### Detection Logic
```swift
struct PokerHandDetector {
    static func detectHand(cards: [Card]) -> HandType?
}
```
- Detects valid poker hands from selected cards
- Supports 2-5 card hands
- Prioritizes higher-ranking hands
- Implements checks for standard and custom hands (pairs, straights, flushes, full house, four of a kind, straight flushes, royal flushes, mini/nearly variants)

#### Royal Flush Fix
- The `isRoyalFlush` check was updated to correctly identify the specific required ranks {Ace, King, Queen, Jack, Ten} in addition to being a Straight Flush. Previously, it incorrectly checked the rank of the last card after sorting.

### 6. Animation System

#### Mesh Gradient Background
- Uses `MeshGradient` (iOS 18.0+) for animated background.
- Provides fallback to `LinearGradient` for older iOS versions.
- Smoothly animates between predefined gradient states.

#### Card Movement
- Uses `.offset` modifier and `.animation(.spring)` for smooth card positioning changes.

#### Connection Lines
- Animates line drawing from start to end point using `Path` and `withAnimation`.

#### Glyph Text Animation
- Component: `GlyphAnimatedText.swift`
- Animates text display glyph-by-glyph.
- Supports delays and completion callbacks.
- Used for intro message, game over message, hand names, and scores.

#### Continuous Wave Animation
- Applied to `GlyphAnimatedText` for specific elements.
- **Title Wave:** Controlled by `isTitleWaveAnimating` state in `GameView` for the main menu title. Uses a `Task` loop started/stopped based on `GameView` state.
- **Hand Formation Text Wave:** Controlled by `isWaveAnimating` state within the `HandFormationText` subview. Uses a `Task` loop started after initial glyph animation completes (`glyphAnimationComplete`) and stopped when text changes or view disappears.

#### Score Animation
- Implemented in `GameView.swift`'s `scoreDisplay` and `handleScoreUpdate`.
- **Tally Effect:** Uses a `Timer` (`scoreUpdateTimer`) to incrementally update `displayedScore` towards `targetScore` for a counting effect.
- **Gradient Pulse:** The `Score` / `New high score` label and the score value briefly switch to a `MeshGradientBackground2` fill (masked) when the score updates, controlled by `isScoreAnimating` state.

#### Button Animations
- Uses `.transition(.opacity.combined(with: .move(edge: .bottom)))` for play button appearance.
- Uses `SuccessAnimationModifier` for a scale/glow effect on successful hand plays or game reset.

#### Falling Ranks Animation (Main Menu)
- Component: `FallingRanksView.swift`
- Uses `Canvas` for efficient rendering of many symbols.
- Uses `TimelineView(.animation)` to drive smooth animation updates.
- `FallingRank` struct stores state for each symbol.
- `updateRankPositions` calculates new Y positions based on speed and approximate delta time.
- `spawnNewRank` adds new ranks at the top, attempting basic collision avoidance.
- Applies a `LinearGradient` mask for fade-out effect.

### 7. Safe Area Layout

- **GameView:** The main `VStack` within `gamePlayContent` now uses `.padding(.top)` and `.padding(.bottom)` instead of fixed padding values.
- **Effect:** This automatically applies padding equal to the device's safe area insets, ensuring the `gameHeader` and the bottom button area are not obscured by notches or the home indicator, while allowing the background gradient to fill the entire screen edge-to-edge.
- **Stability:** The core layout's vertical stability (relative positioning of header, grid, button area) is maintained as the adaptive padding adjusts the overall container's vertical space.

### 8. Hand Reference Mini Card Previews

- **Component:** `HandReferenceRow` within `HandReferenceView` (`GameView.swift`).
- **Parsing:** Includes `parseExampleCards(from: String)` helper to extract card notations (e.g., "5♠ 5♥") from the description string.
- **Rendering:** Uses a nested `HStack` to display `CardView` instances for each parsed example card.
- **Styling:** Applies `CardView(style: .mini)` to render smaller, non-interactive card representations.

## 🔧 Tooling & Dependencies

- **Version Control**: Git
- **Dependency Management**: Swift Package Manager (SPM)
- **CI/CD**: GitHub Actions (basic setup)

## 🧪 Testing Strategy

- **Unit Tests**: XCTest framework for testing models and view models.
- **UI Tests**: XCUITest framework for testing UI flows and interactions.
- **Coverage**: Aim for high test coverage across critical components.

## 💡 Performance Considerations

- Use `LazyVStack`/`LazyHStack` for efficient grid rendering.
- Optimize hand detection algorithms.
- Leverage SwiftUI's optimized rendering.
- Use `Canvas` for performant drawing of many elements (Falling Ranks).
- Profile with Instruments for identifying bottlenecks.

## 🔒 Security Considerations

- Validate user inputs (if applicable).
- Secure data storage (e.g., Keychain for sensitive data, though currently only UserDefaults is used for high scores).
- Follow Apple's security best practices.

## 📚 Documentation

- Maintain comprehensive documentation in the `docs/` directory.
- Keep README.md updated with project overview and setup instructions.
- Document architecture, technical specifications, and coding standards. 

### 1. Game View & State Management
- **GameView (`GameView.swift`)**: Acts as the main container. Uses a `@State` variable (`currentViewState`) to switch between `.mainMenu` and `.gamePlay` content.
- **GameViewModel (`GameViewModel.swift`)**: 
    - Initialized using `@StateObject` in `GameView`.
    - Instantiates and holds references to all necessary services (`GameStateManager`, `CardSelectionManager`, etc.).
    - **Orchestration**: Coordinates actions between services via direct calls and callbacks.
    - **State Exposure**: Uses `@Published` properties to expose required state (e.g., `cardPositions`, `selectedCards`, `displayedScore`, `isGameOver`) to `GameView`. It gets this state from the underlying services.
    - **Bindings**: Sets up Combine bindings (`.assign(to:)`) to automatically update its `@Published` properties when the corresponding properties in the services change.
    - **Callbacks**: Registers callback closures with services (e.g., `gameStateManager.onNewCardsDealt`) to react to events and trigger necessary updates in other services (e.g., calling `cardSelectionManager.updateEligibleCards()`).

### 2. Game State Service (`GameStateManager.swift`)
- **Responsibilities**: Manages the core game state: the deck, `cardPositions` array (including `currentRow`, `currentCol`, `targetRow`, `targetCol`), `score`, `isGameOver` flag, `lastPlayedHand`, and dealing logic.
- **Card Lifecycle**: Handles `dealInitialCards`, `removeCardsAndShiftAndDeal`, `shiftCardsDown`, `dealNewCardsToFillGrid`.
- **Game Over Check**: Contains `checkGameOver` and the crucial `canSelectCards` helper (using BFS/DFS for connectivity check) to determine if any valid, *selectable* hands remain.
- **State Publishing**: Uses `@Published` for key state variables (`cardPositions`, `score`, `isGameOver`, `lastPlayedHand`) that `GameViewModel` binds to.
- **Callbacks**: Provides `onNewCardsDealt` and `onGameOverChecked` for `GameViewModel`.

### 3. Card Selection Service (`CardSelectionManager.swift`)
- **Responsibilities**: Manages the user's card selection process: `selectedCards` set, `eligibleCards` set, `selectionOrder`, `currentHandText`, and UI feedback states (`isErrorState`, `isSuccessState`).
- **Selection Logic**: Implements `selectCard`, `handleSelection`, `handleDeselection` (now calls `unselectAllCards`), `unselectAllCards`.
- **Eligibility**: Calculates `eligibleCards` based on the current selection and adjacency rules using `GameStateManager.isAdjacent`.
- **State Publishing**: Uses `@Published` for its state variables that `GameViewModel` binds to.
- **Callback**: Provides `onSelectionChanged` for `GameViewModel` (used to trigger connection updates).

### 4. Connection Drawing Service (`ConnectionDrawingService.swift`)
- **Responsibilities**: Calculates the `connections` array (`[Connection]`) based on the current `selectedCards` from `CardSelectionManager` and their positions from `GameStateManager`.
- **Pathfinding**: Implements logic (likely Minimum Spanning Tree or similar) to determine the optimal visual connections between selected cards.
- **State Publishing**: Publishes the `connections` array for `GameViewModel` / `GameView`.

### 5. Score Animation Service (`ScoreAnimator.swift`)
- **Responsibilities**: Manages the visual animation of the score display.
- **State**: Holds `displayedScore` (the value shown on screen) and `targetScore`.
- **Animation Logic**: Implements the tally animation logic to update `displayedScore` incrementally towards `targetScore`.
- **State Publishing**: Publishes `displayedScore` and `isScoreAnimating` for `GameViewModel` / `GameView`.

### 6. Haptics Service (`HapticsManager.swift`)
- **Responsibilities**: Centralizes all haptic feedback generation.
- **Methods**: Provides specific methods like `playSelectionChanged`, `playDeselectionImpact`, `playSuccessNotification`, `playErrorNotification`, `playResetNotification`, etc.
- **Usage**: Injected into and used by `GameViewModel` and `CardSelectionManager`.

// ... Update other sections like Hand Recognition, Scoring, Animation System, UI Components (MainMenu, Header, HandReference) to reflect the refactoring and service responsibilities ...

### UI Components

#### Main Menu (`GameView.swift` - `.mainMenu` state)
- Displays title and "tap to start".
- Background: `FallingRanksView`.
- Interaction: Tap gesture triggers `viewModel.resetGame()` and transitions `currentViewState` to `.gamePlay`.

#### Game Header (`GameView.swift` - `gameHeader` property)
- Contains `CircularIconButton` for exit (triggers `viewModel.resetGame()`, returns to `.mainMenu`).
- Contains `scoreDisplay`.
- Contains `CircularIconButton` for help (toggles `showingHandReference` state).

#### Score Display (`GameView.swift` - `scoreDisplay` property)
- Displays score label ("Score" or "New high score") and value (`viewModel.displayedScore`).
- Score Label uses `.id()` and `.transition(.opacity)` for crossfade animation between "Score" and "New high score" based on `viewModel.score > gameState.currentScore`.
- Score Value uses opacity animations based on `viewModel.isScoreAnimating` (driven by `ScoreAnimator`) to show/hide base text vs. gradient text for a pulse effect.

#### Hand Reference View (`HandReferenceView.swift`, presented in `GameView.swift`)
- Overlay presentation controlled by `showingHandReference` state in `GameView`.
- Uses `.transition(.opacity)`.
- Contains `HandReferenceRow` which uses `CardView(style: .mini)`.
- Dismissed via action closure passed from `GameView`.

// ... rest of technical.md ... 