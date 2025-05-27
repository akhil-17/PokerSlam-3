import SwiftUI
import simd

/// A view that displays an animated mesh gradient background.
/// The gradient continuously animates between different mesh positions
/// to create a dynamic visual effect.
struct MeshGradientBackground: View {
    // MARK: - Properties
    
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
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    // MARK: - Body
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation) { timeline in
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedPositions(for: timeline.date),
                    colors: gradientColors,
                    background: backgroundColor,
                    smoothsColors: true
                )
                .ignoresSafeArea()
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
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}

/// A view that displays an animated mesh gradient background with alternative colors.
/// The gradient continuously animates between different mesh positions
/// to create a dynamic visual effect.
struct MeshGradientBackground2: View {
    // MARK: - Properties
    
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
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    // MARK: - Body
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation) { timeline in
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedPositions(for: timeline.date),
                    colors: gradientColors,
                    background: backgroundColor,
                    smoothsColors: true
                )
                .ignoresSafeArea()
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
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}

// MARK: - Custom Font Extensions

extension Font {
    /// Custom font style for the app title
    static var appTitle: Font {
        .custom("Kanit-SemiBold", size: 48)
    }
    
    /// Custom font style for the game title (initially same as appTitle)
    static var gameTitle: Font {
        .custom("Kanit-SemiBold", size: 48)
    }
    
    /// Custom font style for main buttons in the app
    static var mainButton: Font {
        .custom("Kanit-SemiBold", size: 24)
    }
    
    /// Custom font style for intro message text
    static var introMessageText: Font {
        .custom("Kanit-Medium", size: 18)
    }
    
    /// Custom font style for hand formation text
    static var handFormationText: Font {
        .custom("Kanit-SemiBold", size: 20)
    }
    
    /// Custom font style for hand formation score text
    static var handFormationScoreText: Font {
        .custom("Kanit-SemiBold", size: 20)
    }
    
    /// Custom font style for game over and intro messages
    static var messageText: Font {
        .custom("Kanit-Medium", size: 18)
    }
    
    /// Custom font style for the score label (e.g., "SCORE")
    static var scoreLabel: Font {
        .custom("Kanit-Regular", size: 14) // Assuming subheadline maps roughly to size 14
    }
    
    /// Custom font style for the score value (e.g., "1234")
    static var scoreValue: Font {
        .custom("Kanit-SemiBold", size: 24)
    }
    
    /// Custom font style for the instruction text in HandReferenceView
    static var handReferenceInstruction: Font {
        .custom("Kanit-Medium", size: 18)
    }
    
    /// Custom font style for the section headers in HandReferenceView
    static var handReferenceSectionHeader: Font {
        .custom("Kanit-Regular", size: 14)
    }
    
    /// Custom font style for the hand title in HandReferenceRow
    static var handReferenceRowTitle: Font {
        .custom("Kanit-SemiBold", size: 20)
    }
    
    /// Custom font style for the description in HandReferenceRow
    static var handReferenceRowDescription: Font {
        .custom("Kanit-Regular", size: 18)
    }
    
    /// Custom font style for the score in HandReferenceRow
    static var handReferenceRowScore: Font {
        .custom("Kanit-SemiBold", size: 24)
    }

    // MARK: - Card Fonts (These are now defined in Core/Constants.swift)

    // Removed duplicate definitions:
    // static var cardStandardText: Font { ... }
    // static var cardMiniText: Font { ... }
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

/// A modifier that applies the standard styling for intro messages.
struct IntroMessageTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.introMessageText)
            .foregroundColor(.white.opacity(0.5))
            .blendMode(.colorDodge)
    }
}

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

/// A modifier that applies the breathe/pulse symbol effect for falling ranks
public struct FallingRankSymbolEffectModifier: ViewModifier {
    // Add public init if needed for external instantiation, but often not necessary for modifiers.
    // public init() {}
    
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
        } else {
            content // No effect on older versions
        }
    }
}

/// A modifier that applies a pulsing animation to any view
struct PulsingAnimationModifier: ViewModifier {
    let isActive: Bool
    @State private var readyToPulse = false // Internal state to delay start

    func body(content: Content) -> some View {
        let shouldPulse = isActive && readyToPulse
        content
            .scaleEffect(shouldPulse ? 1.2 : 1.0)
            .animation(
                shouldPulse ?
                    Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                    : .default,
                value: shouldPulse // Animate based on the combined state
            )
            .onAppear {
                // Reset internal state on appear
                readyToPulse = false
                // If active, schedule the pulse start after a delay
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Check isActive again in case it changed during the delay
                        if isActive {
                            readyToPulse = true
                        }
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if !newValue {
                    // Reset if becomes inactive
                    readyToPulse = false
                } else {
                    // If it becomes active later, trigger the pulse after delay
                    // (This might handle cases where the button appears inactive then becomes active)
                    readyToPulse = false // Ensure reset before scheduling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                         if isActive { // Check again
                             readyToPulse = true
                         }
                    }
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
    let isSuccessState: Bool
    let isErrorState: Bool
    
    init(action: @escaping () -> Void, isSuccessState: Bool = false, isErrorState: Bool = false) {
        self.action = action
        self.isSuccessState = isSuccessState
        self.isErrorState = isErrorState
    }
    
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
                // Only animate if we're not already exiting and not in success or error state
                if !isButtonTapped && !isSuccessState && !isErrorState {
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

/// A modifier that handles the celebratory success animation for buttons
struct SuccessAnimationModifier: ViewModifier {
    let isSuccess: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var isAnimating: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .overlay(
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.9),
                                    Color.orange.opacity(0.7),
                                    Color.red.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 200
                            )
                        )
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)
                        .blendMode(.hardLight)
                        .blur(radius: 120)
                    
                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color.yellow.opacity(0.7),
                                    Color.orange.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 2,
                                endRadius: 100
                            )
                        )
                        .scaleEffect(glowScale * 0.7)
                        .opacity(glowOpacity)
                        .blendMode(.colorDodge)
                        .blur(radius: 120)
                }
            )
            .onChange(of: isSuccess) { _, newValue in
                if newValue && !isAnimating {
                    print("🎉 Success animation triggered!")
                    isAnimating = true
                    
                    // Initial subtle scale down
                    withAnimation(.easeInOut(duration: 0.1)) {
                        scale = 0.9
                    }
                    
                    // Then rapid scale up with glow effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            scale = 1.1
                            glowOpacity = 1.0
                            glowScale = 1.5
                            
                        }
                        
                        // Fade out the glow and scale back down
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                scale = 0
                                glowOpacity = 0
                                glowScale = 2.0
                                
                            }
                            
                            // Reset animation state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                                isAnimating = false
                            }
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
    let isErrorState: Bool
    let errorAnimationTimestamp: Date?
    let isSuccessState: Bool
    @State private var isVisible: Bool = false
    @State private var textOffset: CGFloat = 20
    @State private var isWiggling: Bool = false
    @State private var isButtonTapped: Bool = false
    
    // State for wave animation
    @State private var initialAppearanceComplete = false
    @State private var isWaveAnimating = false
    @State private var waveLoopTask: Task<Void, Never>? = nil
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String? = nil,
        isAnimated: Bool = false,
        isErrorState: Bool = false,
        errorAnimationTimestamp: Date? = nil,
        isSuccessState: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isAnimated = isAnimated
        self.isErrorState = isErrorState
        self.errorAnimationTimestamp = errorAnimationTimestamp
        self.isSuccessState = isSuccessState
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            isButtonTapped = true
            action()
        }) {
            HStack(spacing: 8) {
                // Text with mesh gradient effect and sequential animation
                ButtonTextLabel(text: title, isWaveAnimating: isWaveAnimating)
                    .transition(TextTransition())
                    // Remove entrance/wiggle modifiers from ButtonTextLabel
                    // .offset(y: isVisible ? 0 : textOffset)
                    // .opacity(isVisible ? 1 : 0)
                    // .blur(radius: isVisible ? 0 : 5)
                    // .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: isVisible)
                    // .offset(x: isWiggling ? 5 : 0)
                    // .animation(
                    //     Animation.easeInOut(duration: 0.1)
                    //         .repeatCount(3, autoreverses: true),
                    //     value: isWiggling
                    // )
                
                if let icon = icon {
                    // Icon with mesh gradient effect - NO entrance/wiggle modifiers
                    ButtonIconLabel(systemName: icon, isAnimated: self.isAnimated)
                }
            }
            // Apply entrance/wiggle modifiers to the HStack
            .offset(y: isVisible ? 0 : textOffset)
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible ? 0 : 5)
            // Add animation for entrance tied to isVisible
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: isVisible)
            .offset(x: isWiggling ? 5 : 0)
            .animation(
                Animation.easeInOut(duration: 0.1)
                    .repeatCount(3, autoreverses: true),
                value: isWiggling
            )
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 4)
            .background(
                MeshGradientBackground2()
                    .mask(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.60), lineWidth: 8)
                            .blur(radius: 4)
                            .blendMode(.colorDodge)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color(hex: "#FFD302").opacity(0.6), lineWidth: 24) // Use yellow color
                            .blur(radius: 4) // Apply blur for the glow effect
                            .blendMode(.overlay) // Use colorDodge for glow
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(1), lineWidth: 2)
                            .blur(radius: 12)
                            .blendMode(.hardLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                            .blur(radius: 1)
                            .blendMode(.multiply)
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
        .modifier(PrimaryButtonAnimationModifier(action: action, isSuccessState: isSuccessState, isErrorState: isErrorState))
        .modifier(SuccessAnimationModifier(isSuccess: isSuccessState))
        .onChange(of: errorAnimationTimestamp) { oldValue, newValue in
            if newValue != nil && oldValue == nil {
                // Start the wiggle animation
                isWiggling = true
                
                // Reset after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isWiggling = false
                }
            }
        }
        .onAppear {
            // Delay setting initial appearance complete to allow entrance animation
            // Existing animation takes roughly 0.4s + 0.05s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                initialAppearanceComplete = true
            }

            // Trigger the text entrance animation with minimal delay (as before)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    isVisible = true
                }
            }
        }
        .onChange(of: initialAppearanceComplete) { _, newValue in
            // Start wave loop when initial appearance is complete
            if newValue {
                startWaveLoop()
            } else {
                stopWaveLoop()
            }
        }
        .onDisappear {
             stopWaveLoop()
        }
    }

    // MARK: - Wave Animation Loop Control
    
    private func startWaveLoop() {
        guard waveLoopTask == nil, initialAppearanceComplete else { return }
        
        waveLoopTask = Task { @MainActor in
            // Set state just before the loop starts
            isWaveAnimating = true
            
            // Loop keeps running as long as the button is visible and not cancelled
            while initialAppearanceComplete && !Task.isCancelled {
                do {
                    // Sleep for a short duration to prevent a tight loop and allow cancellation checks
                    try await Task.sleep(for: .milliseconds(100))
                } catch is CancellationError {
                    break // Exit loop if cancelled
                } catch {
                    break // Exit on other errors
                }
            }
            // Ensure wave animation stops when the loop finishes or is cancelled
            if Task.isCancelled {
                
            }
            isWaveAnimating = false
            waveLoopTask = nil // Clear the task reference
        }
    }
    
    private func stopWaveLoop() {
        if let task = waveLoopTask {
            task.cancel()
            waveLoopTask = nil
        }
        // Explicitly set animating to false, in case cancellation is delayed
        isWaveAnimating = false
    }
}

/// A view that displays text with a mesh gradient effect
struct ButtonTextLabel: View {
    let text: String
    let isWaveAnimating: Bool
    
    var body: some View {
        GlyphAnimatedText(text: text, isWaveAnimating: isWaveAnimating)
            .font(.mainButton)
            .foregroundStyle(.clear)
            .background(
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: animatedPositions(for: timeline.date),
                        colors: [
                            Color(hex: "#FFA87D"), // Lighter Orange-Red
                            Color(hex: "#FFB08A"), // Lighter Orange-Red
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#FFE76B"), // Lighter Yellow
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#90B884"), // Lighter Green
                            Color(hex: "#90B884")  // Lighter Green
                        ],
                        background: Color.clear,
                        smoothsColors: true
                    )
                }
            )
            .mask(
                GlyphAnimatedText(text: text, isWaveAnimating: isWaveAnimating)
                    .font(.mainButton)
            )
    }
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}

/// A view that animates text with a glyph-by-glyph appearance and optional wave effect
struct GlyphAnimatedText: View {
    let text: String
    let animationDelay: Double
    let isWaveAnimating: Bool
    var onGlyphAnimationComplete: (() -> Void)? = nil // Add completion handler
    
    @State private var visibleGlyphs: Int = 0
    
    // Convenience initializer if completion handler is not needed
    init(text: String, animationDelay: Double = 0.0, isWaveAnimating: Bool = false) {
        self.text = text
        self.animationDelay = animationDelay
        self.isWaveAnimating = isWaveAnimating
        self.onGlyphAnimationComplete = nil
    }
    
    // Initializer to accept completion handler
    init(text: String, animationDelay: Double = 0.0, isWaveAnimating: Bool = false, onComplete: (() -> Void)?) {
        self.text = text
        self.animationDelay = animationDelay
        self.isWaveAnimating = isWaveAnimating
        self.onGlyphAnimationComplete = onComplete
    }
    
    var body: some View {
        HStack(spacing: 0) {
            let characters = Array(text.enumerated())
            ForEach(characters, id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < visibleGlyphs ? 1 : 0)
                    .offset(y: index < visibleGlyphs ? 0 : 20)
                    .blur(radius: index < visibleGlyphs ? 0 : 5)
                    // Apply wave modifier to each character
                    .modifier(WaveEffectModifier(
                        isAnimating: isWaveAnimating && visibleGlyphs == text.count, // Only wave when fully visible
                        characterIndex: index,
                        characterCount: characters.count,
                        amplitude: 1.0,
                        frequency: 3.0, // Adjust frequency for wave speed
                        phaseShiftPerCharacter: 0.5 // Adjust for wave length
                    ))
            }
        }
        .id(text) // Use text as ID to trigger reset on change
        .onAppear {
            animateGlyphs()
        }
        .onChange(of: text) {
            animateGlyphs()
        }
        .onChange(of: isWaveAnimating) {
             // if newValue && visibleGlyphs < text.count { 
             //     // Body was empty, no action needed
             // }
        }
    }

    private func animateGlyphs() {
        visibleGlyphs = 0 // Ensure reset before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            let charCount = text.count
            guard charCount > 0 else { 
                onGlyphAnimationComplete?()
                return // No animation needed for empty string
            }

            for i in 0..<charCount {
                let glyphDelay = Double(i) * 0.03
                DispatchQueue.main.asyncAfter(deadline: .now() + glyphDelay) {
                    // Check if text changed during animation setup
                    guard self.text == text else { 
                        return 
                    }
                    if self.visibleGlyphs == i { // Animate only if it's the next glyph
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            visibleGlyphs = i + 1
                        }
                    } else {
                         // This can happen if resetAndAnimateGlyphs was called
                     }
                }
                
                // Schedule completion handler after the last glyph animation starts + its duration
                if i == charCount - 1 {
                    let lastGlyphSpringDuration = 0.4 // Approximate duration of the spring animation
                    let completionDelay = glyphDelay + lastGlyphSpringDuration + 0.1 // Add buffer
                    DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                        // Check if text is still the same before calling completion
                        if self.text == text {
                            onGlyphAnimationComplete?()
                        }
                    }
                }
            }
        }
    }

    private func resetAndAnimateGlyphs() {
        visibleGlyphs = 0 // Reset visibility immediately
        animateGlyphs() // Start animation for new text
    }
}

/// A view that displays an SF Symbol with a mesh gradient effect
struct ButtonIconLabel: View {
    let systemName: String
    let isAnimated: Bool
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(.clear)
            .background(
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: animatedPositions(for: timeline.date),
                        colors: [
                            Color(hex: "#FFA87D"), // Lighter Orange-Red
                            Color(hex: "#FFB08A"), // Lighter Orange-Red
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#FFE76B"), // Lighter Yellow
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#90B884"), // Lighter Green
                            Color(hex: "#90B884")  // Lighter Green
                        ],
                        background: Color.clear,
                        smoothsColors: true
                    )
                }
            )
            .mask(
                Image(systemName: systemName)
                    .font(.system(size: 16))
            )
            .modifier(PulsingAnimationModifier(isActive: isAnimated))
    }
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}

/// A reusable component that applies a mesh gradient effect to text
struct GradientText<Content: View>: View {
    let content: Content
    let font: Font
    let tracking: CGFloat
    let isAnimated: Bool
    let applyShadow: Bool

    init(
        font: Font,
        tracking: CGFloat = 0,
        isAnimated: Bool = false,
        applyShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.font = font
        self.tracking = tracking
        self.isAnimated = isAnimated
        self.applyShadow = applyShadow
    }

    var body: some View {
        content
            .font(font)
            .tracking(tracking)
            .foregroundStyle(.clear)
            .background(
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: animatedPositions(for: timeline.date),
                        colors: [
                            Color(hex: "#FFA87D"), // Lighter Orange-Red
                            Color(hex: "#FFB08A"), // Lighter Orange-Red
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#FFE76B"), // Lighter Yellow
                            Color(hex: "#CCCCCC"), // Lighter Gray
                            Color(hex: "#8BB8E8"), // Lighter Blue
                            Color(hex: "#90B884"), // Lighter Green
                            Color(hex: "#90B884")  // Lighter Green
                        ],
                        background: Color.clear,
                        smoothsColors: true
                    )
                }
            )
            .mask(
                content
                    .font(font)
                    .tracking(tracking)
            )
            // Conditionally apply the shadow
            .if(applyShadow) { view in
                view.shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .modifier(PulsingAnimationModifier(isActive: isAnimated))
    }
    
    // Base positions for the mesh gradient
    private let basePositions: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
    ]
    
    private func animatedPositions(for date: Date) -> [SIMD2<Float>] {
        let phase = CGFloat(date.timeIntervalSince1970)
        var animatedPositions = basePositions
        
        // Animate the middle control points using cosine waves
        // This creates a flowing, organic animation
        animatedPositions[1].x = 0.5 + 0.4 * Float(cos(phase))
        animatedPositions[3].y = 0.5 + 0.3 * Float(cos(phase * 1.1))
        animatedPositions[4].y = 0.5 - 0.4 * Float(cos(phase * 0.9))
        animatedPositions[5].y = 0.5 - 0.2 * Float(cos(phase * 0.9))
        animatedPositions[7].x = 0.5 - 0.4 * Float(cos(phase * 1.2))
        
        return animatedPositions
    }
}

// MARK: - Circular Icon Button

/// A circular button designed to display an SF Symbol icon.
struct CircularIconButton: View {
    let iconName: String
    let action: () -> Void

    private let buttonSize: CGFloat = 44
    private let iconSize: CGFloat = 16
    private let strokeWidth: CGFloat = 1
    private let strokeColor = Color(hex: "#d4d4d4").opacity(0.7)
    private let iconColor = Color(hex: "#d4d4d4").opacity(0.7)

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
                    .blendMode(.colorDodge)

                Image(systemName: iconName)
                    .font(.system(size: iconSize))
                    .foregroundColor(iconColor)
                    .blendMode(.colorDodge)
            }
            .frame(width: buttonSize, height: buttonSize)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack { // Use ZStack for layering
        MeshGradientBackground() // Background layer
            .ignoresSafeArea()

        VStack(spacing: 20) { // VStack for buttons on top
            PrimaryButton(
                title: "Play hand",
                icon: "play.fill",
                isAnimated: true,
                isErrorState: false,
                errorAnimationTimestamp: nil,
                isSuccessState: false
            ) {
                print("Play hand tapped")
            }
            
            PrimaryButton(
                title: "Play again",
                icon: "arrow.clockwise",
                isAnimated: true,
                isErrorState: false,
                errorAnimationTimestamp: nil,
                isSuccessState: false
            ) {
                print("Play again tapped")
            }
        }
        .padding() // Add padding around the VStack if needed
    }
} 

// MARK: - Animation Preview

struct AnimationPreview: View {
    @State private var isSuccessState = false
    @State private var isErrorState = false
    @State private var errorAnimationTimestamp: Date? = nil
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Animation Preview")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Success animation button
                VStack(spacing: 10) {
                    Text("Success Animation")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    PrimaryButton(
                        title: "Play hand",
                        icon: "play.fill",
                        isAnimated: true,
                        isErrorState: isErrorState,
                        errorAnimationTimestamp: errorAnimationTimestamp,
                        isSuccessState: isSuccessState
                    ) {
                        // Trigger success animation
                        isSuccessState = true
                        
                        // Reset after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSuccessState = false
                        }
                    }
                }
                
                // Error animation button
                VStack(spacing: 10) {
                    Text("Error Animation")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    PrimaryButton(
                        title: "Play hand",
                        icon: "play.fill",
                        isAnimated: true,
                        isErrorState: isErrorState,
                        errorAnimationTimestamp: errorAnimationTimestamp,
                        isSuccessState: isSuccessState
                    ) {
                        // Trigger error animation
                        isErrorState = true
                        errorAnimationTimestamp = Date()
                        
                        // Reset after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            isErrorState = false
                            errorAnimationTimestamp = nil
                        }
                    }
                }
                
                // Toggle button to manually trigger success state
                VStack(spacing: 10) {
                    Text("Manual Toggle")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Toggle("Success State", isOn: $isSuccessState)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview("Animation Preview") {
    AnimationPreview()
} 

// MARK: - Wave Animation Modifier

@MainActor
struct WaveEffectModifier: ViewModifier {
    let isAnimating: Bool
    let characterIndex: Int
    let characterCount: Int
    let amplitude: CGFloat
    let frequency: Double
    let phaseShiftPerCharacter: Double
    
    @State private var time: TimeInterval = 0.0
    // State for smooth transition
    @State private var transitionProgress: CGFloat = 0.0
    private let transitionDuration: TimeInterval = 0.5 // Duration for wave to ramp up
    
    func body(content: Content) -> some View {
        content
            .offset(y: calculateOffsetY())
            // Apply animation only to the transitionProgress changes, not the time-driven offset
            .animation(.smooth(duration: transitionDuration), value: transitionProgress)
            .background(
                TimelineView(.animation(minimumInterval: 0.016, paused: !isAnimating)) { timeline in
                    Color.clear
                        .onChange(of: timeline.date) { _, newDate in
                            // Update time state based on timeline only if animating
                            if isAnimating {
                                self.time = newDate.timeIntervalSinceReferenceDate
                            }
                        }
                }
            )
            .onChange(of: isAnimating) { _, newValue in
                // Animate transitionProgress when isAnimating changes
                if newValue {
                    // Start transition to full wave
                    transitionProgress = 1.0
                } else {
                    // Reset transition when stopping
                    transitionProgress = 0.0
                    // Reset time immediately when stopping
                    time = 0.0
                }
            }
            .onAppear {
                 // Set initial state based on isAnimating
                 transitionProgress = isAnimating ? 1.0 : 0.0
                 // Reset time on appear only if not already animating (e.g., initial load)
                 if !isAnimating {
                    time = 0.0
                 }
            }
    }
    
    private func calculateOffsetY() -> CGFloat {
        // Always calculate the potential offset based on time
        let phase = time * frequency
        let reversedIndex = Double(characterCount - 1 - characterIndex)
        let charPhaseOffset = reversedIndex * phaseShiftPerCharacter
        let waveOffset = sin(phase + charPhaseOffset) * amplitude
        
        // Apply the transition progress to smoothly ramp up/down the wave
        return waveOffset * transitionProgress
    }
}

#Preview {
    Text("Wave Animation Modifier Preview")
        .font(.largeTitle)
        .foregroundColor(.white)
        .background(Color.black)
        .modifier(WaveEffectModifier(
            isAnimating: true,
            characterIndex: 0,
            characterCount: 10,
            amplitude: 10.0,
            frequency: 2.0,
            phaseShiftPerCharacter: 0.5
        ))
} 
