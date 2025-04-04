# PokerSlam Architecture Documentation

## System Architecture Overview

PokerSlam follows a clean MVVM (Model-View-ViewModel) architecture pattern, designed specifically for SwiftUI. This architecture emphasizes:

- Clear separation of concerns
- Testability
- Maintainability
- SwiftUI integration
- Reactive state management

## Core Architectural Components

### 1. Presentation Layer (Views)

The presentation layer is built using SwiftUI and consists of:

#### Main Views
- `GameView`: The main game interface
- `CardGridView`: Manages the 5x5 grid layout
- `CardView`: Individual card representation

#### Component Views
- `ConnectionLineView`: Renders individual connection lines
- `ConnectionLinesLayer`: Manages all connection lines in the game
- `HandRecognitionView`: Displays hand recognition results
- `ScoreView`: Shows current score and statistics

### 2. Business Logic Layer (ViewModels)

The business logic layer handles game state and logic:

#### GameViewModel
- Manages game state
- Handles card selection
- Controls card shifting
- Manages connections between cards
- Processes hand recognition
- Calculates scores

### 3. Data Layer (Models)

The data layer consists of core game models:

#### Card Models
- `Card`: Represents a playing card
- `CardPosition`: Tracks card position in the grid
- `Suit`: Defines card suits
- `Rank`: Defines card ranks

#### Connection Models
- `Connection`: Represents a connection between two cards
- `AnchorPoint`: Defines connection points on cards

## Data Models

### Card Model
```swift
struct Card: Identifiable, Equatable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    var isSelected: Bool = false
    var isEligible: Bool = false
}
```

### Card Position Model
```swift
struct CardPosition: Equatable {
    let card: Card
    var currentRow: Int
    var currentCol: Int
    var targetRow: Int
    var targetCol: Int
}
```

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

## View Layer Components

### GameView
- Main container view
- Manages game state
- Coordinates subviews
- Handles user interactions

### CardView
- Displays individual cards
- Handles card selection
- Manages card animations
- Provides visual feedback

### ConnectionLineView
- Renders connection lines
- Implements line draw animation
- Supports customizable appearance
- Handles animation state

### ConnectionLinesLayer
- Manages all connection lines
- Calculates anchor points
- Tracks card frames
- Supports animation state

## ViewModel Layer Components

### GameViewModel
```swift
class GameViewModel: ObservableObject {
    @Published var cardPositions: [CardPosition] = []
    @Published var selectedCards: Set<Card> = []
    @Published var eligibleCards: Set<Card> = []
    @Published var connections: [Connection] = []
    
    // Game state management
    func updateConnections() {
        // Update connections based on selected cards
    }
    
    func selectCard(_ card: Card) {
        // Handle card selection
    }
    
    func shiftCards() {
        // Handle card shifting
    }
}
```

## State Management

### Published Properties
- Card positions
- Selected cards
- Eligible cards
- Connections
- Game state

### State Updates
- Reactive updates
- SwiftUI binding
- State synchronization
- UI updates

## Data Flow

1. User Interaction
   - Card selection
   - Game actions

2. ViewModel Processing
   - State updates
   - Connection management
   - Game logic

3. View Updates
   - UI refresh
   - Animation triggers
   - Visual feedback

## Design Patterns

### MVVM Pattern
- Clear separation of concerns
- SwiftUI integration
- Reactive updates

### Observer Pattern
- State observation
- UI updates
- Data synchronization

### Factory Pattern
- Card creation
- Connection creation
- Position management

## Testing Strategy

### View Tests
- UI component tests
- Interaction tests
- Animation tests

### ViewModel Tests
- State management tests
- Game logic tests
- Connection logic tests

### Model Tests
- Data model tests
- Validation tests
- Equality tests

## Performance Considerations

### Rendering Optimization
- Efficient connection line rendering
- Card frame tracking
- Animation performance

### State Management
- Minimal state updates
- Efficient data structures
- Optimized calculations

### Memory Management
- Proper cleanup
- Resource management
- State disposal

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