# PokerSlam Technical Documentation

## Project Technical Specifications

### Development Environment
- **Platform**: iOS 15.0+
- **Language**: Swift 5.5+
- **IDE**: Xcode 13.0+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **State Management**: SwiftUI's native state management system

### Project Structure
```
PokerSlam/
├── Views/                 # SwiftUI Views
├── ViewModels/           # View Models
├── Models/               # Data Models
├── Extensions/          # Swift Extensions
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

### 3. Card Shifting System

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

### 4. Game Over Detection

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

### 5. Hand Recognition System

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

### 6. Scoring System

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

### 7. Animation System

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