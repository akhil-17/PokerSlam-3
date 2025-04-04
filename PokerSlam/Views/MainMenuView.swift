import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var showingHowToPlay = false
    @State private var showingSettings = false
    @State private var showingGame = false
    
    var body: some View {
        ZStack {
            // Mesh gradient background
            MeshGradientBackground()
            
            VStack(spacing: 30) {
                Text("Poker Slam")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    NavigationButton(title: "Start", action: { showingGame = true })
                    NavigationButton(title: "How to Play", action: { showingHowToPlay = true })
                    NavigationButton(title: "Settings", action: { showingSettings = true })
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameView()
                .environmentObject(gameState)
        }
    }
}

struct NavigationButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
} 