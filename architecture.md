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

    SA -- Publishes displayedScore, isScoreAnimating --> VM; 
```

1.  **User Interaction**: `GameView` captures user taps (e.g., selecting a card, playing a hand) and calls corresponding methods on `GameViewModel`.
// ... existing code ...
3.  **Service Logic & State Update**: Services execute their logic (e.g., `CardSelectionManager` updates `selectedCards`, `GameStateManager` updates `cardPositions` and `score`, `ScoreAnimator` calculates `displayedScore` based on calls from `GameViewModel`). `GameStateManager` uses `async/await` and `Task.sleep` to sequence card removal, data update, shifting, and dealing.
4.  **State Publishing (Service -> ViewModel)**: Services publish their state changes via `@Published` properties. `GameViewModel` subscribes to these using Combine's `.assign(to:)` to directly update its own `@Published` properties (e.g., binding `scoreAnimator.$displayedScore` to `gameViewModel.$displayedScore`, `gameStateManager.$cardPositions` to `gameViewModel.$cardPositions`).
5.  **Callbacks (Service -> ViewModel)**: Services use callbacks (e.g., `onNewCardsDealt`, `onGameOverChecked` from `GameStateManager`, `onSelectionChanged` from `CardSelectionManager`) to signal completion of asynchronous tasks or significant events. `GameViewModel` implements these callbacks to trigger subsequent actions in other services (e.g., `onSelectionChanged` triggers `connectionDrawingService.updateConnections`).
6.  **State Publishing (ViewModel -> View)**: `GameViewModel` publishes the combined/relevant state to `GameView`.
7.  **UI Update**: `GameView` observes the ViewModel's `@Published` properties and automatically re-renders relevant parts of the UI.
// ... existing code ...
### Service Layer Components

### GameStateManager
- **Purpose**: Central manager for the core game state, including the deck, grid layout, scoring, and game over conditions.
- **State Managed**: `deck`, `cardPositions: [CardPosition]`, `score: Int`, `isGameOver: Bool`, `lastPlayedHand: HandType?`, `hasUserInteractedThisGame: Bool`.
- **Key Functions**: `setupDeck`, `dealInitialCards`, `removeCardsAndShiftAndDeal` (critical async function orchestrating the sequenced animation: trigger removal animation -> **await Task.sleep** -> update `cardPositions` data -> trigger shift animation -> **await Task.sleep** -> trigger deal animation), `shiftCardsDown`, `dealNewCardsToFillGrid` (fills empty spots bottom-up), `checkGameOver`, `canSelectCards`, `resetState`.
- **Communication**: Publishes state changes (`@Published` bound by ViewModel), provides callbacks (`onNewCardsDealt`, `onGameOverChecked`).
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
- **Purpose**: Handles the visual animation of the score updating in the UI, providing a tally effect and a visual pulse.
- **State Managed**: `displayedScore: Int` (the value shown in UI), `isScoreAnimating: Bool` (controls pulse animation).
- **Key Functions**: `updateScore(newScore: Int)` (starts tally animation towards `newScore`), `resetScoreDisplay()`. Uses internal timer for tally animation.
- **Communication**: Publishes `displayedScore` and `isScoreAnimating` (`@Published`, bound by `GameViewModel`).
- **Dependencies:** None.

### HapticsManager
// ... existing code ...
### Score Display
- **Role**: Renders the score label ("Score" or "New high score") and the animated score value.
- **Animation**: Score value pulses using opacity changes bound to `viewModel.isScoreAnimating` (driven by `ScoreAnimator`). The "New high score" label cross-fades using `.id()` and `.transition()`.
- **Data**: Binds to `viewModel.displayedScore` (sourced from `ScoreAnimator` via `GameViewModel`). Reads `viewModel.score` (from `GameStateManager` via VM) and `gameState.currentScore` (from EnvironmentObject) to determine the label text.

#### CardGridView
- **Role**: Displays the 5x5 grid of `CardView`s using `LazyVStack`/`LazyHStack`. Manages deselection taps.
- **Layout & Animation**: Position is determined by the `Lazy*Stack` layout. Card shifting animation is solely driven by changes to `CardPosition.currentRow`/`Col` and the `.animation(.spring...)` modifier on `CardView`. Removal animation uses `CardPosition.isBeingRemoved`. New cards fill bottom-up due to sorting logic in `GameStateManager.dealNewCardsToFillGrid`.
- **Dependencies:** Relies on `viewModel.cardPositions`, `viewModel.selectedCards`, `viewModel.eligibleCards` for rendering `CardView` states.
// ... existing code ...

</rewritten_file> 