import XCTest

@testable import Glacier

final class GlacierStateMachineTests: XCTestCase {

    func testEditingIgnoresMarkerClicks() {
        var sm = GlacierStateMachine()
        sm.setStateForTesting(.editing)

        sm.handle(.primaryClick)
        XCTAssertEqual(sm.state, .editing)

        sm.handle(.boundaryClick)
        XCTAssertEqual(sm.state, .editing)

        sm.handle(.alternateClick)
        XCTAssertEqual(sm.state, .editing)
    }

    func testEditingClosesOnEscapeOrFinish() {
        var sm = GlacierStateMachine()
        sm.setStateForTesting(.editing)

        sm.handle(.escape)
        XCTAssertEqual(sm.state, .closed)

        sm.setStateForTesting(.editing)
        sm.handle(.finishEditing)
        XCTAssertEqual(sm.state, .closed)
    }

    func testHiddenOpenPrimaryCloses() {
        var sm = GlacierStateMachine()
        sm.setStateForTesting(.hiddenOpen)
        sm.handle(.primaryClick)
        XCTAssertEqual(sm.state, .closed)
    }

    func testEscapeClosesNonEditingStates() {
        var sm = GlacierStateMachine()
        sm.setStateForTesting(.hiddenOpen)
        sm.handle(.escape)
        XCTAssertEqual(sm.state, .closed)

        sm.setStateForTesting(.allOpen)
        sm.handle(.escape)
        XCTAssertEqual(sm.state, .closed)
    }

    func testEnterEditingFromClosed() {
        var sm = GlacierStateMachine()
        sm.setStateForTesting(.closed)
        sm.handle(.enterEditing)
        XCTAssertEqual(sm.state, .editing)
    }
}
