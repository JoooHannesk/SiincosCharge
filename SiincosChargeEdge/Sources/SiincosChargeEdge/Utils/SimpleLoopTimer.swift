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
    /// A lightweight loop that repeatedly executes the provided async closure at the given
    /// interval. The task fires the body immediately on start, then schedules subsequent
    /// executions aligned to the requested interval (attempting to avoid drift by calculating
    /// the next fire time from the previous scheduled time rather than from `now`).
    ///
    /// Cancellation: Cancel the returned task to stop the loop. The sleep is cancellation-aware,
    /// so the task will exit promptly when cancelled.
    ///
    ///
    /// - Parameters:
    ///   - interval: The interval, in seconds, at which to execute the closure.
    ///   - body: The async closure to execute each cycle.
    /// - Returns: A `Task` you can cancel to stop the loop.
    ///
    /// - Note:
    /// - Uses a monotonic clock via `Task.sleep` to avoid being affected by wall-clock changes.
    /// - If `body` takes longer than `interval`, the next iteration runs immediately (no catch-up),
    ///   and the schedule continues from the last planned fire time.
    /// - The first invocation happens immediately; pass in an async closure that cooperates
    ///   with cancellation if you need quick shutdown.
    ///
    static func getSimpleLoopTimerWith(interval: TimeInterval, _ body: @Sendable @escaping () async -> Void) -> Task<Void, Never> {
        return Task { @Sendable in
            var nextFire = Date()
            while !Task.isCancelled {
                await body()
                nextFire = nextFire.addingTimeInterval(interval)
                let remaining = max(0, nextFire.timeIntervalSinceNow)
                try? await Task.sleep(for: .seconds(remaining))
            }
        }
    }
}
