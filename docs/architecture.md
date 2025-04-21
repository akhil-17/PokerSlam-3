# PokerSlam Architecture Documentation

## System Architecture Overview

PokerSlam follows a modern MVVM (Model-View-ViewModel) architecture with SwiftUI, emphasizing clean separation of concerns, testability, and maintainability. The architecture is designed to support iOS 15.0+ with enhanced features for iOS 18.0+.

### Core Architectural Components

1. **View Layer**
   - SwiftUI views for UI representation
   - Reusable components
   - View composition
   - State observation
   - iOS version-specific features

2. **ViewModel Layer**
   - Business logic
   - State management
   - Data transformation
   - Event handling
   - Game rules enforcement

3. **Model Layer**
   - Data structures
   - Game state
   - Card logic
   - Connection models
   - Animation states

4. **Service Layer**
   - Game mechanics
   - Hand detection
   - Score calculation
   - Animation coordination
   - Background effects

## Data Models

### Card Model
```swift
struct Card: Identifiable, Equatable {
    let id: UUID
    let rank: Rank
    let suit: Suit
    var isSelected: Bool
    var isEligible: Bool
}
```
- Unique identification
- Card properties
- Selection state
- Eligibility tracking

### Falling Rank Model (for animation)
```swift
private struct FallingRank: Identifiable {
    let id = UUID()
    let symbol: String // SF Symbol name
    let color: Color
    var xPosition: CGFloat
    var yPosition: CGFloat
    let speed: CGFloat
    let size: CGFloat
}
```
- Represents a single falling rank symbol in the main menu animation.
- Tracks symbol, color, position, speed, and size.
- `Identifiable` for use in `ForEach`.

### Hand Type Model
```swift
enum HandType: String {
    case pair
    case miniStraight
    case miniFlush
    case miniStraightFlush
    case miniRoyalFlush
    case threeOfAKind
    case twoPair
    case nearlyStraight
    case nearlyFlush
    case nearlyStraightFlush
    case nearlyRoyalFlush
    case fourOfAKind
    case straight
    case flush
    case fullHouse
    case straightFlush
    case royalFlush
    
    var score: Int {
        switch self {
        case .pair: return 15
        case .miniStraight: return 25
        case .miniFlush: return 30
        case .miniStraightFlush: return 35
        case .miniRoyalFlush: return 40
        case .threeOfAKind: return 45
        case .twoPair: return 50
        case .nearlyStraight: return 55
        case .nearlyFlush: return 60
        case .nearlyStraightFlush: return 65
        case .nearlyRoyalFlush: return 70
        case .fourOfAKind: return 75
        case .straight: return 80
        case .flush: return 85
        case .fullHouse: return 90
        case .straightFlush: return 95
        case .royalFlush: return 100
        }
    }
    
    var displayName: String {
        switch self {
        case .pair: return "Pair"
        case .miniStraight: return "Mini Straight"
        case .miniFlush: return "Mini Flush"
        case .miniStraightFlush: return "Mini Straight Flush"
        case .miniRoyalFlush: return "Mini Royal Flush"
        case .threeOfAKind: return "Three of a Kind"
        case .twoPair: return "Two Pair"
        case .nearlyStraight: return "Nearly Straight"
        case .nearlyFlush: return "Nearly Flush"
        case .nearlyStraightFlush: return "Nearly Straight Flush"
        case .nearlyRoyalFlush: return "Nearly Royal Flush"
        case .fourOfAKind: return "Four of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}
```
- Comprehensive hand type enumeration
- Score calculation for each hand type
- Display name for UI presentation
- Prioritized hand detection order

### Connection Model
```swift
struct Connection: Identifiable, Equatable {
    let id = UUID()
    let fromCard: Card
    let toCard: Card
    let fromPosition: AnchorPoint.Position
    let toPosition: AnchorPoint.Position
}
```
- Connection identification
- Source and destination cards
- Anchor point positions
- Equatable conformance

### Anchor Point Model
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
- Position enumeration
- Point coordinates
- Corner handling
- Equatable conformance

### Connection Graph Model
```swift
private struct ConnectionGraph {
    var nodes: Set<ConnectionNode>
    var edges: Set<ConnectionEdge>
    
    func findMinimumSpanningTree() -> Set<ConnectionEdge>
}
```
- Graph representation
- Node and edge management
- Minimum spanning tree algorithm
- Connection optimization

### Mesh Gradient Model
```swift
struct MeshGradientState {
    enum Position {
        case first, second, third, fourth
    }
    
    var currentPosition: Position
    var points: [SIMD2<Float>]
    var colors: [Color]
    var backgroundColor: Color
}
```
- Position tracking
- Point coordinates
- Color management
- Animation state

## View Layer Components

### Main Menu View
- Simplified entry point to the game.
- Displays the game title ("Poker Slam") using `GradientText` and `.appTitle` style.
- Displays a "tap to start" message using `IntroMessageTextStyle`.
- Tapping anywhere triggers a full-screen transition to `GameView`.
- Contains no navigation buttons for settings or instructions.

### Game View
- Main game interface
- View composition: Organizes content using `gameHeader` and `gameMainContent` computed properties.
- State observation: Observes `GameViewModel` and `GameState`.
- User interaction: Handles card selection taps, exit button (`CircularIconButton`), and help button (`CircularIconButton`) taps.
- Layout management: Uses `VStack`, `HStack`, `ZStack`, `Spacer` for layout.
- Header: Displays score (with animation), exit button, and help button to toggle `HandReferenceView` overlay.
- Hand Reference Presentation: Manages the presentation of `HandReferenceView` as an overlay using `@State var showingHandReference`.

### Hand Reference View
- **Presentation:** Rendered as an overlay within `GameView`, toggled by the help button in the `GameView` header.
- **Structure:** Contains a dedicated header with a `CircularIconButton` for dismissal, a `ScrollView` for content, and utilizes `SectionHeader` and `HandReferenceRow` for displaying hand details.
- **Content:** Shows instructional text, poker hand rankings, and scores.
- **UI Details:** Uses custom fonts (`.handReference*`), an `.ultraThinMaterial` background, a bottom fade gradient, and an opacity transition.
- **Mini Card Previews:** `HandReferenceRow` includes a helper function (`parseExampleCards`) to extract card examples from description strings and renders them using `CardView` with a `.mini` style.

### Card Grid View
- Card layout
- Selection handling
- Animation coordination
- Empty space management
- Grid maintenance

### Connection Lines View
- Line rendering
- Animation handling
- Path calculation
- Visual feedback
- Performance optimization

### Connection Lines Layer
- Connection management
- Frame tracking
- Animation coordination
- Visual effects
- Performance optimization

### Mesh Gradient Background
- Background rendering
- Position animation
- Color management
- iOS version handling
- Performance optimization

### GradientText (New Component)
```swift
struct GradientText<Content: View>: View {
    let content: Content // Accepts any View
    let font: Font
    let tracking: CGFloat
    let isAnimated: Bool
    // ... init and body ...
}
```
- Reusable component for text with animated mesh gradient.
- Uses lighter color palette and shadow effect.
- Accepts a ViewBuilder for flexible content (e.g., GlyphAnimatedText).
- Applied to intro message, game over message, hand/score text.

### Falling Ranks View
- Renders the falling suit symbols animation for the main menu background.
- Uses `Canvas` and `TimelineView` for efficient rendering.
- Manages its own state for rank positions and spawning.
- Applies `FallingRankSymbolEffectModifier` for iOS 17+ pulsing effect.

## View Model Layer Components

### Game ViewModel
- Game state management
- Card selection logic
- Score calculation
- Hand detection
- Animation coordination
- Manages state for success (`isSuccessState`) and reset (`isResetting`) animations.
- Manages error animation state (`isErrorState`, `errorAnimationTimestamp`).
- Triggers appropriate haptic feedback for various actions (selection, success, error, reset).

### Connection ViewModel
- Connection management
- Path optimization
- Animation timing
- Visual effects
- Performance monitoring

### Background ViewModel
- Gradient state management
- Position animation
- Color coordination
- iOS version handling
- Performance optimization

### Haptic Feedback State (Conceptual)
- `GameViewModel` directly manages and triggers feedback generators.
- Generators include `UISelectionFeedbackGenerator`, `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`.
- Feedback is tied to specific game actions (selection, success, error, reset, card movement).

## State Management

### Game State
```swift
class GameState: ObservableObject {
    @Published var currentScore: Int
    @Published var highScore: Int
    @Published var isGameOver: Bool
    @Published var selectedCards: Set<Card>
    @Published var eligibleCards: Set<Card>
}
```
- Score tracking
- Game status
- Selection state
- Eligibility tracking

### Connection State
```swift
class ConnectionState: ObservableObject {
    @Published var connections: [Connection]
    @Published var cardFrames: [UUID: CGRect]
    @Published var isAnimating: Bool
}
```
- Connection tracking
- Frame management
- Animation state
- Visual effects

### Background State
```swift
class BackgroundState: ObservableObject {
    @Published var currentPosition: MeshGradientState.Position
    @Published var isAnimating: Bool
    @Published var colors: [Color]
}
```
- Position tracking
- Animation state
- Color management
- iOS version handling

### 3. **State Updates**
- Reactive updates through SwiftUI
- Atomic state changes
- Predictable state flow
- State updates triggering animations (e.g., in `FallingRanksView`) are handled within `.onChange` modifiers rather than directly during view drawing (`Canvas` closure) to ensure proper update cycles and avoid potential state propagation issues.

## Data Flow

### User Interaction Flow
1. User selects card
2. ViewModel updates selection state
3. Connection system updates
4. Visual feedback provided
5. Game state updated

### Connection Flow
1. Cards selected
2. Graph created
3. Minimum spanning tree found
4. Connections rendered
5. Animation triggered

### Background Flow
1. Position state updated
2. Animation triggered
3. Colors interpolated
4. Visual effect rendered
5. Next position scheduled

### Button Animation Flow
1. Button appears (e.g., "Play hand" when >= 2 cards selected).
2. Entrance animation plays (scale, opacity, text glyph reveal).
3. User taps button.
4. Action triggers corresponding ViewModel logic (playHand or resetGame).
5. ViewModel updates state (e.g., `isSuccessState` or `isResetting`).
6. `SuccessAnimationModifier` observes state change and plays scale/glow animation on the button.
7. ViewModel resets animation state after a delay.
8. If action was successful (playHand), button might disappear based on selection count changes.

## Design Patterns

### Observer Pattern
- State observation
- UI updates
- Animation coordination
- Event handling

### Factory Pattern
- Card creation
- Connection creation
- Animation creation
- State creation

### Strategy Pattern
- Hand detection
- Path finding
- Animation timing
- Color interpolation
- Prioritized hand validation

### Command Pattern
- User actions
- Game actions
- Animation actions
- State actions

## Testing Strategy

### Unit Tests
- Model logic
- ViewModel logic
- Game rules
- Connection logic
- Animation logic

### UI Tests
- User interaction
- Visual feedback
- Animation effects
- Layout behavior
- iOS version handling

### Performance Tests
- Animation smoothness
- Memory usage
- CPU usage
- Battery impact
- Response time

## Performance Considerations

### Memory Management
- Efficient data structures
- Proper cleanup
- Resource management
- Cache utilization
- SIMD2 optimization

### Animation Performance
- Efficient rendering
- Frame rate optimization
- Resource management
- State updates
- Visual effects

### Layout Performance
- Efficient layout
- View recycling
- Frame calculation
- Animation coordination
- Resource management

## Best Practices

### Code Organization
- Clear structure
- Proper documentation
- Consistent naming
- Modular design
- Version handling

### Error Handling
- Graceful degradation
- User feedback
- Error logging
- Recovery mechanisms
- iOS version fallbacks

### Security
- Data validation
- Input sanitization
- Secure storage
- Privacy compliance
- Version security

### Accessibility
- VoiceOver support
- Dynamic type
- Color contrast
- Motion reduction
- iOS version support

## Future Architecture Considerations

### 1. Scalability
- Modular component design
- Extensible architecture
- Feature isolation

### 2. Maintainability
- Clear component boundaries
- Consistent patterns
- Documentation

### 3. Performance
- State optimization
- Memory management
- UI efficiency

## Key Design Patterns

### 1. MVVM Pattern
- **Models**: Pure data structures (Card, Suit, Rank, CardPosition)
- **Views**: SwiftUI components (GameView, CardView)
- **ViewModels**: Business logic (GameViewModel, GameState)

### 2. Observable Pattern
- Uses `@Published` properties
- Leverages SwiftUI's `ObservableObject`
- Implements reactive updates

### 3. Dependency Injection
- ViewModels injected into Views
- State objects passed through environment
- Clean separation of concerns

### 4. Protocol-Oriented Design
- Value types for models
- Protocol conformance for shared behavior
- Extensible architecture

### 5. Adjacency Pattern
```swift
private func isAdjacent(position1: (row: Int, col: Int), position2: (row: Int, col: Int)) -> Bool {
    // Same column adjacency
    if position1.col == position2.col {
        return abs(position1.row - position2.row) <= 1
    }
    
    // Adjacent column check
    if abs(position1.col - position2.col) == 1 {
        // Check for empty columns between
        let minCol = min(position1.col, position2.col)
        let maxCol = max(position1.col, position2.col)
        for col in (minCol + 1)..<maxCol {
            if !cardPositions.contains(where: { $0.currentCol == col }) {
                return false
            }
        }
        return abs(position1.row - position2.row) <= 1
    }
    
    return false
}
```
- Manages card selection rules
- Handles empty column detection
- Validates adjacent positions

### 6. Card Shifting Pattern
```swift
// Process each column independently
for col in 0..<5 {
    let columnCards = cardPositions.filter { $0.currentCol == col }
        .sorted { $0.currentRow > $1.currentRow }
    
    // Shift cards down to fill empty positions
    for cardPosition in columnCards {
        if let cardIndex = cardPositions.firstIndex(where: { $0.id == cardPosition.id }) {
            let newRow = cardPosition.currentRow + emptyCount
            cardPositions[cardIndex].targetRow = newRow
        }
    }
}
```
- Handles card movement after selection
- Manages empty position filling
- Coordinates animations

## State Management

### 1. Local State
- View-specific state using `@State`
- Component-level state management
- UI-specific temporary state

### 2. Global State
- Game-wide state using `@StateObject`
- Shared state through environment
- Persistent state management

### 3. State Updates
- Reactive updates through SwiftUI
- Atomic state changes
- Predictable state flow
- State updates triggering animations (e.g., in `FallingRanksView`) are handled within `.onChange` modifiers rather than directly during view drawing (`Canvas` closure) to ensure proper update cycles and avoid potential state propagation issues.

## Performance Considerations

### 1. Memory Management
- Value types for models
- Efficient collection types
- Proper memory allocation

### 2. UI Performance
- Lazy loading of views
- Efficient view updates
- Optimized animations

### 3. State Updates
- Batched updates
- Efficient state propagation
- Minimal view refreshes

## Testing Strategy

### 1. Unit Tests
- Model validation
- ViewModel logic
- State management

### 2. UI Tests
- User interactions
- View hierarchy
- State updates

### 3. Integration Tests
- Component interactions
- Data flow
- State propagation

## Future Architecture Considerations

### 1. Scalability
- Modular component design
- Extensible architecture
- Feature isolation

### 2. Maintainability
- Clear component boundaries
- Consistent patterns
- Documentation

### 3. Performance
- State optimization
- Memory management
- UI efficiency

## Best Practices

1. **Code Organization**
   - Clear file structure
   - Consistent naming
   - Logical grouping

2. **SwiftUI Usage**
   - Declarative syntax
   - View composition
   - State management

3. **Swift Features**
   - Modern Swift features
   - Type safety
   - Protocol-oriented design

4. **Testing**
   - Unit test coverage
   - UI test automation
   - Integration testing

## UI Components

### Button System

The button system in PokerSlam implements a sophisticated animation and visual effects architecture that creates engaging, interactive elements throughout the app.

#### PrimaryButton

The `PrimaryButton` component serves as the main action button throughout the application, featuring:

- **Mesh Gradient Background**: Uses `MeshGradientBackground2` with masking and overlays for a premium visual effect
- **Glyph-by-Glyph Text Animation**: Implements sequential character animation with spring effects via `GlyphAnimatedText`
- **Icon Integration**: Supports optional SF Symbols with matching mesh gradient effects
- **Entrance/Exit Animations**: Smooth transitions for button appearance and disappearance
- **Visual Feedback**: Provides clear visual cues for user interactions, including success (scale/glow) and error (wiggle) animations driven by ViewModel state
- **Optimized State Management**: Enhanced state handling for rapid interactions
- **Combined Transitions**: Uses `.opacity.combined(with: .move(edge: .bottom))` for smooth animations
- **View-Level Animation**: Implements animations at the view level for better performance
- **Responsive State Updates**: Optimized for rapid card selections and state changes

#### PlayHandButtonContainer

The `PlayHandButtonContainer` component manages the "Play hand" button's visibility and animations:

- **State Management**: 
  - Uses `@State private var showButton: Bool` for visibility control
  - Tracks success and error animation states independently
  - Prevents animation conflicts during rapid interactions

- **Animation Architecture**:
  - View-level spring animation for smooth transitions
  - Combined opacity and slide effects for enhanced visual feedback
  - Optimized state updates for rapid card selections
  - Clear separation between animation and state logic

- **Interaction Handling**:
  - Manages button visibility based on card selection count
  - Prevents unwanted animations during success/error states
  - Maintains smooth transitions during rapid interactions
  - Coordinates with game state for proper timing

#### Animation Components

The button system includes several specialized components for animation:

1. **ButtonTextLabel**
   - Applies mesh gradient effects to text
   - Uses TimelineView for continuous animation
   - Implements cosine-based animation for organic movement
   - Masks the gradient to the text shape

2. **ButtonIconLabel**
   - Applies mesh gradient effects to SF Symbols
   - Uses TimelineView for continuous animation
   - Implements cosine-based animation for organic movement
   - Masks the gradient to the icon shape
   - Supports optional pulsing animation

3. **GlyphAnimatedText**
   - Implements glyph-by-glyph text animation
   - Uses sequential animation with configurable delay
   - Applies spring animation for each character
   - Combines opacity, offset, and blur transitions

4. **TextTransition**
   - Implements a custom transition for text
   - Uses AppearanceEffectRenderer for glyph animation
   - Supports spring-based animation for each character
   - Combines opacity, offset, and blur transitions

5. **AppearanceEffectRenderer**
   - Implements a custom text renderer for glyph animation
   - Uses spring-based animation for each character
   - Combines opacity, offset, and blur transitions
   - Supports emphasis attribute for selective animation

#### Animation Architecture

The button animation system follows a layered architecture:

1. **Base Layer**: Core button structure with mesh gradient background
2. **Text Layer**: Glyph-by-glyph animation with mesh gradient effects
3. **Icon Layer**: Optional icon with matching mesh gradient effects
4. **Transition Layer**: 
   - Enhanced entrance and exit animations
   - Combined opacity and slide effects
   - View-level spring animations
   - Optimized state management
5. **Interaction Layer**: 
   - Visual feedback for user interactions
   - Rapid state update handling
   - Animation conflict prevention
   - Smooth transition coordination

This architecture ensures:
- Consistent visual language across the app
- Smooth, engaging animations that enhance user experience
- Efficient performance through optimized rendering
- Flexible customization options for different contexts
- Responsive handling of rapid user interactions
- Clear separation of animation and state logic
- Specific haptic feedback integration for actions

#### GlyphAnimatedText

- Implements glyph-by-glyph text animation.
- Uses sequential animation with configurable delay (`animationDelay`).
- Applies spring animation for each character.
- Combines opacity, offset, and blur transitions.
- Replays animation when `text` changes.

### GradientText (New Component)

- Reusable component for text with animated mesh gradient.
- Uses lighter color palette and shadow effect.
- Accepts a ViewBuilder for flexible content (e.g., GlyphAnimatedText).
- Applied to intro message, game over message, hand/score text.

### Mesh Gradient Background

- Background rendering
- Position animation
- Color management
- iOS version handling
- Performance optimization

### GradientText (New Component)

- Reusable component for text with animated mesh gradient.
- Uses lighter color palette and shadow effect.
- Accepts a ViewBuilder for flexible content (e.g., GlyphAnimatedText).
- Applied to intro message, game over message, hand/score text. 