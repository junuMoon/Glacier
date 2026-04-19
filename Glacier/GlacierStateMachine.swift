enum GlacierState: Equatable {
    case closed
    case hiddenOpen
    case allOpen
    case editing
}

enum GlacierInput {
    case primaryClick
    case boundaryClick
    case alternateClick
    case escape
    case enterEditing
    case finishEditing
}

struct GlacierStateMachine {
    private(set) var state: GlacierState = .closed

    @discardableResult
    mutating func handle(_ input: GlacierInput) -> GlacierState {
        switch (state, input) {
        case (.closed, .primaryClick):
            state = .hiddenOpen
        case (.hiddenOpen, .primaryClick), (.allOpen, .primaryClick):
            state = .closed

        case (.hiddenOpen, .boundaryClick):
            state = .allOpen
        case (.allOpen, .boundaryClick):
            state = .hiddenOpen
        case (.closed, .boundaryClick):
            break

        case (.closed, .alternateClick):
            state = .allOpen
        case (.hiddenOpen, .alternateClick):
            state = .allOpen
        case (.allOpen, .alternateClick):
            state = .closed

        case (.editing, .primaryClick), (.editing, .boundaryClick), (.editing, .alternateClick):
            break

        case (_, .escape), (_, .finishEditing):
            state = .closed

        case (_, .enterEditing):
            state = .editing
        }

        return state
    }
}

extension GlacierStateMachine {
    /// Used by unit tests to seed uncommon states without simulating long click sequences.
    mutating func setStateForTesting(_ newState: GlacierState) {
        state = newState
    }
}
