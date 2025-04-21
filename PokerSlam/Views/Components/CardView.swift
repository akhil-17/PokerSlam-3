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

    // MARK: - Computed Style Properties
    
    private var cardSize: CGSize {
        switch style {
        case .standard: return CGSize(width: 64, height: 94)
        case .mini: return CGSize(width: 45, height: 66) // Approx 70%
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return 8
        case .mini: return 6 // Slightly smaller
        }
    }
    
    private var textFont: Font {
        switch style {
        case .standard: return .cardStandardText
        case .mini: return .cardMiniText
        }
    }
    
    private var shadowRadius: CGFloat {
        isSelected ? (style == .standard ? 8 : 5) : (style == .standard ? 2 : 1)
    }
    
    private var shadowY: CGFloat {
        isSelected ? (style == .standard ? 4 : 2) : (style == .standard ? 1 : 0.5)
    }
    
    private var strokeWidth: CGFloat {
        isSelected ? (style == .standard ? 1.5 : 1.0) : (style == .standard ? 1 : 0.5)
    }
    
    private var scaleEffect: CGFloat {
        isSelected ? 1.15 : 1.0
    }
    
    var body: some View {
        Button(action: {
            if isInteractive {
                // Simplified logic: allow tap if interactive
                onTap()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.thick)
                    .preferredColorScheme(.dark)
                    .shadow(
                        color: isSelected ? Color(hex: "#FFD302").opacity(0.3) : Color(hex: "#191919").opacity(0.2),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowY
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isSelected ? Color(hex: "#FFD302") : Color.clear,
                                lineWidth: strokeWidth
                            )
                    )
                
                VStack(spacing: 0) {
                    Text(card.rank.display)
                        .font(textFont) // Use dynamic font
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(scaleEffect) // Apply scale effect
                        .animation(
                            isSelected ?
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                .default,
                            value: isSelected
                        )
                    
                    Text(card.suit.rawValue)
                        .font(textFont) // Use dynamic font
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(scaleEffect) // Apply scale effect
                        .animation(
                            isSelected ?
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                .default,
                            value: isSelected
                        )
                }
            }
            .opacity(isEligible || isSelected ? 1.0 : (style == .mini ? 1.0 : 0.5)) // Mini cards are always fully opaque
            .frame(width: cardSize.width, height: cardSize.height) // Use dynamic size
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
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
