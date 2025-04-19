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
                    onTap()
                } else if isEligible {
                    onTap()
                } else if !isSelected {
                    onTap()
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Material.thick)
                    .preferredColorScheme(.dark)
                    .shadow(
                        color: isSelected ? Color(hex: "#FFD302").opacity(0.6) : Color(hex: "#191919").opacity(0.3),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color(hex: "#FFD302") : Color.clear,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                
                VStack(spacing: 0) {
                    Text(card.rank.display)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(
                            isSelected ?
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                .default,
                            value: isSelected
                        )
                    
                    Text(card.suit.rawValue)
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: card.suit.color))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(
                            isSelected ?
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                .default,
                            value: isSelected
                        )
                }
            }
            .opacity(isEligible || isSelected ? 1.0 : 0.5) 
            .frame(width: 64, height: 94) 
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .disabled(!isInteractive)
    }
}

#Preview {
    ZStack {
        MeshGradientBackground()
            .ignoresSafeArea()

        HStack {
            CardView(
                card: Card(suit: .hearts, rank: .ace),
                isSelected: false,
                isEligible: true, // Make eligible for preview testing
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
                isEligible: false, // Ineligible for preview testing
                isInteractive: true, // Keep interactive to test tap-to-deselect
                onTap: {}
            )
        }
        .padding()
    }
} 