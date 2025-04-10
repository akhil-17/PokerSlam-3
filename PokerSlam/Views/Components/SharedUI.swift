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
        SIMD2<Float>(0.00, 0.25), SIMD2<Float>(0.05, 0.05), SIMD2<Float>(1.00, 0.75),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.75, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let secondPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.75, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.75), SIMD2<Float>(0.95, 0.05), SIMD2<Float>(1.00, 0.25),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.25, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let thirdPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.25, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.25), SIMD2<Float>(0.95, 0.95), SIMD2<Float>(1.00, 0.75),
        SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.75, 1.00), SIMD2<Float>(1.00, 1.00)
    ]
    
    private let fourthPosition: [SIMD2<Float>] = [
        SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.75, 0.00), SIMD2<Float>(1.00, 0.00),
        SIMD2<Float>(0.00, 0.75), SIMD2<Float>(0.05, 0.95), SIMD2<Float>(1.00, 0.25),
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

/// A modifier that animates a view when it's removed from the hierarchy
struct ExitAnimationModifier: ViewModifier {
    @State private var isExiting = false
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Reset state
                isExiting = false
                isVisible = true
                
                // Animate in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
            .onDisappear {
                // Only animate if we're not already exiting
                if !isExiting {
                    isExiting = true
                    
                    // Animate out
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        scale = 0.8
                        opacity = 0
                    }
                }
            }
    }
}

/// A modifier that applies the standard PrimaryButton entrance and exit animations
struct PrimaryButtonAnimationModifier: ViewModifier {
    @State private var isVisible: Bool = false
    @State private var textOffset: CGFloat = 20
    @State private var buttonScale: CGFloat = 0.8
    @State private var buttonOpacity: Double = 0
    @State private var isButtonTapped: Bool = false
    
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(buttonScale)
            .opacity(buttonOpacity)
            .onAppear {
                // Reset state when button appears
                isButtonTapped = false
                
                // Animate the button appearance
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    buttonScale = 1.0
                    buttonOpacity = 1.0
                }
                
                // Trigger the text animation with minimal delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        isVisible = true
                    }
                }
            }
            .onDisappear {
                // Only animate if we're not already exiting
                if !isButtonTapped {
                    // Animate out - reverse of entrance animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        // First hide the text with the same animation as entrance
                        isVisible = false
                    }
                    
                    // Then scale down and fade out with a slight delay to match entrance sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                            buttonScale = 0.8
                            buttonOpacity = 0
                        }
                    }
                }
            }
    }
}

// MARK: - Text Transition Effect

struct EmphasisAttribute: TextAttribute {}

/// A text renderer that animates its content.
struct AppearanceEffectRenderer: TextRenderer, Animatable {
    /// The amount of time that passes from the start of the animation.
    /// Animatable.
    var elapsedTime: TimeInterval

    /// The amount of time the app spends animating an individual element.
    var elementDuration: TimeInterval

    /// The amount of time the entire animation takes.
    var totalDuration: TimeInterval

    var spring: Spring {
        .snappy(duration: elementDuration - 0.05, extraBounce: 0.4)
    }

    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    init(elapsedTime: TimeInterval, elementDuration: Double = 0.4, totalDuration: TimeInterval) {
        self.elapsedTime = min(elapsedTime, totalDuration)
        self.elementDuration = min(elementDuration, totalDuration)
        self.totalDuration = totalDuration
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for run in layout.flattenedRuns {
            if run[EmphasisAttribute.self] != nil {
                let delay = elementDelay(count: run.count)

                for (index, slice) in run.enumerated() {
                    // The time that the current element starts animating,
                    // relative to the start of the animation.
                    let timeOffset = TimeInterval(index) * delay

                    // The amount of time that passes for the current element.
                    let elementTime = max(0, min(elapsedTime - timeOffset, elementDuration))

                    // Make a copy of the context so that individual slices
                    // don't affect each other.
                    var copy = context
                    draw(slice, at: elementTime, in: &copy)
                }
            } else {
                // Make a copy of the context so that individual slices
                // don't affect each other.
                var copy = context
                // Runs that don't have a tag of `EmphasisAttribute` quickly
                // fade in.
                copy.opacity = UnitCurve.easeIn.value(at: elapsedTime / 0.2)
                copy.draw(run)
            }
        }
    }

    func draw(_ slice: Text.Layout.RunSlice, at time: TimeInterval, in context: inout GraphicsContext) {
        // Calculate a progress value in unit space for blur and
        // opacity, which derive from `UnitCurve`.
        let progress = time / elementDuration

        let opacity = UnitCurve.easeIn.value(at: 1.4 * progress)

        let blurRadius =
            slice.typographicBounds.rect.height / 16 *
            UnitCurve.easeIn.value(at: 1 - progress)

        // The y-translation derives from a spring, which requires a
        // time in seconds.
        let translationY = spring.value(
            fromValue: -slice.typographicBounds.descent,
            toValue: 0,
            initialVelocity: 0,
            time: time)

        context.translateBy(x: 0, y: translationY)
        context.addFilter(.blur(radius: blurRadius))
        context.opacity = opacity
        context.draw(slice, options: .disablesSubpixelQuantization)
    }

    /// Calculates how much time passes between the start of two consecutive
    /// element animations.
    ///
    /// For example, if there's a total duration of 1 s and an element
    /// duration of 0.5 s, the delay for two elements is 0.5 s.
    /// The first element starts at 0 s, and the second element starts at 0.5 s
    /// and finishes at 1 s.
    ///
    /// However, to animate three elements in the same duration,
    /// the delay is 0.25 s, with the elements starting at 0.0 s, 0.25 s,
    /// and 0.5 s, respectively.
    func elementDelay(count: Int) -> TimeInterval {
        let count = TimeInterval(count)
        let remainingTime = totalDuration - count * elementDuration

        return max(remainingTime / (count + 1), (totalDuration - elementDuration) / count)
    }
}

extension Text.Layout {
    /// A helper function for easier access to all runs in a layout.
    var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
        self.flatMap { line in
            line
        }
    }

    /// A helper function for easier access to all run slices in a layout.
    var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
        flattenedRuns.flatMap(\.self)
    }
}

struct TextTransition: Transition {
    static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }

    func body(content: Content, phase: TransitionPhase) -> some View {
        let duration = 0.9
        let elapsedTime = phase.isIdentity ? duration : 0
        let renderer = AppearanceEffectRenderer(
            elapsedTime: elapsedTime,
            totalDuration: duration
        )

        content.transaction { transaction in
            // Force the animation of `elapsedTime` to pace linearly and
            // drive per-glyph springs based on its value.
            if !transaction.disablesAnimations {
                transaction.animation = .linear(duration: duration)
            }
        } body: { view in
            view.textRenderer(renderer)
        }
    }
}

/// A primary action button with consistent styling across the app
struct PrimaryButton: View {
    // MARK: - Properties
    
    let title: String
    let icon: String?
    let action: () -> Void
    let isAnimated: Bool
    @State private var isVisible: Bool = false
    @State private var textOffset: CGFloat = 20
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String? = nil,
        isAnimated: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isAnimated = isAnimated
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // Execute the action immediately
            action()
        }) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.mainButton)
                    .offset(y: isVisible ? 0 : textOffset)
                    .opacity(isVisible ? 1 : 0)
                    .blur(radius: isVisible ? 0 : 5)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .if(isAnimated) { view in
                            view.modifier(PulsingAnimationModifier())
                        }
                        .offset(y: isVisible ? 0 : textOffset)
                        .opacity(isVisible ? 1 : 0)
                        .blur(radius: isVisible ? 0 : 5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 4)
            .background(
                MeshGradientBackground2()
                    .mask(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.5), lineWidth: 16)
                        .blur(radius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.25), lineWidth: 2)
                            .blur(radius: 12)
                            .blendMode(.overlay)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                            .blur(radius: 1)
                            .blendMode(.overlay)
                    )
            )
            .background(Color(hex: "#0D092B"))
            .cornerRadius(40)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(.black.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 20)
        }
        .padding()
        .modifier(PrimaryButtonAnimationModifier(action: action))
        .onAppear {
            // Trigger the text animation with minimal delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    isVisible = true
                }
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
        
        PrimaryButton(
            title: "Play hand",
            icon: "play.fill",
            isAnimated: true
        ) {
            print("Play hand tapped")
        }
        
        PrimaryButton(
            title: "Play again",
            icon: "arrow.clockwise",
            isAnimated: true
        ) {
            print("Play again tapped")
        }
    }
} 
