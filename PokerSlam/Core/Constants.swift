import Foundation
import SwiftUI // For Font

// MARK: - Grid Configuration

enum GridConstants {
    static let size = 5
    static let rows = 5
    static let columns = 5
    static let initialCardCount = rows * columns // 25
    static let maxHandSize = 5
    static let minHandSize = 2
}

// MARK: - Animation Timings & Parameters

enum AnimationConstants {
    // Initial Deal
    static let initialDealBaseDelay: TimeInterval = 0.1
    static let initialDealStagger: TimeInterval = 0.01

    // Card Shifting & Dealing (after play)
    static let cardShiftSpringResponse: TimeInterval = 0.3
    static let cardShiftSpringDamping: Double = 0.7
    // Duration matching the spring animation for sequencing async operations
    static let cardShiftDuration: TimeInterval = 0.4 // Approximation, matches response (Increased from 0.3)

    // New Card Dealing (can use same spring as shift or define separately)
    static let newCardDealSpringResponse: TimeInterval = 0.3
    static let newCardDealSpringDamping: Double = 0.7
    static let newCardDealDuration: TimeInterval = 0.3 // Approximation, matches response

    // Card View Animations
    static let cardSelectionSpringResponse: TimeInterval = 0.3
    static let cardSelectionSpringDamping: Double = 0.6
    static let cardSelectionSpring = Animation.spring(
        response: cardSelectionSpringResponse,
        dampingFraction: cardSelectionSpringDamping
    )
    
    static let cardPulseDuration: TimeInterval = 0.8
    static let cardPulseAnimation = Animation.easeInOut(duration: cardPulseDuration).repeatForever(autoreverses: true)
    static let cardDefaultAnimation = Animation.default


    // UI State Reset Delays (from GameViewModel)
    static let successStateResetDelay: TimeInterval = 1.0
    static let errorStateResetDelay: TimeInterval = 0.6
    static let gameResetDelay: TimeInterval = 0.5
    static let uiStateResetAnimation = Animation.easeOut(duration: 0.3)

    // General UI Animations
    static let defaultSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

}

// MARK: - UI Layout & Style Constants (from CardView)

enum CardUIConstants {
    // Standard Card
    static let standardWidth: CGFloat = 64
    static let standardHeight: CGFloat = 94
    static let standardSize = CGSize(width: standardWidth, height: standardHeight)
    static let standardCornerRadius: CGFloat = 8
    static let standardTextFont: Font = .system(size: 28, weight: .semibold, design: .rounded)
    static let standardSelectedShadowRadius: CGFloat = 8
    static let standardUnselectedShadowRadius: CGFloat = 2
    static let standardSelectedShadowY: CGFloat = 4
    static let standardUnselectedShadowY: CGFloat = 1
    static let standardSelectedStrokeWidth: CGFloat = 1.5
    static let standardUnselectedStrokeWidth: CGFloat = 1.0

    // Mini Card
    static let miniWidth: CGFloat = 45
    static let miniHeight: CGFloat = 66
    static let miniSize = CGSize(width: miniWidth, height: miniHeight)
    static let miniCornerRadius: CGFloat = 6
    static let miniTextFont: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let miniSelectedShadowRadius: CGFloat = 5
    static let miniUnselectedShadowRadius: CGFloat = 1
    static let miniSelectedShadowY: CGFloat = 2
    static let miniUnselectedShadowY: CGFloat = 0.5
    static let miniSelectedStrokeWidth: CGFloat = 1.0
    static let miniUnselectedStrokeWidth: CGFloat = 0.5

    // Shared
    static let selectedScaleEffect: CGFloat = 1.15
    static let unselectedScaleEffect: CGFloat = 1.0
    static let ineligibleOpacity: Double = 0.5
    static let eligibleOpacity: Double = 1.0
    
    // Shadow Colors
    static let selectedShadowColor = Color(hex: "#FFD302").opacity(0.3)
    static let unselectedShadowColor = Color(hex: "#191919").opacity(0.2)
    static let selectedStrokeColor = Color(hex: "#FFD302")
    static let unselectedStrokeColor = Color.clear // Explicitly clear
}

// MARK: - Font Definitions (Consider moving to a dedicated Theme file later)

extension Font {
    static let cardStandardText: Font = CardUIConstants.standardTextFont
    static let cardMiniText: Font = CardUIConstants.miniTextFont
    // Add other fonts as needed
} 