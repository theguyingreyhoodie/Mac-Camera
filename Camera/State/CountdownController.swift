import Observation

enum CountdownDuration: Int, CaseIterable {
    case off = 0, three = 3, five = 5, ten = 10

    var seconds: Int { rawValue }
    var label: String { self == .off ? "Off" : "\(rawValue)s" }

    /// The next choice when the timer button is tapped; wraps around to Off.
    var next: CountdownDuration {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

/// Timer state machine: idle → counting(n…1) → firing → idle.
@Observable
final class CountdownController {
    enum Phase: Equatable {
        case idle
        case counting(remaining: Int)
        case firing
    }

    private(set) var phase = Phase.idle
    var duration = CountdownDuration.off

    /// Called on every phase change (used by tests).
    @ObservationIgnored var onPhaseChange: ((Phase) -> Void)?
    @ObservationIgnored private let tickInterval: Duration
    @ObservationIgnored private var task: Task<Void, Never>?

    init(tickInterval: Duration = .seconds(1)) {
        self.tickInterval = tickInterval
    }

    var isCounting: Bool {
        if case .counting = phase { true } else { false }
    }

    /// Starts the countdown (or fires immediately when the duration is Off), then runs `fire`.
    /// Triggering while a countdown is running cancels it; while firing it is ignored.
    @discardableResult
    func trigger(_ fire: @escaping () async -> Void) -> Task<Void, Never> {
        switch phase {
        case .counting:
            cancel()
            return Task {}
        case .firing:
            return Task {}
        case .idle:
            break
        }

        let seconds = duration.seconds
        // Set synchronously so a quick second tap sees the countdown already running.
        setPhase(seconds > 0 ? .counting(remaining: seconds) : .firing)

        let newTask = Task { [weak self] in
            guard let self else { return }
            if seconds > 0 {
                for remaining in stride(from: seconds, through: 1, by: -1) {
                    guard !Task.isCancelled else { return }
                    self.setPhase(.counting(remaining: remaining))
                    do { try await Task.sleep(for: self.tickInterval) } catch { return }
                }
                guard !Task.isCancelled else { return }
                self.setPhase(.firing)
            }
            await fire()
            self.setPhase(.idle)
        }
        task = newTask
        return newTask
    }

    /// Cancels a running countdown. Does nothing once the photo is being taken.
    func cancel() {
        guard isCounting else { return }
        task?.cancel()
        task = nil
        setPhase(.idle)
    }

    private func setPhase(_ newPhase: Phase) {
        guard phase != newPhase else { return }
        phase = newPhase
        onPhaseChange?(newPhase)
    }
}
