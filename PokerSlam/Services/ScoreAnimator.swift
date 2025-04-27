import Foundation
import SwiftUI // For @MainActor, @Published, withAnimation, Timer, RunLoop

@MainActor
final class ScoreAnimator: ObservableObject {
    @Published private(set) var displayedScore: Int = 0
    @Published private(set) var isScoreAnimating: Bool = false
    
    private var targetScore: Int = 0 // Internal target for animation
    private var scoreUpdateTimer: Timer?
    
    /// Updates the target score and starts the animation.
    func updateScore(_ newScore: Int) {
        // Handle instant reset to 0 (e.g., when score is set to 0 directly)
        if newScore == 0 && displayedScore != 0 { // Prevent animation if already 0
            stopTimer()
            isScoreAnimating = false
            displayedScore = 0
            targetScore = 0
            return
        }

        // Ensure target score is updated
        targetScore = newScore

        // Cancel existing timer if score changes during animation
        stopTimer()

        let difference = newScore - displayedScore
        guard difference != 0 else { return }

        // Start gradient animation
        withAnimation(.easeInOut(duration: 1.0)) {
            isScoreAnimating = true
        }

        // Configure tally animation parameters
        let steps = abs(difference)
        // Avoid division by zero if steps is 0 (shouldn't happen due to guard, but safety)
        guard steps > 0 else { 
             // If somehow difference is non-zero but steps is zero, just set final value
             displayedScore = targetScore
             withAnimation(.easeInOut(duration: 1.0)) {
                 isScoreAnimating = false
             }
             return
        }
        
        let totalDuration = Double(steps) * 0.01
        let clampedDuration = max(0.05, totalDuration)
        let timeInterval = max(0.005, clampedDuration / Double(steps))
        let increment = difference > 0 ? 1 : -1

        // Start the timer
        scoreUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] timer in
            // Ensure execution on the Main Actor
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                self.displayedScore += increment

                // Stop condition
                if (increment > 0 && self.displayedScore >= self.targetScore) || (increment < 0 && self.displayedScore <= self.targetScore) {
                    self.displayedScore = self.targetScore
                    self.stopTimer()
                    // Fade out gradient animation
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.isScoreAnimating = false
                    }
                }
            }
        }

        // Ensure timer runs during UI interactions
        if let timer = scoreUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Resets the displayed score and animation state.
    func resetScoreDisplay(initialScore: Int = 0) {
        stopTimer()
        isScoreAnimating = false
        displayedScore = initialScore // Sync displayed score with actual score
        targetScore = initialScore
    }
    
    /// Stops the score update timer.
    private func stopTimer() {
        scoreUpdateTimer?.invalidate()
        scoreUpdateTimer = nil
    }
} 