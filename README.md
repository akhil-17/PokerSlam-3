# PokerSlam

A modern iOS game that combines poker hand recognition with puzzle mechanics, built using SwiftUI and following MVVM architecture enhanced with a Service layer.

## 🎮 Overview

PokerSlam is an engaging puzzle game where players create poker hands by selecting cards in a 5x5 grid. The game challenges players to form valid poker hands by selecting adjacent cards while managing their card selection strategically. Players can create various poker hands like pairs, straights, flushes, and more to earn points.

### Key Features
- 5x5 grid of playing cards
- Support for forming poker hands with adjacent cards
- Real-time hand recognition and scoring (including correct Royal Flush detection)
- Haptic feedback for interactions
- High score tracking
- Hand reference guide
- Smooth animations and transitions using SwiftUI's animation system and `Task.sleep` for coordination.
- Modern, clean UI design with animated mesh gradient background
- Falling ranks animation on the main menu background
- Intelligent card adjacency rules
- **Corrected Dynamic Card Shifting:** Cards reliably shift down to fill empty spots, respecting the bottom rows first.
- **Corrected New Card Dealing:** New cards correctly fill the grid from the bottom-up, especially when the deck is low.
- Visual connection lines between selected cards
- Animated line drawing for enhanced visual feedback
- Optimized connection path finding for selected cards
- Comprehensive poker hand detection including mini straight flushes and nearly straight flushes
- Reusable gradient text component with lighter, animated mesh gradient styling and shadow effect
- Glyph-by-glyph text animation for key text elements (intro, game over, hand/score)
- Sequential glyph animation for hand name and score
- Continuous wave animation effect for specific text/icon elements (title, hand formation text)
- Animated score updates (tally and gradient pulse) managed by dedicated `ScoreAnimator` service.
- Replayable glyph animation when text content changes
- Shared success animation for "Play hand" and "Play again" buttons
- Distinct haptic feedback for game reset
- Simplified main menu (tap anywhere to start)
- Enhanced game header with score display, exit button, and help button for Hand Reference access.
- Updated HandReferenceView: Presented as an interactive overlay with `.ultraThinMaterial` background, top-right close button, custom fonts, mini card previews for examples, and a bottom fade gradient.
- **Coordinated Card Animations:** Precisely sequenced animations managed by `GameStateManager` for card removal (fade/scale out triggered, waits via `Task.sleep` for visual completion), shifting (spring animation driven by `currentRow` changes), and dealing new cards (spring animation, fills bottom-up).
- Adaptive layout respecting device safe areas.
- **Main Menu/Game Play States:** Clear separation managed by `GameView`.
- **High Score Display on Main Menu:** User's current high score is displayed at the top of the main menu if it's greater than zero, styled similarly to the in-game score.

### Game Rules
- Cards must be adjacent to be selected
- Adjacent means:
  - Same column, one row apart
  - Adjacent columns, one row apart (diagonal included)
- Empty columns break adjacency
- Cards shift down to fill empty positions completely before new cards appear.
- New cards are dealt into the lowest available empty spots first.
- Game ends when no valid, selectable hands can be formed with remaining cards on the grid or in the deck (if grid isn't full).
- Connection lines visually link selected cards to show relationships
- Hand detection prioritizes higher-ranking hands (e.g., straight flush over flush)

## 🎮 Technology Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel) with a dedicated Service layer (`GameStateManager`, `CardSelectionManager`, `ConnectionDrawingService`, `ScoreAnimator`, `HapticsManager`, `PokerHandDetector`).
- **State Management**:
  - SwiftUI's built-in tools (`@State`, `@StateObject`, `@Published`)
  - `ObservableObject` protocol for ViewModels and Services
  - Direct data binding (`.assign(to:)` in Combine) from Service `@Published` properties to ViewModel `@Published` properties.
  - Callbacks (e.g., `onNewCardsDealt`, `onSelectionChanged`) for signaling events and coordinating actions between ViewModel and Services.
  - `async/await` with `Task.sleep` in `GameStateManager` for sequencing animations and data updates.
- **Data Persistence**: UserDefaults for high scores
- **Design Patterns**:
  - Protocol-oriented programming (e.g., `HapticsManaging` for testability)
  - Value types (structs) for models
  - Observable pattern for state management
  - Dependency injection (via initializers, using protocols where applicable)
- **iOS Features**:
  - MeshGradient for iOS 18.0+ (with fallback for earlier versions)
  - SIMD2 for efficient vector operations
  - Advanced animation system
  - Comprehensive poker hand detection system
  - Core Haptics

## 📁 Project Structure

```
PokerSlam/
├── Views/                 # SwiftUI views
│   ├── GameView.swift     # Main game container (handles transitions between Main Menu and Game Play)
│   ├── CardView.swift     # Individual card view
│   ├── FallingRanksView.swift # Background animation for main menu
│   ├── HandReferenceView.swift # Poker hand reference overlay content
│   └── Components/        # Reusable UI components (Buttons, Gradients, Text Effects, etc.)
├── ViewModels/           # View models
│   └── GameViewModel.swift # Orchestrates Services, exposes state for GameView
├── Models/               # Data models (Card, HandType, CardPosition, etc.)
├── Services/             # Core game logic and state managers
│   ├── GameStateManager.swift # Manages deck, card positions, grid state, game logic (scoring, game over), animation coordination
│   ├── CardSelectionManager.swift # Handles card selection/deselection, eligibility checks, hand text display, UI states (error/success)
│   ├── ConnectionDrawingService.swift # Calculates connection lines based on selection
│   ├── ScoreAnimator.swift    # Manages score display animation logic (tally, pulse)
│   ├── HapticsManager.swift   # Centralizes haptic feedback generation
│   └── PokerHandDetector.swift # Detects poker hands
├── Protocols.swift       # Shared protocols (e.g., HapticsManaging)
├── Extensions/          # Swift extensions
│   └── Color+Hex.swift  # Color extension for hex color support
├── Resources/           # Assets and resources
│   ├── Assets.xcassets/ # Image assets
│   └── Fonts/          # Custom fonts
├── PokerSlamApp.swift   # App entry point
├── Preview Content/     # Assets for SwiftUI Previews
├── PokerSlam.xcodeproj # Xcode project file
└── docs/                # Documentation files
```

## 🎯 Design Patterns & Architecture

### MVVM Architecture with Service Layer
- **Models**: Pure data structures representing game entities and state.
- **Views**: SwiftUI views responsible for UI layout and presentation. `GameView` acts as a container managing the `mainMenu` and `gamePlay` states.
- **ViewModels**: Orchestrates data flow between Views and Services. `GameViewModel` centralizes dependencies, subscribes to service state updates (via Combine `.assign(to:)`), handles callbacks from services, and exposes curated state to `GameView`.
- **Services**: Encapsulate specific domains of game logic (e.g., `GameStateManager`, `CardSelectionManager`, `ScoreAnimator`, `HapticsManager`). They manage their own state (`@Published`) and provide functionalities accessed by the ViewModel. `GameStateManager` uses `async/await` and `Task.sleep` to coordinate the visual sequence of removing, shifting, and dealing cards.

### State Management
- **ViewModel State**: `GameViewModel` uses `@Published` properties to expose necessary state derived from underlying services to `GameView`.
- **Service State**: Services like `GameStateManager`, `CardSelectionManager`, `ScoreAnimator` manage their internal state using `@Published` properties, directly reflecting the source of truth for their domain.
- **Bindings**: SwiftUI bindings connect UI elements (like `CardView`, score display) directly to the `GameViewModel`'s published state.
- **Callbacks & Combine**: Services use callbacks (e.g., `onNewCardsDealt`, `onGameOverChecked`, `onSelectionChanged`) to notify `GameViewModel` of key events. ViewModel uses Combine's `.assign(to:)` to directly bind its state to the relevant service's state.

### Design Principles
- Protocol-oriented programming (using protocols like `HapticsManaging`)
- Value types for models
- Clean separation of concerns
- Reactive programming with SwiftUI
- Haptic feedback for enhanced UX
- Visual feedback through connection lines
- Advanced animation system leveraging SwiftUI's `.animation` modifiers and `async/await` with `Task.sleep` for coordination.

## 🚀 Getting Started

1. Clone the repository
2. Open `PokerSlam.xcodeproj` in Xcode
3. Build and run the project

## 🎨 UI/UX Features

- Separate Main Menu view with falling ranks animation and tap-to-start interaction.
- Game Header displaying score (with animation), exit button, and help button.
- Hand Reference guide presented as an interactive overlay within the game view.
- Dynamic card grid layout
- Smooth animations for card movements
- Haptic feedback for interactions
- Clear visual feedback for valid/invalid selections
- In-game hand reference guide accessible via icon button
- Responsive design for all iOS devices, respecting safe area insets.
- Animated connection lines between selected cards
- Rounded corner-aware connection points
- Animated mesh gradient background with position-based transitions
- Falling ranks background animation on main menu with blend modes and symbol effects (iOS 17+)
- Optimized connection path finding for selected cards
- Lighter mesh gradient styling with shadow for important text elements (intro, game over, hand/score)
- Glyph-by-glyph text animation for buttons and key text elements
- Continuous wave effect applied to animated glyphs (Title, Hand Formation Text)
- Sequential character animation (hand name then score) with spring effects and blur transitions
- Replayable glyph animation when text content changes
- Enhanced button animations with combined opacity and slide effects
- Shared success animation (scale/glow) for "Play hand" and "Play again" buttons
- Optimized state handling for rapid user interactions
- Responsive button visibility management
- Smooth entrance and exit transitions for action buttons
- Smooth crossfade transition for HandReferenceView overlay
- **Score Animation**: Dedicated `ScoreAnimator` service provides a smooth tally effect for score increments and a visual pulse animation on the score value itself.
- Specific haptic feedback for game reset action
- Simplified main menu: Tap anywhere to start the game
- **Updated Game Header:** Displays current score (driven by `ScoreAnimator`), provides an exit button (`X`) to return to the main menu, and a help button (`?`) to toggle the `HandReferenceView` overlay.
- **High Score on Main Menu:** The user's highest score is displayed at the top of the main menu (if greater than 0), using a refactored `ScoreDisplayView` component. Its background blur is disabled for a cleaner look on the menu.
- **Updated HandReferenceView:**
    - Presented as a modal overlay within the `GameView` using an `.ultraThinMaterial` background and a smooth opacity transition.
    - Features a dedicated header with a close button (`X`) using `CircularIconButton`.
    - Uses custom fonts (`.handReferenceInstruction`, `.handReferenceSectionHeader`, etc.) for better readability and consistent styling.
    - Includes mini card previews (`CardView(style: .mini)`) within each `HandReferenceRow` to visually represent example hands.
    - Implements a bottom fade gradient overlay for a polished look.
    - Contains `SectionHeader` and `HandReferenceRow` sub-components for structured content presentation.
- **Coordinated Card Animations:** Precisely sequenced and reliable animations managed by `GameStateManager`'s `removeCardsAndShiftAndDeal` function:
    1. Removal animation triggered (scale/fade out).
    2. `Task.sleep` waits for removal animation duration.
    3. Card data removed from `cardPositions`.
    4. Shift animation triggered (spring via `currentRow` change in `CardGridView`).
    5. `Task.sleep` waits for shift animation duration.
    6. New cards dealt (spring animation, filling bottom-up correctly).
- **Button Feedback:** Error wiggle animation on the "Play hand" button for invalid attempts.

## 🔧 Technical Implementation

### Card Selection System
- Supports selection in rows, columns, and diagonals
- Real-time validation of poker hands
- Smooth animations for card movements
- Haptic feedback for user interactions

### Scoring System
- Points based on poker hand rankings
- High score persistence using UserDefaults
- Real-time score updates
- New high score celebrations

### Connection System
- Intelligent path finding between selected cards
- Minimum spanning tree algorithm for optimal connections
- Support for straight and diagonal connections
- Animated line drawing with customizable appearance
- Rounded corner-aware connection points

### Background System
- Animated mesh gradient background for iOS 18.0+
- Position-based animation with smooth transitions
- Fallback to linear gradient for earlier iOS versions
- Customizable color palette and animation timing
- Mesh gradient text effects with sequential glyph animation
- Spring-based character animations with blur and opacity transitions

### Haptic Feedback System
- Centralized in `HapticsManager` (conforming to `HapticsManaging` protocol).
- Provides distinct feedback for selection, deselection, success (`playSuccessNotification`), error (`playErrorNotification`), reset (`playResetNotification`), card shifts (`playShiftImpact`), and new card deals (`playNewCardImpact`).
- Injected into relevant services/viewModels using the `HapticsManaging` protocol.

### Performance Optimizations
- Efficient card position tracking using `[CardPosition]`.
- Optimized hand recognition algorithms.
- Smooth animations using SwiftUI's declarative system and coordinated via `GameStateManager`.
- Memory-efficient data structures (structs for Models).
- SIMD2 for efficient vector operations

## 📱 Requirements

- iOS 15.0+ (with enhanced features for iOS 18.0+)
- Xcode 13.0+
- Swift 5.5+

## 🔄 Future Enhancements

- Multiplayer support
- Additional game modes
- Achievement system
- Social sharing
- Custom themes
- Tutorial system

## 📝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 