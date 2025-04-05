import SwiftUI
import simd

/// A view that displays an animated mesh gradient background.
/// The gradient continuously animates between different mesh positions
/// to create a dynamic visual effect.
struct MeshGradientBackground: View {
    // MARK: - Types
    
    /// Represents the different positions for the mesh gradient animation
    private enum MeshPosition {
        case first
        case second
        case third
        case fourth
    }
    
    // MARK: - Properties
    
    @State private var currentPosition: MeshPosition = .first
    
    private let gradientColors: [Color] = [
        Color(hex: "#260846"),
        Color(hex: "#35088A"),
        Color(hex: "#12196F"),
        Color(hex: "#3E00B9"),
        Color(hex: "#0D092B"),
        Color(hex: "#132A73"),
        Color(hex: "#260846"),
        Color(hex: "#1A196A"),
        Color(hex: "#12196F")
    ]
    
    private let backgroundColor = Color(hex: "#0D092B")
    
    // MARK: - Position Arrays
    
    private let firstPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.25, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.25, 0.25), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.75, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private let secondPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.75, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.75, 0.25), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.25, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private let thirdPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.75, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.25, 0.75), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.25, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private let fourthPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.25, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.75, 0.75), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.75, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    // MARK: - Computed Properties
    
    private var currentPoints: [SIMD2<Float>] {
        switch currentPosition {
        case .first: return firstPosition
        case .second: return secondPosition
        case .third: return thirdPosition
        case .fourth: return fourthPosition
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: currentPoints,
                colors: gradientColors,
                background: backgroundColor,
                smoothsColors: true
            )
            .ignoresSafeArea()
            .onAppear {
                cyclePosition()
            }
        } else {
            // Fallback for iOS versions before 18.0
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Private Methods
    
    private func cyclePosition() {
        withAnimation(.easeInOut(duration: 5)) {
            switch currentPosition {
            case .first: currentPosition = .second
            case .second: currentPosition = .fourth
            case .third: currentPosition = .first
            case .fourth: currentPosition = .third
            }
        }
        
        // Schedule the next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            cyclePosition()
        }
    }
}

// MARK: - Preview

#Preview {
    MeshGradientBackground()
} 