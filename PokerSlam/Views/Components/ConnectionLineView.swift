import SwiftUI

/// A view that renders a connection line between two points
struct ConnectionLineView: View {
    /// The starting point of the line
    let startPoint: CGPoint
    
    /// The ending point of the line
    let endPoint: CGPoint
    
    /// The color of the line
    let color: Color
    
    /// The width of the line
    let lineWidth: CGFloat
    
    /// Whether the line should be animated
    let isAnimated: Bool
    
    /// Animation progress (0.0 to 1.0)
    @State private var animationProgress: CGFloat = 0
    
    /// Creates a connection line view with the specified parameters
    init(
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: Color = Color(hex: "#d4d4d4"),
        lineWidth: CGFloat = 2,
        isAnimated: Bool = true
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        Path { path in
            // Calculate the current end point based on animation progress
            let currentEndPoint = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * animationProgress,
                y: startPoint.y + (endPoint.y - startPoint.y) * animationProgress
            )
            
            path.move(to: startPoint)
            path.addLine(to: currentEndPoint)
        }
        .stroke(color, lineWidth: lineWidth)
        .onAppear {
            if isAnimated {
                // Reset animation progress
                animationProgress = 0
                
                // Animate the line drawing
                withAnimation(.easeInOut(duration: 0.3)) {
                    animationProgress = 1
                }
            } else {
                // If not animated, set progress to 1 immediately
                animationProgress = 1
            }
        }
    }
}

struct ConnectionLineView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            
            ConnectionLineView(
                startPoint: CGPoint(x: 100, y: 100),
                endPoint: CGPoint(x: 300, y: 300),
                color: .blue,
                lineWidth: 2,
                isAnimated: true
            )
        }
    }
} 