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
// Removal Delay:** A `Task.sleep` is now used after triggering the removal animation to allow it to play before data is removed from the source array.
- Standard opacity/scale transition for new card appearance.
- Smooth transitions.
// ... existing code ...
// ... rest of technical.md ...

### Service Layer Components

#### GameStateManager
// ... existing code ...
- **Communication**: Publishes state changes (`@Published`), provides callbacks (`onNewCardsDealt`, `onGameOverChecked`).
- **Dependencies:** Injected with `HapticsManaging`.

#### CardSelectionManager
// ... existing code ...
- **Dependencies:** Injected with `GameStateManager`, `HapticsManaging`.

#### ConnectionDrawingService
- **Purpose**: Calculates the visual connection paths between selected cards.
// ... existing code ...
- **Communication**: Publishes `connections` (`@Published`). Depends on `GameStateManager` and `CardSelectionManager` for input data.
- **Dependencies:** Injected with `GameStateManager`, `CardSelectionManager`.

#### ScoreAnimator
- **Purpose**: Handles the visual animation of the score updating.
- **State Managed**: `displayedScore: Int`, `isScoreAnimating: Bool`, `targetScore: Int` (internal).
- **Key Functions**: `updateScore(newScore: Int)`, `resetScoreDisplay()`. Animates `displayedScore` towards `targetScore` using a timer for the tally effect.
- **Communication**: Publishes `displayedScore` and `isScoreAnimating` (`@Published`).
- **Dependencies:** None.

#### HapticsManager
// ... existing code ...
### UI Components & Interactions

#### GameView
- **Role**: Container view managing transitions between Main Menu and Game Play.
- **State**: Uses `currentViewState`.
- **Orchestration**: Initializes `GameViewModel`.
// ... existing code ...
### Score Display
- **Role**: Renders the score label and value.
- **Animation**: Uses `.id()`/`.transition` for label crossfade, opacity changes based on `viewModel.isScoreAnimating` (driven by `ScoreAnimator`) for value pulse.
- **Data**: Binds to `viewModel.displayedScore` (sourced from `ScoreAnimator` via `GameViewModel`) and derives label content from `viewModel.score > gameState.currentScore`.

#### CardGridView
- **Role**: Displays the grid of `CardView`s.
// ... existing code ...
// ... rest of technical.md ... 