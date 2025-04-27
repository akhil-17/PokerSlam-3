import XCTest
@testable import PokerSlam // Import the module to test

// Dummy Haptics Manager for testing
class DummyHapticsManager: HapticsManaging { // Conform to protocol
    func playSuccess() {}
    func playError() {}
    func playWarning() {}
    func playSelectionChanged() {}
    func playImpact(intensity: CGFloat) {}
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {}
    func prepare() {}
    
    // Conform to the specific methods used by GameStateManager
    func playShiftImpact() {}
    func playNewCardImpact() {}
}


@MainActor // Since GameStateManager is @MainActor
final class GameStateManagerTests: XCTestCase {

    var sut: GameStateManager! // System Under Test
    var dummyHapticsManager: HapticsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dummyHapticsManager = DummyHapticsManager()
        // Initialize with real PokerHandDetector for now
        sut = GameStateManager(hapticsManager: dummyHapticsManager, detectHand: PokerHandDetector.detectHand)
        // Reset deck before each test (important!)
        sut.setupDeck() 
    }

    override func tearDownWithError() throws {
        sut = nil
        dummyHapticsManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization and Reset Tests

    func testInitialDeal_DealsCorrectNumberOfCards() {
        // Arrange
        let expectation = XCTestExpectation(description: "Initial deal completes")
        sut.onNewCardsDealt = {
            expectation.fulfill()
        }
        
        // Act
        sut.dealInitialCards()
        
        // Assert
        // Wait for the asynchronous dealing to potentially complete
        // Note: Direct async verification is better if possible, but this checks the end state.
        wait(for: [expectation], timeout: 5.0) // Adjust timeout as needed based on animation delays
        
        // Use GridConstants.initialCardCount
        XCTAssertEqual(sut.cardPositions.count, GridConstants.initialCardCount, "Should deal the standard number of cards")
        XCTAssertFalse(sut.isGameOver, "Game should not be over after initial deal")
        XCTAssertEqual(sut.score, 0, "Score should be zero initially")
    }
    
    func testInitialDeal_WhenDeckHasFewCards_DealsOnlyAvailableCards() {
        // Arrange
        let cardsToKeep = 10
        var smallDeckCards = [Card]()
        for i in 0..<cardsToKeep {
            // Create unique cards to avoid potential issues if Card relied on reference equality
            smallDeckCards.append(Card(suit: .hearts, rank: Rank.allCases[i]))
        }
        
        // Directly set the deck using internal access
        sut.deck = smallDeckCards.reversed() // dealInitialCards uses popLast, so reverse the prepared list

        let expectation = XCTestExpectation(description: "Initial deal with small deck completes")
        sut.onNewCardsDealt = {
            expectation.fulfill()
        }

        // Act
        sut.dealInitialCards()

        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(sut.cardPositions.count, cardsToKeep, "Should deal only the remaining cards")
        XCTAssertFalse(sut.isGameOver, "Game should not be over")
        XCTAssertTrue(sut.deck.isEmpty, "Deck should be empty after dealing all cards") // Added check
    }


    func testResetState_ClearsAllPropertiesAndResetsDeck() {
        // Arrange
        // Simulate some game state
        sut.dealInitialCards() 
        // Wait briefly for deal animation simulation if needed, though state should update sync
         let expectation = XCTestExpectation(description: "Initial deal for reset test completes")
         sut.onNewCardsDealt = { expectation.fulfill() }
         sut.dealInitialCards()
         wait(for: [expectation], timeout: 5.0)

        sut.updateScore(by: 100)
        sut.setLastPlayedHand(.straight)
        sut.setUserInteracted()
        // Simulate game over (might need a helper to force this state)
        // sut.isGameOver = true // Cannot directly set private(set) - need a test method or trigger game over

        // Act
        sut.resetState()

        // Assert
        XCTAssertTrue(sut.cardPositions.isEmpty, "Card positions should be empty after reset")
        XCTAssertEqual(sut.score, 0, "Score should be zero after reset")
        XCTAssertFalse(sut.isGameOver, "Game over flag should be false after reset")
        XCTAssertNil(sut.lastPlayedHand, "Last played hand should be nil after reset")
        XCTAssertFalse(sut.hasUserInteractedThisGame, "User interaction flag should be false after reset")
        // Use DeckConstants or just 52? Assuming standard deck size.
        XCTAssertEqual(sut.deck.count, 52, "Deck should be reset to a full deck") 
    }

    // MARK: - Card Removal, Shift, Deal Tests (Async)

    func testRemoveCardsAndShiftAndDeal_RemovesPlayedCards() async throws {
        // Arrange
        setupGameStateWithSimpleLayout() // Helper to set specific card positions
        let cardsToRemove = [
            sut.cardAt(row: 4, col: 0)!, // Bottom-left card
            sut.cardAt(row: 4, col: 1)!  // Card next to it
        ]
        let initialCount = sut.cardPositions.count
        let removeCount = cardsToRemove.count

        // Expectations for callbacks
        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)

        // Assert
        // Check that the specific cards are gone
        let remainingCardIDs = Set(sut.cardPositions.map { $0.card.id })
        for removedCard in cardsToRemove {
            XCTAssertFalse(remainingCardIDs.contains(removedCard.id), "Removed card \(removedCard.shortName) should not be present")
        }
        
        // Check total count (will be refilled, so check against grid size)
        // Use GridConstants.initialCardCount or rows*cols
        let expectedFinalCount = GridConstants.rows * GridConstants.columns
        XCTAssertEqual(sut.cardPositions.count, expectedFinalCount, "Grid should be full after removing and dealing")

        // Wait for callbacks
        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0) // Adjust timeout
    }
    
    func testShiftCardsDown_SingleGap() async throws {
        // Arrange
        // Layout: Card A (r3,c0), GAP (r4,c0)
        let cardA = Card(suit: .hearts, rank: .ace)
        sut.cardPositions = [
            CardPosition(card: cardA, row: 3, col: 0) 
            // Other columns can be empty or full, doesn't matter for this test
        ]
        
        let cardsToRemove = [Card(suit: .spades, rank: .king)] // Dummy removed card info
        let emptyPositions = [(4, 0)] // The gap below Card A
        
        // Act
        // We need to test shiftCardsDown in isolation. It's private.
        // Options: 1) Make it internal for testing. 2) Test via removeCardsAndShiftAndDeal.
        // Let's try testing via the public method, ensuring setup leads to the desired shift.
        
        // Refined Arrange: Set up a state where removing a card CREATES the gap at (4,0)
        let cardToRemove = Card(suit: .spades, rank: .king)
        sut.cardPositions = [
            CardPosition(card: cardA, row: 3, col: 0),
            CardPosition(card: cardToRemove, row: 4, col: 0) 
        ]
        
        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: [cardToRemove])

        // Assert
        // Verify Card A shifted down
        let cardAPosition = sut.cardPositions.first { $0.card.id == cardA.id }
        XCTAssertNotNil(cardAPosition, "Card A should still be present")
        XCTAssertEqual(cardAPosition?.currentRow, 4, "Card A should have shifted down to row 4")
        XCTAssertEqual(cardAPosition?.currentCol, 0, "Card A should remain in column 0")
        
        // Check that a new card filled the top slot (0,0) or (1,0) depending on grid size?
        // Need to know GridConstants.rows to be precise. Assuming 5 rows.
        // The new card should be at row 0 after shift+deal fills from top.
        let newCardAtTop = sut.cardPositions.contains { $0.currentRow == 0 && $0.currentCol == 0 }
        XCTAssertTrue(newCardAtTop, "A new card should have filled the top slot in column 0")
        
        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0)
    }
    
    func testShiftCardsDown_MultipleGaps_SingleColumn() async throws {
        // Arrange
        // Column 0: C, C, GAP, C, GAP (rows 0, 1, 3 filled initially)
        let card00 = Card(suit: .hearts, rank: .ten)
        let card10 = Card(suit: .hearts, rank: .jack)
        let card30 = Card(suit: .hearts, rank: .queen)
        let cardToRemove20 = Card(suit: .spades, rank: .two)
        let cardToRemove40 = Card(suit: .spades, rank: .three)
        
        sut.cardPositions = [
            CardPosition(card: card00, row: 0, col: 0),
            CardPosition(card: card10, row: 1, col: 0),
            CardPosition(card: cardToRemove20, row: 2, col: 0),
            CardPosition(card: card30, row: 3, col: 0),
            CardPosition(card: cardToRemove40, row: 4, col: 0)
            // Add cards in other columns to ensure grid is full for simplicity
        ]
        fillRemainingGridSimple(startCol: 1)

        let cardsToRemove = [cardToRemove20, cardToRemove40]
        let initialDeckSize = sut.deck.count
        
        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)

        // Assert
        // Expected final state in Col 0 (bottom up): card00, card10, card30, NewCard1, NewCard2
        // Check positions of original cards
        XCTAssertEqual(sut.cardAt(row: 2, col: 0)?.id, card30.id, "Card Q♥ should shift to row 2")
        XCTAssertEqual(sut.cardAt(row: 3, col: 0)?.id, card10.id, "Card J♥ should shift to row 3")
        XCTAssertEqual(sut.cardAt(row: 4, col: 0)?.id, card00.id, "Card T♥ should shift to row 4")
        
        // Check that new cards filled the top slots (rows 0, 1)
        XCTAssertNotNil(sut.cardAt(row: 0, col: 0), "New card should be at 0,0")
        XCTAssertNotNil(sut.cardAt(row: 1, col: 0), "New card should be at 1,0")
        // Verify these aren't the original cards
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card00.id)
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card10.id)
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card30.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card00.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card10.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card30.id)
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")
        XCTAssertEqual(sut.deck.count, initialDeckSize - 2, "Deck should have 2 fewer cards")
        
        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0)
    }
    
    func testShiftCardsDown_Gaps_MultipleColumns() async throws {
        // Arrange
        // Col 0: C, GAP, C (rows 0, 2 filled) -> Remove C at row 4
        // Col 1: C, C, GAP (rows 0, 1 filled) -> Remove C at row 3
        let card00 = Card(suit: .hearts, rank: .two)
        let card20 = Card(suit: .hearts, rank: .three)
        let cardToRemove40 = Card(suit: .spades, rank: .king) // Gap at 4,0
        
        let card01 = Card(suit: .clubs, rank: .four)
        let card11 = Card(suit: .clubs, rank: .five)
        let cardToRemove31 = Card(suit: .diamonds, rank: .queen) // Gap at 3,1
        
        sut.cardPositions = [
            CardPosition(card: card00, row: 0, col: 0),
            // Gap at 1,0 initially
            CardPosition(card: card20, row: 2, col: 0),
            // Gap at 3,0 initially
            CardPosition(card: cardToRemove40, row: 4, col: 0), // To be removed
            
            CardPosition(card: card01, row: 0, col: 1),
            CardPosition(card: card11, row: 1, col: 1),
            // Gap at 2,1 initially
            CardPosition(card: cardToRemove31, row: 3, col: 1), // To be removed
            // Gap at 4,1 initially
        ]
        fillRemainingGridSimple(startCol: 2) // Fill other columns
        
        let cardsToRemove = [cardToRemove40, cardToRemove31]
        let initialDeckSize = sut.deck.count

        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        // Expected Col 0 (bottom-up): card00, card20, New1, New2, New3
        XCTAssertEqual(sut.cardAt(row: 4, col: 0)?.id, card00.id, "Col 0: 2H should shift to row 4")
        XCTAssertEqual(sut.cardAt(row: 3, col: 0)?.id, card20.id, "Col 0: 3H should shift to row 3")
        XCTAssertNotNil(sut.cardAt(row: 0, col: 0), "Col 0: New card should be at 0,0")
        XCTAssertNotNil(sut.cardAt(row: 1, col: 0), "Col 0: New card should be at 1,0")
        XCTAssertNotNil(sut.cardAt(row: 2, col: 0), "Col 0: New card should be at 2,0")
        
        // Expected Col 1 (bottom-up): card01, card11, New4, New5, New6
        XCTAssertEqual(sut.cardAt(row: 4, col: 1)?.id, card01.id, "Col 1: 4C should shift to row 4")
        XCTAssertEqual(sut.cardAt(row: 3, col: 1)?.id, card11.id, "Col 1: 5C should shift to row 3")
        XCTAssertNotNil(sut.cardAt(row: 0, col: 1), "Col 1: New card should be at 0,1")
        XCTAssertNotNil(sut.cardAt(row: 1, col: 1), "Col 1: New card should be at 1,1")
        XCTAssertNotNil(sut.cardAt(row: 2, col: 1), "Col 1: New card should be at 2,1")
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")
        XCTAssertEqual(sut.deck.count, initialDeckSize - cardsToRemove.count, "Deck should reflect dealt cards")

        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0)
    }

    func testShiftCardsDown_ColumnBecomesEmpty() async throws {
        // Arrange
        // Column 2 only has one card at row 3, which we remove.
        let cardToRemove32 = Card(suit: .diamonds, rank: .jack)
        sut.cardPositions = [
            CardPosition(card: cardToRemove32, row: 3, col: 2)
        ]
        fillRemainingGridSimple(startCol: 0, skipCol: 2) // Fill other columns
        
        let cardsToRemove = [cardToRemove32]
        let initialDeckSize = sut.deck.count
        let expectedNewCards = GridConstants.rows // Entire column needs filling
        
        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        // Column 2 should be filled with new cards
        for row in 0..<GridConstants.rows {
             let card = sut.cardAt(row: row, col: 2)
             XCTAssertNotNil(card, "Col 2: New card expected at row \(row)")
             XCTAssertNotEqual(card?.id, cardToRemove32.id, "Col 2: Card at row \(row) should not be the removed card")
        }
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")
        // Deck count check is tricky if fillRemainingGridSimple used many cards. Check relative?
        // Check that *at least* expectedNewCards were dealt
        XCTAssertLessThanOrEqual(sut.deck.count, initialDeckSize - expectedNewCards, "Deck should have dealt at least \(expectedNewCards) cards")

        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0)
    }
    
    func testShiftCardsDown_RemoveTopCards() async throws {
        // Arrange
        // Column 0: Remove C, Remove C, C, C, C (rows 0, 1 removed)
        let cardToRemove00 = Card(suit: .hearts, rank: .ace)
        let cardToRemove10 = Card(suit: .hearts, rank: .king)
        let card20 = Card(suit: .hearts, rank: .queen)
        let card30 = Card(suit: .hearts, rank: .jack)
        let card40 = Card(suit: .hearts, rank: .ten)
        
        sut.cardPositions = [
            CardPosition(card: cardToRemove00, row: 0, col: 0),
            CardPosition(card: cardToRemove10, row: 1, col: 0),
            CardPosition(card: card20, row: 2, col: 0),
            CardPosition(card: card30, row: 3, col: 0),
            CardPosition(card: card40, row: 4, col: 0)
        ]
        fillRemainingGridSimple(startCol: 1)

        let cardsToRemove = [cardToRemove00, cardToRemove10]
        let initialDeckSize = sut.deck.count
        
        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)

        // Assert
        // Expected final state in Col 0 (bottom up): Q, J, T, NewCard1, NewCard2
        XCTAssertEqual(sut.cardAt(row: 4, col: 0)?.id, card40.id, "Card TH should shift to row 4")
        XCTAssertEqual(sut.cardAt(row: 3, col: 0)?.id, card30.id, "Card JH should shift to row 3")
        XCTAssertEqual(sut.cardAt(row: 2, col: 0)?.id, card20.id, "Card QH should shift to row 2")
        
        // Check that new cards filled the top slots (rows 0, 1)
        XCTAssertNotNil(sut.cardAt(row: 0, col: 0), "New card should be at 0,0")
        XCTAssertNotNil(sut.cardAt(row: 1, col: 0), "New card should be at 1,0")
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card20.id)
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card30.id)
        XCTAssertNotEqual(sut.cardAt(row: 0, col: 0)?.id, card40.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card20.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card30.id)
        XCTAssertNotEqual(sut.cardAt(row: 1, col: 0)?.id, card40.id)
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")
        XCTAssertEqual(sut.deck.count, initialDeckSize - 2, "Deck should have 2 fewer cards")
        
        await fulfillment(of: [dealExpectation, gameOverExpectation], timeout: 5.0)
    }

    // Add more shift tests: multiple gaps, full/empty columns etc.

    // MARK: - Game Over Tests

    func testCheckGameOver_NoMovesLeft() {
        // Arrange: Setup a board state where no valid hands can be formed/selected
        // Example: A checkerboard pattern or cards where no 3+ are adjacent/form a hand
        sut.cardPositions = createGameOverState() // Need helper
        sut.deck = [] // Deck must be empty or condition won't trigger game over reliably unless board is full+unplayable

        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        sut.checkGameOver()

        // Assert
        XCTAssertTrue(sut.isGameOver, "Game should be over when no moves are possible")
        wait(for: [gameOverExpectation], timeout: 1.0)
    }

    func testCheckGameOver_MovesAvailable() {
        // Arrange: Setup a board state with a clearly valid & selectable hand
        sut.cardPositions = createPlayableState() // Need helper (e.g., 3 adjacent Aces)
        
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        sut.checkGameOver()

        // Assert
        XCTAssertFalse(sut.isGameOver, "Game should not be over when moves are possible")
        wait(for: [gameOverExpectation], timeout: 1.0)
    }
    
    func testCheckGameOver_EmptyDeck_PlayableHandExists() {
        // Arrange: Setup a board with < 25 cards, but a valid hand IS present
        sut.cardPositions = createPlayableState() // Uses 3 Aces + 2 others = 5 cards
        sut.deck = [] // Deck is empty
        
        XCTAssertLessThan(sut.cardPositions.count, GridConstants.initialCardCount, "Precondition: Card count < grid size")
        XCTAssertTrue(sut.deck.isEmpty, "Precondition: Deck is empty")
        
        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        sut.checkGameOver()

        // Assert
        XCTAssertFalse(sut.isGameOver, "Game should NOT be over when deck is empty but a playable hand exists")
        wait(for: [gameOverExpectation], timeout: 1.0)
    }

    func testCheckGameOver_EmptyDeck_NoPlayableHand() {
        // Arrange: Setup a board with < 25 cards, and NO valid hands are present
        sut.cardPositions = createGameOverState() // Uses scattered low cards = 8 cards
        sut.deck = [] // Deck is empty
        
        XCTAssertLessThan(sut.cardPositions.count, GridConstants.initialCardCount, "Precondition: Card count < grid size")
        XCTAssertTrue(sut.deck.isEmpty, "Precondition: Deck is empty")

        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        sut.checkGameOver()

        // Assert
        XCTAssertTrue(sut.isGameOver, "Game should BE over when deck is empty and no playable hand exists")
        wait(for: [gameOverExpectation], timeout: 1.0)
    }
    
    func testCheckGameOver_FullBoard_NoPlayableHand() {
        // Arrange: Setup a full board (25 cards) where no hands are possible
        // This requires a carefully constructed board state.
        sut.cardPositions = createFullBoardGameOverState() // Need new helper
        // Deck can be non-empty, result should be the same
        sut.deck = [Card(suit: .clubs, rank: .ace)] 
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.initialCardCount, "Precondition: Card count == grid size")
        XCTAssertFalse(sut.deck.isEmpty, "Precondition: Deck is not empty")

        let gameOverExpectation = XCTestExpectation(description: "onGameOverChecked called")
        sut.onGameOverChecked = { gameOverExpectation.fulfill() }

        // Act
        sut.checkGameOver()

        // Assert
        XCTAssertTrue(sut.isGameOver, "Game should BE over when board is full and no playable hand exists, regardless of deck")
        wait(for: [gameOverExpectation], timeout: 1.0)
    }

    // Add tests for empty deck scenarios specifically

    // MARK: - canSelectCards Tests (Helper for checkGameOver)
    // Now directly testable as it's internal

    func testCanSelectCards_AdjacentPair() throws {
        let card1 = Card(suit: .hearts, rank: .two)
        let card2 = Card(suit: .hearts, rank: .three)
        sut.cardPositions = [
            CardPosition(card: card1, row: 0, col: 0),
            CardPosition(card: card2, row: 0, col: 1)
        ]
        let result = sut.canSelectCards([card1, card2]) // Now callable
        XCTAssertTrue(result, "Adjacent cards should be selectable")
    }

    func testCanSelectCards_DiagonalPair() throws {
         let card1 = Card(suit: .hearts, rank: .two)
         let card2 = Card(suit: .hearts, rank: .three)
         sut.cardPositions = [
             CardPosition(card: card1, row: 0, col: 0),
             CardPosition(card: card2, row: 1, col: 1)
         ]
         let result = sut.canSelectCards([card1, card2]) // Now callable
         XCTAssertTrue(result, "Diagonally adjacent cards should be selectable")
    }
     
    func testCanSelectCards_NonAdjacentPair() throws {
        let card1 = Card(suit: .hearts, rank: .two)
        let card2 = Card(suit: .hearts, rank: .three)
        sut.cardPositions = [
            CardPosition(card: card1, row: 0, col: 0),
            CardPosition(card: card2, row: 0, col: 2) // Gap in between
        ]
        let result = sut.canSelectCards([card1, card2]) // Now callable
        XCTAssertFalse(result, "Non-adjacent cards should not be selectable")
    }
    
    func testCanSelectCards_ConnectedGroup() throws {
        let card1 = Card(suit: .hearts, rank: .two)   // 0,0
        let card2 = Card(suit: .hearts, rank: .three) // 0,1
        let card3 = Card(suit: .hearts, rank: .four)  // 1,1
        sut.cardPositions = [
            CardPosition(card: card1, row: 0, col: 0),
            CardPosition(card: card2, row: 0, col: 1),
            CardPosition(card: card3, row: 1, col: 1)
        ]
        let result = sut.canSelectCards([card1, card2, card3]) // Now callable
        XCTAssertTrue(result, "A connected group should be selectable")
    }

    func testCanSelectCards_DisconnectedGroup() throws {
        let card1 = Card(suit: .hearts, rank: .two)   // 0,0
        let card2 = Card(suit: .hearts, rank: .three) // 0,1
        let card3 = Card(suit: .hearts, rank: .four)  // 2,2 (Disconnected)
        sut.cardPositions = [
            CardPosition(card: card1, row: 0, col: 0),
            CardPosition(card: card2, row: 0, col: 1),
            CardPosition(card: card3, row: 2, col: 2)
        ]
        let result = sut.canSelectCards([card1, card2, card3]) // Now callable
        XCTAssertFalse(result, "A disconnected group should not be selectable")
    }

    // MARK: - Helper Methods

    // Helper to set up a predictable initial state (e.g., first 25 cards sequentially)
    func setupGameStateWithSimpleLayout() {
        var positions: [CardPosition] = []
        var cardIndex = 0
        let suits = Suit.allCases
        let ranks = Rank.allCases
        // Use GridConstants.rows and GridConstants.columns
        for row in 0..<GridConstants.rows {
            for col in 0..<GridConstants.columns {
                if cardIndex < 52 {
                    let suit = suits[cardIndex / ranks.count]
                    let rank = ranks[cardIndex % ranks.count]
                    positions.append(CardPosition(card: Card(suit: suit, rank: rank), row: row, col: col))
                    cardIndex += 1
                }
            }
        }
        sut.cardPositions = positions
        // Ensure deck is appropriate (e.g., remove the cards we just placed)
        sut.deck.removeFirst(min(positions.count, sut.deck.count)) 
    }
    
    // Helper to create a state guaranteed to have no valid moves
    func createGameOverState() -> [CardPosition] {
        // Example: Use low cards unlikely to form straights/flushes, placed non-adjacently
        // This is tricky to guarantee without knowing PokerHandDetector's exact logic
        // A simpler approach for testing: use specific ranks known not to form hands.
        // Let's just create a sparse grid for now.
        return [
            CardPosition(card: Card(suit: .hearts, rank: .two), row: 0, col: 0),
            CardPosition(card: Card(suit: .clubs, rank: .three), row: 0, col: 2),
            CardPosition(card: Card(suit: .diamonds, rank: .four), row: 0, col: 4),
            CardPosition(card: Card(suit: .spades, rank: .five), row: 2, col: 1),
            CardPosition(card: Card(suit: .hearts, rank: .six), row: 2, col: 3),
            CardPosition(card: Card(suit: .clubs, rank: .seven), row: 4, col: 0),
            CardPosition(card: Card(suit: .diamonds, rank: .eight), row: 4, col: 2),
            CardPosition(card: Card(suit: .spades, rank: .nine), row: 4, col: 4),
        ]
    }
    
    // Helper to create a state with a known playable hand
    func createPlayableState() -> [CardPosition] {
        // Example: Three Aces adjacent horizontally
         return [
            CardPosition(card: Card(suit: .hearts, rank: .ace), row: 2, col: 1),
            CardPosition(card: Card(suit: .clubs, rank: .ace), row: 2, col: 2),
            CardPosition(card: Card(suit: .diamonds, rank: .ace), row: 2, col: 3),
            // Add some other cards around them
            CardPosition(card: Card(suit: .spades, rank: .two), row: 0, col: 0),
            CardPosition(card: Card(suit: .hearts, rank: .three), row: 4, col: 4),
        ]
    }

    // Helper to create a FULL board state guaranteed to have no valid moves
    func createFullBoardGameOverState() -> [CardPosition] {
        // This is difficult to guarantee without knowing the hand detector perfectly.
        // Strategy: Alternate low/high cards and suits across the grid to break sequences/flushes.
        // Example using alternating ranks and suits (may need refinement based on HandDetector)
        var positions: [CardPosition] = []
        let lowRanks: [Rank] = [.two, .four, .six, .eight, .ten]
        let highRanks: [Rank] = [.three, .five, .seven, .nine, .jack] // Avoid A, K, Q initially
        let suits1: [Suit] = [.hearts, .diamonds]
        let suits2: [Suit] = [.clubs, .spades]
        var rankIndex = 0
        var suit1Index = 0
        var suit2Index = 0

        for row in 0..<GridConstants.rows {
            for col in 0..<GridConstants.columns {
                let rank: Rank
                let suit: Suit
                if (row + col) % 2 == 0 { // Checkerboard pattern
                    rank = lowRanks[rankIndex % lowRanks.count]
                    suit = suits1[suit1Index % suits1.count]
                    rankIndex += 1
                    suit1Index += 1
                } else {
                    rank = highRanks[rankIndex % highRanks.count]
                    suit = suits2[suit2Index % suits2.count]
                    rankIndex += 1
                    suit2Index += 1
                }
                positions.append(CardPosition(card: Card(suit: suit, rank: rank), row: row, col: col))
            }
        }
        // Ensure exactly 25 cards if grid size is 5x5
        return Array(positions.prefix(GridConstants.initialCardCount)) 
    }

    // Helper to access the internal deck (if needed and made accessible)
    // func getDeck() -> [Card] {
    //    return sut.deck 
    // }

    // Helper to fill the rest of the grid with simple cards, avoiding specified columns
    func fillRemainingGridSimple(startCol: Int, skipCol: Int? = nil) {
        var existingPositions = Set(sut.cardPositions.map { GridPosition(row: $0.currentRow, col: $0.currentCol) })
        var cardsToAdd: [CardPosition] = []
        var deckCardsUsed = 0
        
        // Iterate through columns then rows
        for col in startCol..<GridConstants.columns {
            if col == skipCol { continue }
            for row in 0..<GridConstants.rows {
                let currentGridPos = GridPosition(row: row, col: col)
                if !existingPositions.contains(currentGridPos) {
                    // Make sure we have cards left in the deck
                    if sut.deck.indices.contains(deckCardsUsed) {
                        let card = sut.deck[deckCardsUsed] // Use existing deck cards for simplicity
                        cardsToAdd.append(CardPosition(card: card, row: row, col: col))
                        existingPositions.insert(currentGridPos) // Add to set to avoid duplicates
                        deckCardsUsed += 1
                    } else {
                        // If deck runs out during test setup, create dummy cards
                        let dummyCard = Card(suit: .spades, rank: .init(rawValue: row + col) ?? .ace) // Simple unique card
                         cardsToAdd.append(CardPosition(card: dummyCard, row: row, col: col))
                         existingPositions.insert(currentGridPos)
                    }
                }
            }
        }
        
        sut.cardPositions.append(contentsOf: cardsToAdd)
        // Adjust the actual deck if we used cards from it
        if deckCardsUsed > 0 {
             sut.deck.removeFirst(deckCardsUsed)
        }
    }

    // MARK: - Deal New Cards Tests (Verification of placement)

    func testDealNewCards_FillsTopGap_SingleColumn() async throws {
        // Arrange
        // Remove card at (0,0). Expect new card to fill (0,0).
        let cardToRemove00 = sut.cardAt(row: 0, col: 0) ?? Card(suit: .hearts, rank: .ace) // Get existing or make one
        
        // Ensure the card is actually in the grid if we made one
        if sut.cardAt(row: 0, col: 0) == nil {
            sut.cardPositions.append(CardPosition(card: cardToRemove00, row: 0, col: 0))
            fillRemainingGridSimple(startCol: 0) // Fill rest of grid
        }
        
        let cardsToRemove = [cardToRemove00]
        let initialDeck = sut.deck // Copy deck before removal
        let expectedNewCard = initialDeck.last // popLast takes the last element

        XCTAssertNotNil(expectedNewCard, "Deck shouldn't be empty for this test")

        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        // Check that the new card filled the specific top slot
        let newCardAtPosition = sut.cardAt(row: 0, col: 0)
        XCTAssertNotNil(newCardAtPosition, "A new card should be at 0,0")
        XCTAssertEqual(newCardAtPosition?.id, expectedNewCard?.id, "The card at 0,0 should be the next one from the deck")
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")

        await fulfillment(of: [dealExpectation], timeout: 5.0)
    }

    func testDealNewCards_FillsMultipleTopGaps_SingleColumn() async throws {
        // Arrange
        // Remove cards at (0,0) and (1,0). Expect new cards at (0,0) and (1,0).
        setupGameStateWithSimpleLayout() // Start with a full grid
        let cardToRemove00 = sut.cardAt(row: 0, col: 0)!
        let cardToRemove10 = sut.cardAt(row: 1, col: 0)!
        
        let cardsToRemove = [cardToRemove00, cardToRemove10]
        let initialDeck = sut.deck
        let expectedNewCard1 = initialDeck.last // First card dealt (fills highest row index first? No, lowest index = top)
        let expectedNewCard2 = initialDeck.dropLast().last // Second card dealt

        XCTAssertNotNil(expectedNewCard1, "Deck needs at least 2 cards")
        XCTAssertNotNil(expectedNewCard2, "Deck needs at least 2 cards")
        XCTAssertNotEqual(expectedNewCard1?.id, expectedNewCard2?.id)

        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        let newCardAtPos00 = sut.cardAt(row: 0, col: 0)
        let newCardAtPos10 = sut.cardAt(row: 1, col: 0)

        XCTAssertNotNil(newCardAtPos00, "A new card should be at 0,0")
        XCTAssertNotNil(newCardAtPos10, "A new card should be at 1,0")
        
        // Verify the *correct* cards from the deck filled the slots. 
        // dealNewCardsToFillGrid sorts empty slots by (row, col) ascending.
        // So (0,0) gets filled first, then (1,0).
        // popLast gets the *end* of the deck array.
        XCTAssertEqual(newCardAtPos00?.id, expectedNewCard1?.id, "Card at 0,0 should be the last from initial deck")
        XCTAssertEqual(newCardAtPos10?.id, expectedNewCard2?.id, "Card at 1,0 should be the second-to-last from initial deck")
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")

        await fulfillment(of: [dealExpectation], timeout: 5.0)
    }
    
    func testDealNewCards_FillsTopGaps_MultipleColumns() async throws {
        // Arrange
        // Remove cards at (0,0) and (0,1). Expect new cards at (0,0) and (0,1).
        setupGameStateWithSimpleLayout()
        let cardToRemove00 = sut.cardAt(row: 0, col: 0)!
        let cardToRemove01 = sut.cardAt(row: 0, col: 1)!
        
        let cardsToRemove = [cardToRemove00, cardToRemove01]
        let initialDeck = sut.deck
        let expectedNewCard1 = initialDeck.last // Fills (0,0)
        let expectedNewCard2 = initialDeck.dropLast().last // Fills (0,1)

        XCTAssertNotNil(expectedNewCard1, "Deck needs at least 2 cards")
        XCTAssertNotNil(expectedNewCard2, "Deck needs at least 2 cards")

        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        let newCardAtPos00 = sut.cardAt(row: 0, col: 0)
        let newCardAtPos01 = sut.cardAt(row: 0, col: 1)

        XCTAssertNotNil(newCardAtPos00, "A new card should be at 0,0")
        XCTAssertNotNil(newCardAtPos01, "A new card should be at 0,1")
        
        // Empty slots sorted: (0,0), (0,1). 
        // popLast fills (0,0) first, then (0,1).
        XCTAssertEqual(newCardAtPos00?.id, expectedNewCard1?.id, "Card at 0,0 should be the last from initial deck")
        XCTAssertEqual(newCardAtPos01?.id, expectedNewCard2?.id, "Card at 0,1 should be the second-to-last from initial deck")
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")

        await fulfillment(of: [dealExpectation], timeout: 5.0)
    }
    
    func testDealNewCards_FillsGapBelowOtherCards() async throws {
        // Arrange
        // Remove card at (2,0). Cards at (3,0) and (4,0) shift down to (1,0) and (2,0)? NO. 
        // Let's re-verify shift logic: Cards shift to lowest available spot. 
        // If we have C at 0,0, C at 1,0 and remove C at 2,0. Nothing shifts.
        // New card should fill the TOPMOST empty slot, which is (0,1) if column 1 is empty, or (2,0).
        // Let's test removing (2,0) from a FULL column.
        setupGameStateWithSimpleLayout()
        let cardAt00 = sut.cardAt(row: 0, col: 0)!
        let cardAt10 = sut.cardAt(row: 1, col: 0)!
        let cardToRemove20 = sut.cardAt(row: 2, col: 0)! // Removed
        let cardAt30 = sut.cardAt(row: 3, col: 0)!
        let cardAt40 = sut.cardAt(row: 4, col: 0)!
        
        let cardsToRemove = [cardToRemove20]
        let initialDeck = sut.deck
        let expectedNewCard = initialDeck.last // Fills the single empty slot (0,1 or wherever)

        XCTAssertNotNil(expectedNewCard, "Deck needs at least 1 card")

        let dealExpectation = XCTestExpectation(description: "onNewCardsDealt called")
        sut.onNewCardsDealt = { dealExpectation.fulfill() }
        
        // Act
        await sut.removeCardsAndShiftAndDeal(playedCards: cardsToRemove)
        
        // Assert
        // Verify cards shifted: 40->4, 30->3, 10->2, 00->1. Gap is at 0,0.
        XCTAssertEqual(sut.cardAt(row: 4, col: 0)?.id, cardAt40.id)
        XCTAssertEqual(sut.cardAt(row: 3, col: 0)?.id, cardAt30.id)
        XCTAssertEqual(sut.cardAt(row: 2, col: 0)?.id, cardAt10.id)
        XCTAssertEqual(sut.cardAt(row: 1, col: 0)?.id, cardAt00.id)
        
        // Verify the new card filled the top slot (0,0)
        let newCardAtPos00 = sut.cardAt(row: 0, col: 0)
        XCTAssertNotNil(newCardAtPos00, "A new card should be at 0,0")
        XCTAssertEqual(newCardAtPos00?.id, expectedNewCard?.id, "Card at 0,0 should be the last from initial deck")
        
        XCTAssertEqual(sut.cardPositions.count, GridConstants.rows * GridConstants.columns, "Grid should be full")

        await fulfillment(of: [dealExpectation], timeout: 5.0)
    }
}

// Extension for Card (if not already present) for easier debugging/logging
extension Card {
    var shortName: String { "\(rank.symbol)\(suit.symbol)" }
} 