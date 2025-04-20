import SwiftUI

/// Represents a single falling rank symbol.
private struct FallingRank: Identifiable {
    let id = UUID()
    let symbol: String // SF Symbol name (e.g., "suit.spade.fill")
    let color: Color
    var xPosition: CGFloat
    var yPosition: CGFloat
    let speed: CGFloat
    let size: CGFloat
}

/// A view that displays an animation of card ranks falling from the top.
struct FallingRanksView: View {
    @State private var ranks: [FallingRank] = []
    // private let maxRanks = 10 // REMOVED: Maximum number of ranks on screen
    private let spawnInterval: TimeInterval = 0.5 // How often new ranks appear
    @State private var lastSpawnTime: Date = Date() // Track last spawn time
    private let fixedRankSize: CGFloat = 30.0 // Define a fixed size
    private let fixedSpeed: CGFloat = 1.0 // Define a fixed speed

    // Define suit symbols and colors
    private let suits: [(symbol: String, color: Color)] = [
        ("suit.spade.fill", .orange.opacity(0.7)), // Use white for visibility
        ("suit.heart.fill", .red.opacity(0.4)),
        ("suit.diamond.fill", .blue.opacity(0.6)), // Standard 4-color deck blue
        ("suit.club.fill", .green.opacity(0.5)) // Standard 4-color deck green
    ]

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.016)) { timeline in
                // --- DEBUG LOG REMOVED ---
                // --- END DEBUG LOG ---
                Canvas { context, size in
                    // Draw ranks
                    for rank in ranks {
                        // Attempt to resolve the symbol FIRST
                        if let resolvedSymbol = context.resolveSymbol(id: rank.id) {
                            let drawPoint = CGPoint(x: rank.xPosition, y: rank.yPosition)
                            // Draw the resolved symbol without foregroundStyle here
                            context.draw(resolvedSymbol,
                                         at: drawPoint,
                                         anchor: .center)
                        } else {
                            print("⚠️ Failed to resolve symbol for rank ID: \(rank.id)")
                        }
                    }
                } symbols: {
                    // Define the symbols and apply modifiers within the Canvas builder
                    ForEach(ranks) { rank in
                         Image(systemName: rank.symbol)
                             .tag(rank.id) // Tag for Canvas resolution
                             .font(.system(size: rank.size))
                             .foregroundStyle(rank.color)
                             .modifier(FallingRankSymbolEffectModifier()) // Apply the new effect
                     }
                }
                .onAppear {
                    // Initial spawn when view appears
                    spawnNewRank(in: geometry.size)
                    lastSpawnTime = Date() // Initialize spawn time
                }
                // Use onChange on the timeline date to periodically spawn AND UPDATE POSITIONS
                .onChange(of: timeline.date) { _, newDate in
                     // --- DEBUG LOG REMOVED ---
                     // print("TimelineView Update (onChange): \(newDate)")
                     // --- END DEBUG LOG ---

                     // Update positions first
                     updateRankPositions(date: newDate, size: geometry.size)
                     
                     // Check if spawn interval has passed
                     if newDate.timeIntervalSince(lastSpawnTime) >= spawnInterval {
                         spawnNewRank(in: geometry.size)
                         lastSpawnTime = newDate // Update last spawn time
                     }
                 }
            }
            .clipped() // Ensure ranks don't draw outside the view bounds
            .allowsHitTesting(false) // Prevent interaction with the background animation
        }
        .ignoresSafeArea() // Allow animation to fill the background
        // Restore mask
        .mask(
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.8), .black.opacity(0.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func updateRankPositions(date: Date, size: CGSize) {
        // Need to know the *previous* date to calculate deltaTime accurately.
        // Let's store the previous date in state.
        // @State private var previousUpdateTime: Date = Date() // Add this near other @State vars
        // let deltaTime = date.timeIntervalSince(previousUpdateTime)
        // previousUpdateTime = date
        
        // For now, let's stick to a fixed deltaTime approximation. 
        // A more complex approach using previous time is possible if needed.
        let deltaTime = 0.016 // Approximate time since last frame

        // Use a Set for efficient removal
        var ranksToRemove = Set<UUID>()

        // Iterate by index to modify structs in place
        for i in 0..<ranks.count { // Use 0..<ranks.count for clarity
            var rank = ranks[i] // Get a mutable copy
            // Restore update with deltaTime
            rank.yPosition += rank.speed * CGFloat(deltaTime) * 100 
            ranks[i] = rank // Assign the modified copy back to the array

            // --- DEBUG LOG REMOVED ---
            /*
            if i == 0 { // Log only the first rank to avoid spam
                print("Rank 0 yPosition: \(ranks[i].yPosition)")
            }
            */
            // --- END DEBUG LOG ---
            
            // Mark ranks that have fallen off the bottom for removal (use updated rank copy)
            if ranks[i].yPosition > size.height + ranks[i].size { 
                ranksToRemove.insert(ranks[i].id)
            }
        }

        // Remove ranks efficiently
        if !ranksToRemove.isEmpty {
            ranks.removeAll { ranksToRemove.contains($0.id) }
             print("FallingRanksView: Removed \(ranksToRemove.count) ranks.")
        }
    }

    private func spawnNewRank(in size: CGSize) {
        guard let randomSuit = suits.randomElement() else { return }

        let rankSize = fixedRankSize // Use fixed size
        let yPosition = -rankSize // Start just above the view
        let speed = fixedSpeed // Use fixed speed
        var xPosition: CGFloat = 0.0
        var positionIsSafe = false
        let maxRetries = 10 // Increase retries for better distribution
        
        for _ in 0..<maxRetries {
            // Generate a potential horizontal position
            xPosition = CGFloat.random(in: (rankSize / 2)...(size.width - rankSize / 2))
            positionIsSafe = true // Assume safe initially
            
            // Check against existing ranks near the top
            for existingRank in ranks {
                // Only check ranks that are still near the top visually
                if existingRank.yPosition < rankSize * 2 { 
                    let horizontalDistance = abs(existingRank.xPosition - xPosition)
                    // If too close horizontally, mark as unsafe and break inner loop
                    if horizontalDistance < rankSize * 2.0 { // Increase multiplier for more spacing
                        positionIsSafe = false
                        break 
                    }
                }
            }
            
            // If the position is safe, break the retry loop
            if positionIsSafe {
                break
            }
        }
        
        // Only spawn if a safe position was found
        guard positionIsSafe else {
            print("FallingRanksView: Could not find safe spawn position, skipping spawn.")
            return
        }

        let newRank = FallingRank(
            symbol: randomSuit.symbol,
            color: randomSuit.color,
            xPosition: xPosition,
            yPosition: yPosition,
            speed: speed,
            size: rankSize // Use fixed size
        )
        
        ranks.append(newRank)
         print("FallingRanksView: Spawned new rank (\(randomSuit.symbol)) at X: \(Int(xPosition)), count: \(ranks.count)")
    }
}

#Preview {
    FallingRanksView()
        .background(Color.blue) // Change background for preview visibility
} 
