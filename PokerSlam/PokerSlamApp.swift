//
//  PokerSlamApp.swift
//  PokerSlam
//
//  Created by Akhil Dakinedi on 4/2/25.
//

import SwiftUI
import SwiftData

@main
struct PokerSlamApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(gameState)
        }
    }
}

// Global state manager
@MainActor
class GameState: ObservableObject {
    @Published private(set) var currentScore: Int = 0
    @Published private(set) var highScore: Int = 0
    
    init() {
        // Load high score from UserDefaults
        highScore = UserDefaults.standard.integer(forKey: "highScore")
    }
    
    func updateHighScore() {
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
    
    func updateCurrentScore(_ score: Int) {
        currentScore = score
        updateHighScore()
    }
}
