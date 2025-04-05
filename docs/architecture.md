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

### Game View
- Main game interface
- View composition
- State observation
- User interaction
- Layout management

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

## View Model Layer Components

### Game ViewModel
- Game state management
- Card selection logic
- Score calculation
- Hand detection
- Animation coordination

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