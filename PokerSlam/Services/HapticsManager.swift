import SwiftUI // For UIImpactFeedbackGenerator etc.

@MainActor
final class HapticsManager {
    // Selection
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let deselectionFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Notifications
    private let errorFeedback = UINotificationFeedbackGenerator()
    private let successFeedback = UINotificationFeedbackGenerator()
    private let resetGameFeedback = UINotificationFeedbackGenerator()

    // Impacts
    private let shiftFeedback = UIImpactFeedbackGenerator(style: .light)
    private let newCardFeedback = UIImpactFeedbackGenerator(style: .soft)
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        selectionFeedback.prepare()
        deselectionFeedback.prepare()
        errorFeedback.prepare()
        successFeedback.prepare()
        resetGameFeedback.prepare()
        shiftFeedback.prepare()
        newCardFeedback.prepare()
    }
    
    // MARK: - Public Methods
    
    func playSelectionChanged() {
        selectionFeedback.selectionChanged()
    }
    
    func playDeselectionImpact() {
        deselectionFeedback.impactOccurred()
    }
    
    func playErrorNotification() {
        errorFeedback.notificationOccurred(.error)
    }
    
    func playSuccessNotification() {
        successFeedback.notificationOccurred(.success)
    }
    
    func playResetNotification() {
        resetGameFeedback.notificationOccurred(.success) // Assuming success is intended here
    }
    
    func playShiftImpact() {
        shiftFeedback.impactOccurred()
    }
    
    func playNewCardImpact() {
        newCardFeedback.impactOccurred()
    }
} 