import SwiftUI

/// A view that displays an animated mesh gradient background.
/// The gradient continuously animates between different color combinations
/// to create a dynamic visual effect.
struct MeshGradientBackground: View {
    @State private var animateGradient = false
    
    private let gradientColors: [Color] = [
        Color(red: 0.1, green: 0.2, blue: 0.3),
        Color(red: 0.2, green: 0.3, blue: 0.4),
        Color(red: 0.3, green: 0.4, blue: 0.5)
    ]
    
    private let animationDuration: Double = 5.0
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

#Preview {
    MeshGradientBackground()
} 