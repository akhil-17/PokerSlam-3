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
        .custom("Kanit-Bold", size: 20)
    }
    
    /// Custom font style for game over and intro messages
    static var messageText: Font {
        .custom("Kanit-Medium", size: 18)
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
                ButtonTextLabel(text: title)
                    .transition(TextTransition())
                    .offset(y: isVisible ? 0 : textOffset)
                    .opacity(isVisible ? 1 : 0)
                    .blur(radius: isVisible ? 0 : 5)
                    .offset(x: isWiggling ? 5 : 0)
                    .animation(
                        Animation.easeInOut(duration: 0.1)
                            .repeatCount(3, autoreverses: true),
                        value: isWiggling
                    )
                
                if let icon = icon {
                    // Icon with mesh gradient effect
                    ButtonIconLabel(systemName: icon, isAnimated: isAnimated)
                        .offset(y: isVisible ? 0 : textOffset)
                        .opacity(isVisible ? 1 : 0)
                        .blur(radius: isVisible ? 0 : 5)
                        .offset(x: isWiggling ? 5 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.1)
                                .repeatCount(3, autoreverses: true),
                            value: isWiggling
                        )
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 4)
            .background(
                MeshGradientBackground2()
                    .mask(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(.white.opacity(0.60), lineWidth: 16)
                            .blur(radius: 4)
                            .blendMode(.colorDodge)
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
            // Trigger the text animation with minimal delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    isVisible = true
                }
            }
        }
    }
}

/// A view that displays text with a mesh gradient effect
struct ButtonTextLabel: View {
    let text: String
    
    var body: some View {
        GlyphAnimatedText(text: text)
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
                GlyphAnimatedText(text: text)
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

/// A view that animates text with a glyph-by-glyph animation
struct GlyphAnimatedText: View {
    let text: String
    let animationDelay: Double
    @State private var visibleGlyphs: Int = 0
    
    init(text: String, animationDelay: Double = 0.0) {
        self.text = text
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < visibleGlyphs ? 1 : 0)
                    .offset(y: index < visibleGlyphs ? 0 : 20)
                    .blur(radius: index < visibleGlyphs ? 0 : 5)
            }
        }
        .id(text)
        .onAppear {
            animateGlyphs()
        }
        .onChange(of: text) {
            resetAndAnimateGlyphs()
        }
    }

    private func animateGlyphs() {
        // Apply initial delay before starting the animation loop
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            // Animate each glyph sequentially
            for i in 0..<text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                    // Ensure the text hasn't changed again before updating visibleGlyphs
                    if self.visibleGlyphs == i {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            visibleGlyphs = i + 1
                        }
                    }
                }
            }
        }
    }

    private func resetAndAnimateGlyphs() {
        visibleGlyphs = 0 // Reset visibility
        // No delay needed on reset, animation itself will be delayed by animateGlyphs in animateGlyphs
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
            .if(isAnimated) { view in
                view.modifier(PulsingAnimationModifier())
            }
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

    init(
        font: Font,
        tracking: CGFloat = 0,
        isAnimated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.font = font
        self.tracking = tracking
        self.isAnimated = isAnimated
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
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            .if(isAnimated) { view in
                view.modifier(PulsingAnimationModifier())
            }
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
                        title: "Invalid hand",
                        icon: "xmark",
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
