\
// ... existing code ...
```mermaid
graph LR
    V[View Layer (GameView)] -- User Actions --> VM(ViewModel Layer <br/> GameViewModel);
    VM -- Calls Methods --> S((Service Layer));
    S -- Publishes State / Callbacks --> VM;
    VM -- Publishes State --> V;
    S --> M(Model Layer);
    VM --> M;

    subgraph Service Layer
        GSM[GameStateManager]
        CSM[CardSelectionManager]
        CDS[ConnectionDrawingService]
        SA[ScoreAnimator]
        HM[HapticsManager <br/> (HapticsManaging)]
        PHD[PokerHandDetector]
    end
// ... existing code ...
    CSM -- onSelectionChanged --> VM -- Update Connections --> CDS;
    CDS -- Publishes connections --> VM -- Publishes connections --> V;
    
    V -- Play Hand --> VM -- Play Hand Logic --> CSM;
    VM -- Update Score --> GSM;
    VM -- Animate Score --> SA;
    VM -- Play Haptics --> HM;
    VM -- Remove/Deal Cards --> GSM;
    GSM -- onNewCardsDealt --> VM -- Update Eligibility --> CSM;
    GSM -- onGameOverChecked --> VM;
```

1.  **User Interaction**: `GameView` captures user taps (e.g., selecting a card, playing a hand) and calls corresponding methods on `GameViewModel`.
// ... existing code ...
3.  **Service Logic & State Update**: Services execute their logic (e.g., `CardSelectionManager` updates `selectedCards`, `GameStateManager` updates `cardPositions` and `score`). `ScoreAnimator` updates `displayedScore` based on calls from `GameViewModel`.
4.  **State Publishing (Service -> ViewModel)**: Services publish their state changes via `@Published` properties. `GameViewModel` subscribes to these using Combine's `.assign(to:)` to update its own `@Published` properties (e.g., binding `scoreAnimator.$displayedScore` to `gameViewModel.$displayedScore`).
5.  **Callbacks (Service -> ViewModel)**: Services use callbacks (e.g., `onNewCardsDealt`) to signal completion of asynchronous tasks or significant events like animation sequences (e.g., after `GameStateManager` completes its coordinated removal/shift/deal sequence). `GameViewModel` implements these callbacks to trigger subsequent actions in other services.
6.  **State Publishing (ViewModel -> View)**: `GameViewModel` publishes the combined/relevant state to `GameView`.
7.  **UI Update**: `GameView` observes the ViewModel's `@Published` properties and automatically re-renders relevant parts of the UI.
// ... existing code ...
### Service Layer Components

### GameStateManager
- **Purpose**: Central manager for the core game state, including the deck, grid layout, scoring, and game over conditions.
- **State Managed**: `deck`, `cardPositions: [CardPosition]`, `score: Int`, `isGameOver: Bool`, `lastPlayedHand: HandType?`.
- **Key Functions**: `setupDeck`, `dealInitialCards`, `removeCardsAndShiftAndDeal` (orchestrates the sequenced animation: trigger removal -> **await Task.sleep** -> update data -> trigger shift -> await shift -> trigger deal), `shiftCardsDown`, `dealNewCardsToFillGrid`, `checkGameOver`, `canSelectCards`.
- **Communication**: Publishes state changes (`@Published`), provides callbacks (`onNewCardsDealt`, `onGameOverChecked`).
- **Dependencies:** Injected with `HapticsManaging`.
// ... existing code ...
- **Key Functions**: `selectCard`, `unselectAllCards`, `updateEligibleCards`, `updateCurrentHandText`, state setters/resetters (`setErrorState`, `setSuccessState`, `resetErrorState`, `resetSuccessState`, `reset`).
- **Communication**: Publishes state changes (`@Published`), provides callback (`onSelectionChanged`). Depends on `GameStateManager` for position data and adjacency checks.
- **Dependencies:** Injected with `GameStateManager`, `HapticsManaging`.

### ConnectionDrawingService
- **Purpose**: Calculates the visual connection paths between selected cards.
// ... existing code ...
- **Dependencies:** Injected with `GameStateManager`, `CardSelectionManager`.

### ScoreAnimator
- **Purpose**: Handles the visual animation of the score updating.
- **State Managed**: `displayedScore: Int`, `isScoreAnimating: Bool`, `targetScore: Int` (internal).
- **Key Functions**: `updateScore(newScore: Int)`, `resetScoreDisplay()`. Animates `displayedScore` towards `targetScore` using a timer for the tally effect and sets `isScoreAnimating` for the pulse.
- **Communication**: Publishes `displayedScore` and `isScoreAnimating` (`@Published`).
- **Dependencies:** None.

### HapticsManager
// ... existing code ...
### Score Display
- **Role**: Renders the score label and value.
- **Animation**: Uses `.id()`/`.transition` for label crossfade, opacity changes based on `viewModel.isScoreAnimating` (driven by `ScoreAnimator` via `GameViewModel`) for value pulse.
- **Data**: Binds to `viewModel.displayedScore` (sourced from `ScoreAnimator` via `GameViewModel`) and derives label content from `viewModel.score > gameState.currentScore`.

#### CardGridView
- **Role**: Displays the grid of `CardView`s.
// ... existing code ...

</rewritten_file> 