import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let instructions = [
        Instruction(
            title: "Find Poker Hands",
            description: "Select 2-5 adjacent cards to form valid poker hands",
            imageName: "hand.raised.fill"
        ),
        Instruction(
            title: "Score Points",
            description: "Better hands earn more points. Try to beat your high score!",
            imageName: "star.fill"
        ),
        Instruction(
            title: "Keep Playing",
            description: "When you play a hand, new cards will fill the empty spaces",
            imageName: "arrow.clockwise.circle.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<instructions.count, id: \.self) { index in
                        InstructionView(instruction: instructions[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct Instruction: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct InstructionView: View {
    let instruction: Instruction
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: instruction.imageName)
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text(instruction.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(instruction.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    HowToPlayView()
} 