import Foundation
import Network
import Observation

@Observable
@MainActor
final class ReachabilityObserver {
    private(set) var isOnline: Bool = false
    var onChange: ((Bool) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.antinoise.reachability")
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = (path.status == .satisfied)
            Task { @MainActor in
                guard let self else { return }
                let prev = self.isOnline
                self.isOnline = online
                if prev != online {
                    self.onChange?(online)
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
