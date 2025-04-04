//
//  Item.swift
//  PokerSlam
//
//  Created by Akhil Dakinedi on 4/2/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
