# PokerSlam

A modern iOS game that combines poker hand recognition with puzzle mechanics, built using SwiftUI and following MVVM architecture.

## 🎮 Overview

PokerSlam is an engaging puzzle game where players create poker hands by selecting cards in a 5x5 grid. The game challenges players to form valid poker hands by selecting adjacent cards while managing their card selection strategically. Players can create various poker hands like pairs, straights, flushes, and more to earn points.

### Key Features
- 5x5 grid of playing cards
- Support for forming poker hands with adjacent cards
- Real-time hand recognition and scoring
- Haptic feedback for interactions
- High score tracking
- Hand reference guide
- Smooth animations and transitions
- Modern, clean UI design with animated mesh gradient background
- Intelligent card adjacency rules
- Dynamic card shifting and filling
- Visual connection lines between selected cards
- Animated line drawing for enhanced visual feedback
- Optimized connection path finding for selected cards
- Comprehensive poker hand detection including mini straight flushes and nearly straight flushes
- Reusable gradient text component with lighter, animated mesh gradient styling and shadow effect
- Glyph-by-glyph text animation for key text elements (intro, game over, hand/score)
- Sequential glyph animation for hand name and score
- Replayable glyph animation when text content changes
- Shared success animation for "Play hand" and "Play again" buttons
- Distinct haptic feedback for game reset

### Game Rules
- Cards must be adjacent to be selected
- Adjacent means:
  - Same column, one row apart
  - Adjacent columns, one row apart (with no empty columns between)
- Empty columns break adjacency
- Cards shift down to fill empty positions
- New cards are added from the top
- Game ends when no valid hands can be formed with remaining cards
- Connection lines visually link selected cards to show relationships
- Hand detection prioritizes higher-ranking hands (e.g., straight flush over flush)

## 🎮 Technology Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: 
  - @Published properties
  - @StateObject for view models
  - @EnvironmentObject for global state
- **Data Persistence**: UserDefaults for high scores
- **Design Patterns**:
  - Protocol-oriented programming
  - Value types (structs) for models
  - Observable pattern for state management
  - Dependency injection
- **iOS Features**:
  - MeshGradient for iOS 18.0+ (with fallback for earlier versions)
  - SIMD2 for efficient vector operations
  - Advanced animation system
  - Comprehensive poker hand detection system

## 📁 Project Structure

```
PokerSlam/
├── Views/                 # SwiftUI views
│   ├── GameView.swift     # Main game interface
│   ├── CardView.swift     # Individual card view
│   ├── MainMenuView.swift # Main menu interface
│   ├── HandReferenceView.swift # Poker hand reference
│   └── Components/        # Reusable UI components
│       ├── SharedUI.swift # Shared UI components including MeshGradientBackground
│       ├── ConnectionLineView.swift # Connection line rendering
│       └── ConnectionLinesLayer.swift # Connection lines management
├── ViewModels/           # View models
│   └── GameViewModel.swift # Game logic and state management
├── Models/               # Data models
│   ├── Card.swift        # Card model
│   ├── HandType.swift    # Poker hand types
│   ├── Connection.swift  # Connection between cards
│   └── AnchorPoint.swift # Anchor point for connections
├── Extensions/          # Swift extensions
│   └── Color+Hex.swift  # Color extension for hex color support
├── Resources/           # Assets and resources
│   ├── Assets.xcassets/ # Image assets
│   └── Fonts/          # Custom fonts
└── PokerSlamApp.swift   # App entry point
```

## 🎯 Design Patterns & Architecture

### MVVM Architecture
- **Models**: Pure data structures (Card, HandType, Connection, AnchorPoint)
- **Views**: SwiftUI views for UI components
- **ViewModels**: GameViewModel handles game logic and state

### State Management
- **GameState**: Global state manager for scores and game settings
- **GameViewModel**: Manages game-specific state and logic
- **Published Properties**: For reactive UI updates

### Design Principles
- Protocol-oriented programming
- Value types for models
- Clean separation of concerns
- Reactive programming with SwiftUI
- Haptic feedback for enhanced UX
- Visual feedback through connection lines
- Advanced animation system with position-based transitions

## 🚀 Getting Started

1. Clone the repository
2. Open `PokerSlam.xcodeproj` in Xcode
3. Build and run the project

## 🎨 UI/UX Features

- Dynamic card grid layout
- Smooth animations for card movements
- Haptic feedback for interactions
- Clear visual feedback for valid/invalid selections
- Intuitive hand reference guide
- Responsive design for all iOS devices
- Animated connection lines between selected cards
- Rounded corner-aware connection points
- Animated mesh gradient background with position-based transitions
- Optimized connection path finding for selected cards
- Lighter mesh gradient styling with shadow for important text elements (intro, game over, hand/score)
- Glyph-by-glyph text animation for buttons and key text elements
- Sequential character animation (hand name then score) with spring effects and blur transitions
- Replayable glyph animation when text content changes
- Enhanced button animations with combined opacity and slide effects
- Shared success animation (scale/glow) for "Play hand" and "Play again" buttons
- Optimized state handling for rapid user interactions
- Responsive button visibility management
- Smooth entrance and exit transitions for action buttons
- Specific haptic feedback for game reset action

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

### Performance Optimizations
- Efficient card position tracking
- Optimized hand recognition algorithms
- Smooth animations using SwiftUI
- Memory-efficient data structures
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