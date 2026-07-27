//
//  SimpleTimer.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 02.07.26.
//

import Foundation

/// SimpleLoopTimer
///
enum SimpleLoopTimer {

    /// Creates and starts a simple repeating timer task.
    ///
    /// A lightweight loop that repeatedly executes the provided async closure with a fixed
    /// delay between executions: each cycle runs the body to completion, then waits the full
    /// interval before starting the next cycle.
    ///
    /// Cancellation: Cancel the returned task to stop the loop. The sleep is cancellation-aware,
    /// so the task will exit promptly when cancelled.
    ///
    ///
    /// - Parameters:
    ///   - interval: The delay, in seconds, between the end of one execution and the start of the next.
    ///   - body: The async closure to execute each cycle.
    /// - Returns: A `Task` you can cancel to stop the loop.
    ///
    /// - Note:
    /// - Uses a monotonic clock via `Task.sleep` to avoid being affected by wall-clock changes.
    /// - Because the interval is measured from the end of each execution, cycles never overlap
    ///   or run back-to-back, even if `body` takes longer than `interval`.
    /// - The first invocation happens after an initial delay of one interval; pass in an async
    ///   closure that cooperates with cancellation if you need quick shutdown.
    ///
    static func getSimpleLoopTimerWith(interval: TimeInterval, _ body: @Sendable @escaping () async -> Void) -> Task<Void, Never> {
        return Task { @Sendable in
            while !Task.isCancelled {
                await body()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
}
