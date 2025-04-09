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
        Color(hex: "#8053DF"),
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

/// A view that displays an animated mesh gradient background with alternative colors.
/// The gradient continuously animates between different mesh positions
/// to create a dynamic visual effect.
struct MeshGradientBackground2: View {
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
        Color(hex: "#D5602B"),
        Color(hex: "#D45F2B"),
        Color(hex: "#AAAAAA"),
        Color(hex: "#4883D3"),
        Color(hex: "#FFD302"),
        Color(hex: "#AAAAAA"),
        Color(hex: "#4883D3"),
        Color(hex: "#50803A"),
        Color(hex: "#50803A")
    ]
    
    private let backgroundColor = Color(hex: "#0D092B")
    
    // MARK: - Position Arrays
    
    private let firstPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.25, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.25), SIMD2<Float>(0.10, 0.10), SIMD2<Float>(1.00, 0.75),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.75, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let secondPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.75, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.75), SIMD2<Float>(0.90, 0.10), SIMD2<Float>(1.00, 0.25),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.25, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let thirdPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.25, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.25), SIMD2<Float>(0.90, 0.90), SIMD2<Float>(1.00, 0.75),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.75, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let fourthPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.75, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.75), SIMD2<Float>(0.10, 0.90), SIMD2<Float>(1.00, 0.25),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.25, 1.00), SIMD2<Float>(1.00, 1.00)
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
            case .second: currentPosition = .third
            case .third: currentPosition = .fourth
            case .fourth: currentPosition = .first
            }
        }
        
        // Schedule the next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cyclePosition()
        }
    }
}

// MARK: - Custom Font Extensions

extension Font {
    /// Custom font style for main buttons in the app
    static var mainButton: Font {
        .custom("Kanit-SemiBold", size: 24)
    }
}

// MARK: - View Extensions

extension View {
    /// Conditionally applies a modifier based on a condition
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Custom Modifiers

/// A modifier that conditionally applies the symbol effect based on iOS version
struct SymbolEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.scale.up.byLayer, options: .repeat(.periodic(delay: 1.0)))
        } else {
            content
        }
    }
}

/// A modifier that applies a pulsing animation to any view
struct PulsingAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                // Add a slight delay before starting the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        MeshGradientBackground()
            .frame(height: 300)
        
        MeshGradientBackground2()
            .frame(height: 300)
    }
} 