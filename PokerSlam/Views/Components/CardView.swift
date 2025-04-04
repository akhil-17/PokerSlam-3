import SwiftUI

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isEligible: Bool
    let isInteractive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if isInteractive {
                if isSelected {
                    onTap() // Unselect if the card is already selected
                } else if isEligible {
                    onTap() // Select the card if it's eligible
                } else if !isSelected {
                    onTap() // Unselect all cards if tapping an ineligible card
                }
            }
        }) {
            // Fixed size container to maintain grid layout
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#191919"))
                    .frame(width: isSelected ? 64 : 60, height: isSelected ? 94 : 90)
                    .shadow(
                        color: Color(hex: "#191919").opacity(isSelected ? 0.5 : 0.3),
                        radius: isSelected ? 4 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color(hex: "#d4d4d4") : Color.clear,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                
                // Card content
                VStack(spacing: 0) {
                    Text(card.rank.display)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: card.suit.color))
                    
                    Text(card.suit.rawValue)
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: card.suit.color))
                }
            }
            .frame(width: 64, height: 94) // Fixed container size
            .contentShape(Rectangle()) // Ensure the entire area is tappable
            .opacity(isSelected ? 1.0 : (isEligible ? 1.0 : 0.5)) // Selected cards are always 100% opacity, eligible cards are 100% opacity, non-eligible cards are 50% opacity
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .disabled(!isInteractive)
    }
}

#Preview {
    ZStack {
        MeshGradientBackground()
        
        HStack {
            CardView(
                card: Card(suit: .hearts, rank: .ace),
                isSelected: false,
                isEligible: false,
                isInteractive: true,
                onTap: {}
            )
            CardView(
                card: Card(suit: .spades, rank: .king),
                isSelected: true,
                isEligible: false,
                isInteractive: true,
                onTap: {}
            )
            CardView(
                card: Card(suit: .diamonds, rank: .queen),
                isSelected: false,
                isEligible: true,
                isInteractive: true,
                onTap: {}
            )
            CardView(
                card: Card(suit: .clubs, rank: .jack),
                isSelected: false,
                isEligible: false,
                isInteractive: false,
                onTap: {}
            )
        }
        .padding()
    }
} 