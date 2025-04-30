import Foundation

/// Represents the different types of poker hands that can be formed
enum HandType: Int, Comparable {
    // 5-card hands (highest scoring)
    case royalFlush = 100
    case straightFlush = 95
    case fullHouse = 90
    case flush = 85
    case straight = 80
    
    // 4-card hands
    case fourOfAKind = 75
    case nearlyRoyalFlush = 70
    case nearlyStraightFlush = 65
    case nearlyFlush = 60
    case nearlyStraight = 55
    case twoPair = 50
    
    // 3-card hands
    case threeOfAKind = 45
    case miniRoyalFlush = 40
    case miniStraightFlush = 35
    case miniFlush = 30
    case miniStraight = 25
    
    // 2-card hands (lowest scoring)
    case pair = 15
    
    var displayName: String {
        switch self {
        case .royalFlush: return "Royal flush"
        case .straightFlush: return "Straight flush"
        case .fullHouse: return "Full house"
        case .flush: return "Flush"
        case .straight: return "Straight"
        case .fourOfAKind: return "Four of a kind"
        case .nearlyRoyalFlush: return "Nearly royal flush"
        case .nearlyStraightFlush: return "Nearly straight flush"
        case .nearlyFlush: return "Nearly flush"
        case .nearlyStraight: return "Nearly straight"
        case .twoPair: return "Two pair"
        case .threeOfAKind: return "Three of a kind"
        case .miniRoyalFlush: return "Mini royal flush"
        case .miniStraightFlush: return "Mini straight flush"
        case .miniFlush: return "Mini flush"
        case .miniStraight: return "Mini straight"
        case .pair: return "Pair"
        }
    }
    
    static func < (lhs: HandType, rhs: HandType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Handles the detection and validation of poker hands
struct PokerHandDetector {
    /// Detects the highest-ranking valid poker hand from a set of cards
    /// - Parameter cards: Array of cards to evaluate
    /// - Returns: The highest-ranking valid hand type, or nil if no valid hand is found
    static func detectHand(cards: [Card]) -> HandType? {
        guard cards.count >= 2 else { return nil }
        
        // Sort cards by rank for easier evaluation
        let sortedCards = cards.sorted { $0.rank.rawValue < $1.rank.rawValue }
        
        // Check for royal flush first (highest ranking)
        if isRoyalFlush(cards: sortedCards) {
            return .royalFlush
        }
        
        // Check for nearly royal flush
        if isNearlyRoyalFlush(cards: sortedCards) {
            return .nearlyRoyalFlush
        }
        
        // Check for mini royal flush
        if isMiniRoyalFlush(cards: sortedCards) {
            return .miniRoyalFlush
        }
        
        // Check for straight flush
        if isStraightFlush(cards: sortedCards) {
            return .straightFlush
        }
        
        // Check for four of a kind
        if isFourOfAKind(cards: sortedCards) {
            return .fourOfAKind
        }
        
        // Check for nearly straight flush
        if isNearlyStraightFlush(cards: sortedCards) {
            return .nearlyStraightFlush
        }
        
        // Check for full house
        if isFullHouse(cards: sortedCards) {
            return .fullHouse
        }
        
        // Check for flush
        if isFlush(cards: sortedCards) {
            return .flush
        }
        
        // Check for nearly flush
        if isNearlyFlush(cards: sortedCards) {
            return .nearlyFlush
        }
        
        // Check for straight
        if isStraight(cards: sortedCards) {
            return .straight
        }
        
        // Check for nearly straight
        if isNearlyStraight(cards: sortedCards) {
            return .nearlyStraight
        }
        
        // Check for mini straight flush
        if isMiniStraightFlush(cards: sortedCards) {
            return .miniStraightFlush
        }
        
        // Check for mini flush
        if isMiniFlush(cards: sortedCards) {
            return .miniFlush
        }
        
        // Check for mini straight
        if isMiniStraight(cards: sortedCards) {
            return .miniStraight
        }
        
        // Check for three of a kind
        if isThreeOfAKind(cards: sortedCards) {
            return .threeOfAKind
        }
        
        // Check for two pair
        if isTwoPair(cards: sortedCards) {
            return .twoPair
        }
        
        // Check for one pair
        if isPair(cards: sortedCards) {
            return .pair
        }
        
        // No valid hand found
        return nil
    }
    
    // MARK: - Individual Hand Checks
    
    private static func isRoyalFlush(cards: [Card]) -> Bool {
        guard cards.count == 5 else { return false }

        // Check if it's a straight flush first
        // Note: isStraightFlush itself checks count is 5, isFlush, and isStraight.
        // The input 'cards' to this function are already sorted by rank in detectHand.
        guard isStraightFlush(cards: cards) else { return false }

        // If it's a straight flush, check if the ranks are specifically 10, J, Q, K, A
        let ranks = Set(cards.map { $0.rank })
        let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]

        return ranks == royalRanks
    }
    
    private static func isNearlyRoyalFlush(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        let suits = cards.map { $0.suit }
        guard Set(suits).count == 1 else { return false }
        
        let ranks = Set(cards.map { $0.rank })
        let requiredRanks: Set<Rank> = [.jack, .queen, .king, .ace]
        return ranks == requiredRanks
    }
    
    private static func isNearlyStraightFlush(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        
        // First check if all cards are of the same suit
        let suits = cards.map { $0.suit }
        guard Set(suits).count == 1 else { return false }
        
        // Then check if the ranks form a straight
        return isNearlyStraight(cards: cards)
    }
    
    private static func isMiniRoyalFlush(cards: [Card]) -> Bool {
        guard cards.count == 3 else { return false }
        let suits = cards.map { $0.suit }
        guard Set(suits).count == 1 else { return false }
        
        let ranks = Set(cards.map { $0.rank })
        let requiredRanks: Set<Rank> = [.jack, .queen, .king]
        return ranks == requiredRanks
    }
    
    private static func isMiniStraightFlush(cards: [Card]) -> Bool {
        guard cards.count == 3 else { return false }
        
        // First check if all cards are of the same suit
        let suits = cards.map { $0.suit }
        guard Set(suits).count == 1 else { return false }
        
        // Then check if the ranks form a straight
        return isMiniStraight(cards: cards)
    }
    
    private static func isStraightFlush(cards: [Card]) -> Bool {
        guard cards.count == 5 else { return false }
        return isFlush(cards: cards) && isStraight(cards: cards)
    }
    
    private static func isFourOfAKind(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        let ranks = cards.map { $0.rank }
        return Set(ranks).count == 1
    }
    
    private static func isFullHouse(cards: [Card]) -> Bool {
        guard cards.count == 5 else { return false }
        let ranks = cards.map { $0.rank }
        let uniqueRanks = Set(ranks)
        guard uniqueRanks.count == 2 else { return false }
        
        let firstRankCount = ranks.filter { $0 == ranks[0] }.count
        return firstRankCount == 2 || firstRankCount == 3
    }
    
    private static func isFlush(cards: [Card]) -> Bool {
        guard cards.count == 5 else { return false }
        let suits = cards.map { $0.suit }
        return Set(suits).count == 1
    }
    
    private static func isNearlyFlush(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        let suits = cards.map { $0.suit }
        return Set(suits).count == 1
    }
    
    private static func isMiniFlush(cards: [Card]) -> Bool {
        guard cards.count == 3 else { return false }
        let suits = cards.map { $0.suit }
        return Set(suits).count == 1
    }
    
    private static func isStraight(cards: [Card]) -> Bool {
        guard cards.count == 5 else { return false }
        let uniqueRanks = Set(cards.map { $0.rank })
        guard uniqueRanks.count == 5 else { return false } // Must have 5 distinct ranks

        let sortedRankValues = cards.map { $0.rank.rawValue }.sorted()

        // Check for normal straight (no Ace involved, or Ace is high/low in standard sequence)
        let isStandardConsecutive = (sortedRankValues[4] - sortedRankValues[0] == 4)
        // Check for Ace-low straight (A, 2, 3, 4, 5)
        let isAceLow = uniqueRanks == Set([.ace, .two, .three, .four, .five])

        if isStandardConsecutive || isAceLow {
            return true
        }

        // Explicitly check for Ace-bridge wrap-around cases (less common)
        // Q-K-A-2-3
        if uniqueRanks == Set([.queen, .king, .ace, .two, .three]) { return true }
        // K-A-2-3-4
        if uniqueRanks == Set([.king, .ace, .two, .three, .four]) { return true }
        // J-Q-K-A-2 <-- Added this case
        if uniqueRanks == Set([.jack, .queen, .king, .ace, .two]) { return true }
        // A-2-3-4-K (Example of another possible wrap-around if needed)
        // if uniqueRanks == Set([.ace, .two, .three, .four, .king]) { return true }
        // A-2-J-Q-K (Example)
        // if uniqueRanks == Set([.ace, .two, .jack, .queen, .king]) { return true }
        
        // Note: 10-J-Q-K-A is covered by isStandardConsecutive after sorting raw values.

        return false
    }
    
    private static func isNearlyStraight(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        let uniqueRanks = Set(cards.map { $0.rank })
        guard uniqueRanks.count == 4 else { return false } // Must have 4 distinct ranks

        let sortedRankValues = cards.map { $0.rank.rawValue }.sorted()
        
        // Check if ranks are consecutive OR it's an Ace-low fragment
        let isStandardConsecutive = (sortedRankValues[3] - sortedRankValues[0] == 3)
        let isAceLow = uniqueRanks == Set([.ace, .two, .three, .four])
        // Check Ace-high specifically (J-Q-K-A)
        let isAceHigh = uniqueRanks == Set([.jack, .queen, .king, .ace])

        if isStandardConsecutive || isAceLow || isAceHigh {
            return true
        }

        // Explicitly check for Ace-bridge wrap-around cases
        // Q-K-A-2
        if uniqueRanks == Set([.queen, .king, .ace, .two]) { return true }
        // K-A-2-3
        if uniqueRanks == Set([.king, .ace, .two, .three]) { return true }
        // A-2-3-K
        // if uniqueRanks == Set([.ace, .two, .three, .king]) { return true }
        // A-J-Q-K
        // if uniqueRanks == Set([.ace, .jack, .queen, .king]) { return true }

        return false
    }
    
    private static func isMiniStraight(cards: [Card]) -> Bool {
        guard cards.count == 3 else { return false }
        let uniqueRanks = Set(cards.map { $0.rank })
        guard uniqueRanks.count == 3 else { return false } // Must have 3 distinct ranks

        let sortedRankValues = cards.map { $0.rank.rawValue }.sorted()
        
        // Check if ranks are consecutive OR it's an Ace-low fragment
        let isStandardConsecutive = (sortedRankValues[2] - sortedRankValues[0] == 2)
        let isAceLow = uniqueRanks == Set([.ace, .two, .three])
        // Check Ace-high specifically (Q-K-A)
        let isAceHigh = uniqueRanks == Set([.queen, .king, .ace])

        if isStandardConsecutive || isAceLow || isAceHigh {
            return true
        }

        // Explicitly check for Ace-bridge wrap-around case (K-A-2)
        if uniqueRanks == Set([.king, .ace, .two]) { return true }
        // A-2-K
        // if uniqueRanks == Set([.ace, .two, .king]) { return true }
        
        return false
    }
    
    private static func isThreeOfAKind(cards: [Card]) -> Bool {
        guard cards.count == 3 else { return false }
        let ranks = cards.map { $0.rank }
        return Set(ranks).count == 1
    }
    
    private static func isTwoPair(cards: [Card]) -> Bool {
        guard cards.count == 4 else { return false }
        let ranks = cards.map { $0.rank }
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        return rankCounts.count == 2 && rankCounts.values.allSatisfy { $0 == 2 }
    }
    
    /// Checks if the cards form a pair (two cards of the same rank)
    private static func isPair(cards: [Card]) -> Bool {
        guard cards.count == 2 else { return false }
        
        // Check if both cards have the same rank
        return cards[0].rank == cards[1].rank
    }
} 