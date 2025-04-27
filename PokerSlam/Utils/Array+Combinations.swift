import Foundation

extension Array {
    func combinations(ofCount count: Int) -> [[Element]] {
        guard count > 0 && count <= self.count else { return [] }
        
        if count == 1 {
            return self.map { [$0] }
        }
        
        var result: [[Element]] = []
        for i in 0...(self.count - count) {
            let first = self[i]
            let remaining = Array(self[(i + 1)...])
            let subCombinations = remaining.combinations(ofCount: count - 1)
            result.append(contentsOf: subCombinations.map { [first] + $0 })
        }
        return result
    }
} 