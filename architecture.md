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
    *   `GameView` also directly observes `GameState.currentScore` (EnvironmentObject) to conditionally display the high score on the main menu using the `ScoreDisplayView` component.

## Data Flow (Example: Playing a Hand)

1.  `GameView` (specifically a button in `PlayHandButtonContainer`) calls `viewModel.playHand()`. 
// ... existing code ...
- **Dependencies:** None.

### HapticsManager
// ... existing code ...
### Score Display
- **Role**: Renders the score label ("Score" or "New high score") and the animated score value.
- **Animation**: Score value pulses using opacity changes bound to `viewModel.isScoreAnimating` (driven by `ScoreAnimator`). The "New high score" label cross-fades using `.id()` and `.transition()`.
- **Data**: Binds to `viewModel.displayedScore` (sourced from `ScoreAnimator` via `GameViewModel`). Reads `viewModel.score` (from `GameStateManager` via VM) and `gameState.currentScore` (from EnvironmentObject) to determine the label text.

(Note: The above "Score Display" section describes the functionality now encapsulated in the reusable `ScoreDisplayView` struct, which is used by `GameView` for both the in-game score header and the main menu high score display.)

#### CardGridView
- **Role**: Displays the 5x5 grid of `CardView`s using `LazyVStack`/`LazyHStack`. Manages deselection taps.
- **Layout & Animation**: Position is determined by the `Lazy*Stack` layout. Card shifting animation is solely driven by changes to `CardPosition.currentRow`/`Col` and the `.animation(.spring...)` modifier on `CardView`. Removal animation uses `CardPosition.isBeingRemoved`. New cards fill bottom-up due to sorting logic in `GameStateManager.dealNewCardsToFillGrid`.
- **Dependencies:** Relies on `viewModel.cardPositions`, `viewModel.selectedCards`, `viewModel.eligibleCards` for rendering `CardView` states.
// ... existing code ...

</rewritten_file> 