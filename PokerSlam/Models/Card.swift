import Foundation

enum Suit: String, CaseIterable, Hashable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"
    
    var color: String {
        switch self {
        case .hearts: return "#C02D40"
        case .diamonds: return "#CEAB27"
        case .clubs: return "#2875BA"
        case .spades: return "#E66523"
        }
    }
}

enum Rank: Int, CaseIterable, Hashable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    
    var display: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return String(rawValue)
        }
    }
}

struct Card: Identifiable, Hashable {
    let id = UUID()
    let suit: Suit
    let rank: Rank
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 