\
// ... existing code ...
│   ├── HandReferenceView.swift # Hand reference overlay content
│   │   └── ...              # Other components (e.g., PrimaryButton, CircularIconButton)
│   └── ...
├── ViewModels/           # View Models
│   └── GameViewModel.swift # Orchestrates Services, manages UI state for GameView
├── Models/               # Data Models
// ... existing code ...
│   ├── CardSelectionManager.swift # Handles card selection, eligibility, hand text state
│   ├── ConnectionDrawingService.swift # Calculates connection line paths
│   ├── ScoreAnimator.swift # Manages score display animation logic
│   ├── HapticsManager.swift # Centralizes haptic feedback
│   └── PokerHandDetector.swift # Contains logic for detecting all hand types
├── Extensions/          # Swift Extensions
// ... existing code ...
.animation(.spring(response: AnimationConstants.newCardDealSpringResponse, dampingFraction: AnimationConstants.newCardDealSpringDamping), value: cardPosition.isBeingRemoved)

// Appearance transition (for new cards)
.transition(.opacity.combined(with: .scale))

// Removal visual effect (applied to CardView)
// ... existing code ...
// Removal Delay:** A `Task.sleep` is used in `GameStateManager.removeCardsAndShiftAndDeal` after triggering the removal animation (`isBeingRemoved = true`) to allow the animation to visually complete before the corresponding `CardPosition` is removed from the data source.
// **Shift Delay:** A `Task.sleep` is used after triggering the shift animation (via `currentRow` updates) to allow it to visually complete before dealing new cards.
- Standard opacity/scale transition for new card appearance.
- Smooth transitions.
// ... existing code ...
// ... rest of technical.md ...

### Service Layer Components

#### GameStateManager
- **Purpose**: Manages core game state: deck, `cardPositions`, score, game over status. Orchestrates the critical sequence of removing played cards, shifting remaining cards, and dealing new cards with coordinated animations using `async/await` and `Task.sleep`.
- **State Managed**: `deck`, `cardPositions: [CardPosition]`, `score: Int`, `isGameOver: Bool`, `lastPlayedHand: HandType?`, `hasUserInteractedThisGame: Bool`.
- **Key Functions**: `setupDeck`, `dealInitialCards`, `removeCardsAndShiftAndDeal` (async function coordinating removal animation -> sleep -> data removal -> shift animation -> sleep -> deal animation), `shiftCardsDown` (calculates target rows), `dealNewCardsToFillGrid` (calculates and fills empty spots bottom-up), `checkGameOver`, `canSelectCards`, `resetState`.
- **Communication**: Publishes state changes (`@Published`), provides callbacks (`onNewCardsDealt`, `onGameOverChecked`).

#### CardSelectionManager
- **Purpose**: Manages user card selection state, validates selections based on adjacency rules, determines eligible cards for next selection, calculates and formats the current hand text, and manages UI states related to selection (error, success, animating text).
- **State Managed**: `selectedCards: Set<Card>`, `eligibleCards: Set<Card>`, `currentHandText: String?`, `isAnimatingHandText: Bool`, `isErrorState: Bool`, `errorAnimationTimestamp: Date?`, `isSuccessState: Bool`.
- **Key Functions**: `selectCard`, `unselectAllCards`, `updateEligibleCards` (based on selection and `GameStateManager` positions), `updateCurrentHandText`, `clearSelectionAfterPlay`, state setters/resetters (`setErrorState`, `setSuccessState`, etc.), `reset`.
- **Communication**: Publishes state changes (`@Published`), provides callback (`onSelectionChanged`). Depends on `GameStateManager` for position data and adjacency checks.

#### ConnectionDrawingService
- **Purpose**: Calculates the visual connection paths between selected cards.
// ... existing code ...
- **Communication**: Publishes `connections` (`@Published`). Depends on `GameStateManager` and `CardSelectionManager` for input data.
- **Dependencies:** Injected with `GameStateManager`, `CardSelectionManager`.

#### ScoreAnimator
- **Purpose**: Handles the visual animation of the score updating in the UI, providing a tally effect and a visual pulse.
- **State Managed**: `displayedScore: Int` (the value shown in UI), `isScoreAnimating: Bool` (controls pulse animation).
- **Key Functions**: `updateScore(newScore: Int)` (starts tally animation towards `newScore`), `resetScoreDisplay()`. Uses internal timer for tally animation.
- **Communication**: Publishes `displayedScore` and `isScoreAnimating` (`@Published`) for `GameViewModel` to bind to.

#### HapticsManager
// ... existing code ...

### UI Components & Interactions

#### GameView
- **Role**: Container view managing transitions between Main Menu (`mainMenuContent`) and Game Play (`gamePlayContent`) states using `currentViewState`.
- **State**: Manages `currentViewState`, `showingHandReference`, `isTitleWaveAnimating`. Uses `@StateObject` for `GameViewModel`.
- **Orchestration**: Initializes `GameViewModel`, handles state transitions, toggles `HandReferenceView` overlay.

#### ScoreDisplay (Refactored to `ScoreDisplayView` struct)
- **Role**: Renders the score label (e.g., "Score", "New high score", "High score") and the animated/static score value. Used in both `gameHeader` and `mainMenuContent`.
- **Parameters**: `label: String`, `score: Int`, `isAnimatingScoreValue: Bool`, `showBackgroundBlur: Bool`.
- **Features**: Conditionally displays a blurred background rectangle. Uses opacity toggling for animated vs. non-animated score text, with the animated path using `MeshGradientBackground2` and the non-animated path using `.colorDodge`. The animated text path has `.fixedSize(horizontal: false, vertical: true)` to prevent vertical greediness.
- **Animation**: Score value can pulse (driven by `isAnimatingScoreValue`). Label can cross-fade using `.id()`/`.transition`.
- **Data**: Binds to score values. Label text is passed in. `showBackgroundBlur` controls the visibility of its internal blurred rectangle background.

#### CardGridView
- **Role**: Displays the 5x5 grid of `CardView`s within a `LazyVStack` and `LazyHStack`. Handles tap gestures for deselecting cards.
- **Layout & Animation**: Relies on the `Lazy*Stack` structure and the `CardPosition` data provided by `GameViewModel`. Card shifting animation is driven *solely* by changes to `cardPosition.currentRow`/`cardPosition.currentCol` paired with the `.animation(.spring..., value: ...)` modifiers on the `CardView`. The `.offset` modifier was removed. Removal animation is triggered by `cardPosition.isBeingRemoved`.
- **Data**: Iterates over `viewModel.cardPositions`. Uses `GeometryReader` to track card frames for `ConnectionLinesLayer`.

// Card Shifting Animation (driven by changes in CardPosition.currentRow/Col)
.animation(.spring(response: AnimationConstants.cardShiftSpringResponse, dampingFraction: AnimationConstants.cardShiftSpringDamping), value: cardPosition.currentRow)
.animation(.spring(response: AnimationConstants.cardShiftSpringResponse, dampingFraction: AnimationConstants.cardShiftSpringDamping), value: cardPosition.currentCol)

// Card Removal Animation (driven by CardPosition.isBeingRemoved)
.animation(.spring(response: AnimationConstants.newCardDealSpringResponse, dampingFraction: AnimationConstants.newCardDealSpringDamping), value: cardPosition.isBeingRemoved)
// ... existing code ...
// Removal Delay:** A `Task.sleep` is used in `GameStateManager.removeCardsAndShiftAndDeal` after triggering the removal animation (`isBeingRemoved = true`) to allow the animation to visually complete before the corresponding `CardPosition` is removed from the data source.
// **Shift Delay:** A `Task.sleep` is used after triggering the shift animation (via `currentRow` updates) to allow it to visually complete before dealing new cards.
- Standard opacity/scale transition for new card appearance.
- Smooth transitions.
// ... existing code ...
// ... rest of technical.md ... 