import SwiftUI

// Define the style options for CardView
enum CardStyle {
    case standard
    case mini
}

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isEligible: Bool
    let isInteractive: Bool
    let style: CardStyle // Add style property
    let onTap: () -> Void
    
    // Convenience initializer for standard style
    init(
        card: Card,
        isSelected: Bool,
        isEligible: Bool,
        isInteractive: Bool,
        onTap: @escaping () -> Void
    ) {
        self.card = card
        self.isSelected = isSelected
        self.isEligible = isEligible
        self.isInteractive = isInteractive
        self.style = .standard // Default to standard
        self.onTap = onTap
    }
    
    // Full initializer including style
    init(
        card: Card,
        isSelected: Bool,
        isEligible: Bool,
        isInteractive: Bool,
        style: CardStyle, // Explicitly include style
        onTap: @escaping () -> Void
    ) {
        self.card = card
        self.isSelected = isSelected
        self.isEligible = isEligible
        self.isInteractive = isInteractive
        self.style = style
        self.onTap = onTap
    }

    // MARK: - Computed Style Properties (Replaced with Constants)
    
    // Properties now directly use constants from CardUIConstants based on style and isSelected state
    private var cardSize: CGSize {
        style == .standard ? CardUIConstants.standardSize : CardUIConstants.miniSize
    }
    
    private var cornerRadius: CGFloat {
        style == .standard ? CardUIConstants.standardCornerRadius : CardUIConstants.miniCornerRadius
    }
    
    private var textFont: Font {
        // Explicitly use Font. prefix to resolve ambiguity
        style == .standard ? Font.cardStandardText : Font.cardMiniText
    }
    
    private var shadowRadius: CGFloat {
        isSelected ? 
            (style == .standard ? CardUIConstants.standardSelectedShadowRadius : CardUIConstants.miniSelectedShadowRadius) :
            (style == .standard ? CardUIConstants.standardUnselectedShadowRadius : CardUIConstants.miniUnselectedShadowRadius)
    }
    
    private var shadowY: CGFloat {
        isSelected ?
            (style == .standard ? CardUIConstants.standardSelectedShadowY : CardUIConstants.miniSelectedShadowY) :
            (style == .standard ? CardUIConstants.standardUnselectedShadowY : CardUIConstants.miniUnselectedShadowY)
    }
    
    private var strokeWidth: CGFloat {
        isSelected ?
            (style == .standard ? CardUIConstants.standardSelectedStrokeWidth : CardUIConstants.miniSelectedStrokeWidth) :
            (style == .standard ? CardUIConstants.standardUnselectedStrokeWidth : CardUIConstants.miniUnselectedStrokeWidth)
    }
    
    private var scaleEffect: CGFloat {
        isSelected ? CardUIConstants.selectedScaleEffect : CardUIConstants.unselectedScaleEffect
    }
    
    private var shadowColor: Color {
        isSelected ? CardUIConstants.selectedShadowColor : CardUIConstants.unselectedShadowColor
    }
    
    private var strokeColor: Color {
        isSelected ? CardUIConstants.selectedStrokeColor : CardUIConstants.unselectedStrokeColor
    }
    
    private var opacity: Double {
        // Mini cards are always fully opaque (as per original logic)
        isEligible || isSelected || style == .mini ? CardUIConstants.eligibleOpacity : CardUIConstants.ineligibleOpacity
    }
    
    private var textPulseAnimation: Animation {
        isSelected ? AnimationConstants.cardPulseAnimation : AnimationConstants.cardDefaultAnimation
    }
    
    var body: some View {
        Button(action: {
            if isInteractive {
                onTap()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.thick)
                    .preferredColorScheme(.dark)
                    .shadow(
                        color: shadowColor, // Use constant
                        radius: shadowRadius,
                        x: 0,
                        y: shadowY
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                strokeColor, // Use constant
                                lineWidth: strokeWidth
                            )
                    )
                
                VStack(spacing: 0) {
                    Text(card.rank.display)
                        .font(textFont)
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(scaleEffect)
                        .animation(textPulseAnimation, value: isSelected) // Use constant animation
                    
                    Text(card.suit.rawValue)
                        .font(textFont)
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(scaleEffect)
                        .animation(textPulseAnimation, value: isSelected) // Use constant animation
                }
            }
            .opacity(opacity) // Use constant
            .frame(width: cardSize.width, height: cardSize.height)
            .contentShape(Rectangle())
            // Apply accessibility modifiers here
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(card.rank.display) of \(card.suit.rawValue)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityAddTraits(isInteractive ? .isButton : [])
        }
        .buttonStyle(PlainButtonStyle())
        // Use AnimationConstants.cardSelectionSpring
        .animation(AnimationConstants.cardSelectionSpring, value: isSelected)
    }
}

#Preview {
    ZStack {
        MeshGradientBackground()
            .ignoresSafeArea()

        VStack(spacing: 20) { // Use VStack to stack the rows
            // Standard cards row
            HStack {
                CardView(
                    card: Card(suit: .hearts, rank: .ace),
                    isSelected: false,
                    isEligible: true,
                    isInteractive: true,
                    style: .standard, // Explicitly set style
                    onTap: {}
                )
                CardView(
                    card: Card(suit: .spades, rank: .king),
                    isSelected: true,
                    isEligible: false,
                    isInteractive: true,
                    style: .standard, // Explicitly set style
                    onTap: {}
                )
                CardView(
                    card: Card(suit: .diamonds, rank: .queen),
                    isSelected: false,
                    isEligible: true,
                    isInteractive: true,
                    style: .standard, // Explicitly set style
                    onTap: {}
                )
                CardView(
                    card: Card(suit: .clubs, rank: .jack),
                    isSelected: false,
                    isEligible: false,
                    isInteractive: true,
                    style: .standard, // Explicitly set style
                    onTap: {}
                )
            }
            
            // Mini cards row
            HStack(spacing: 8) { // Adjust spacing if needed
                CardView(
                    card: Card(suit: .hearts, rank: .two),
                    isSelected: false,
                    isEligible: true,
                    isInteractive: false, // Mini cards are not interactive
                    style: .mini, // Use mini style
                    onTap: {}
                )
                CardView(
                    card: Card(suit: .spades, rank: .three),
                    isSelected: true, // Show a selected mini card
                    isEligible: true,
                    isInteractive: false,
                    style: .mini,
                    onTap: {}
                )
                CardView(
                    card: Card(suit: .diamonds, rank: .four),
                    isSelected: false,
                    isEligible: true,
                    isInteractive: false,
                    style: .mini,
                    onTap: {}
                )
                 CardView(
                    card: Card(suit: .clubs, rank: .five),
                    isSelected: false,
                    isEligible: true,
                    isInteractive: false,
                    style: .mini,
                    onTap: {}
                )
            }
        }
        .padding()
    }
} 
