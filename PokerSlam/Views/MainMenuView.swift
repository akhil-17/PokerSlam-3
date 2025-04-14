import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var showingGame = false
    
    var body: some View {
        ZStack {
            // Mesh gradient background
            MeshGradientBackground()
            
            // VStack to center the title
            VStack {
                Spacer()
                GradientText(font: .appTitle) {
                    Text("Poker Slam")
                }
                Spacer()
            }
            .padding() // Add padding if needed around the title
            
            // VStack to position "tap to start" at the bottom
            VStack {
                Spacer() // Pushes the text down
                Text("tap to start")
                    .modifier(IntroMessageTextStyle()) // Apply the custom modifier
                    .padding(.bottom, 60) // Adjust padding from bottom as needed
            }
        }
        .onTapGesture {
            showingGame = true
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameView()
                .environmentObject(gameState)
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
} 