# PokerSlam Architecture Documentation

## System Architecture Overview

PokerSlam follows a clean MVVM (Model-View-ViewModel) architecture pattern, designed with SwiftUI's declarative UI paradigm in mind. The architecture emphasizes separation of concerns, testability, and maintainability while leveraging Swift's modern features and best practices.

### Core Architectural Components

1. **Presentation Layer (Views)**
   - SwiftUI-based UI components
   - Declarative view hierarchy
   - Reactive UI updates through SwiftUI's data binding
   - Card grid layout with dynamic positioning

2. **Business Logic Layer (ViewModels)**
   - Game logic and state management
   - Data transformation and validation
   - User interaction handling
   - Card adjacency rules and validation
   - Card shifting and filling logic

3. **Data Layer (Models)**
   - Pure data structures
   - Business rules and validation
   - Domain-specific logic
   - Card position tracking

## Component Relationships

### 1. Data Models

#### Card Model
```swift
struct Card: Identifiable, Hashable {
    let id: UUID
    let suit: Suit
    let rank: Rank
}
```
- Core data structure representing a playing card
- Implements `Identifiable` for unique identification
- Implements `Hashable` for efficient collection operations
- Contains immutable properties for suit and rank

#### CardPosition Model
```swift
struct CardPosition: Identifiable {
    let id = UUID()
    let card: Card
    var currentRow: Int
    var currentCol: Int
    var targetRow: Int
    var targetCol: Int
}
```
- Tracks card positions in the grid
- Supports current and target positions for animations
- Manages card movement and adjacency

#### Suit Enum
```swift
enum Suit: String, CaseIterable, Hashable {
    case hearts, diamonds, clubs, spades
    var color: String
}
```
- Represents card suits
- Provides color information for UI rendering
- Implements `CaseIterable` for iteration support
- Implements `Hashable` for collection operations

#### Rank Enum
```swift
enum Rank: Int, CaseIterable, Hashable {
    case ace = 1, two = 2, ..., king = 13
    var display: String
}
```
- Represents card ranks
- Provides display string for UI
- Implements `CaseIterable` for iteration support
- Implements `Hashable` for collection operations

### 2. View Layer Components

#### GameView
- Main game interface
- Manages the 5x5 card grid
- Handles user interactions
- Coordinates with GameViewModel

#### CardView
```swift
struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isEligible: Bool
    let isInteractive: Bool
    let onTap: () -> Void
}
```
- Individual card representation
- Handles card selection states
- Manages visual feedback
- Provides interaction callbacks

#### MainMenuView
- Entry point interface
- Game options and settings
- High score display
- Game start/resume controls

### 3. ViewModel Layer

#### GameViewModel
```swift
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var cardPositions: [CardPosition]
    @Published private(set) var selectedCards: Set<Card>
    @Published private(set) var eligibleCards: Set<Card>
    @Published private(set) var score: Int
    @Published var isGameOver: Bool
}
```
- Manages game state
- Handles card selection logic
- Validates poker hands
- Controls game flow
- Manages scoring system

#### GameState
```swift
class GameState: ObservableObject {
    @Published var currentScore: Int
    @Published var highScore: Int
}
```
- Global state management
- Score tracking
- High score persistence
- Game settings

## Data Flow

1. **User Interaction Flow**
   ```
   User Action → View → ViewModel → Model → ViewModel → View Update
   ```

2. **State Management Flow**
   ```
   GameState → ViewModel → View → UI Update
   ```

3. **Card Selection Flow**
   ```
   Card Tap → CardView → GameViewModel → Hand Validation → Score Update → UI Refresh
   ```

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