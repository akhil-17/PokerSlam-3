import Foundation
import SwiftUI // For UINotificationFeedbackGenerator

// Define protocols for dependency injection and testing

@MainActor
protocol HapticsManaging {
    // Define all methods used by other components
    func playSelectionChanged()
    func playDeselectionImpact()
    func playErrorNotification()
    func playSuccessNotification()
    func playResetNotification()
    func playShiftImpact()
    func playNewCardImpact()
    // Add any other methods from HapticsManager that are used elsewhere
    // func playSuccess() // Add if used
    // func playWarning() // Add if used
    // func playImpact(intensity: CGFloat) // Add if used
    // func prepare() // Likely not needed externally
}

// Add other protocols here as needed... 