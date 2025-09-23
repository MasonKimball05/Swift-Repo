import Foundation

// This file demonstrates how to use Swift Concurrency with Task groups to run multiple asynchronous child tasks, collect their results, and coordinate completion.

// Flush prints immediately to ensure output appears in real-time without buffering delays.
setbuf(stdout, nil)

print("Starting…")

// Launch the async root task to manage child tasks concurrently.
func runAsync() {    
    Task {
        print("[root] async Task started")

        // Create a task group to run multiple child tasks concurrently and collect their results.
        await withTaskGroup(of: Int.self) { group in
            print("[root] creating child tasks")
            // Schedule five child tasks that each sleep for 1 second and then return their index.
            for i in 1...5 {
                group.addTask {
                    print("  [child \(i)] scheduled")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    print("  [child \(i)] returning")
                    return i
                }
            }

            print("[root] awaiting child results…")
            // Await each child task's result as they complete.
            for await idx in group {
                print("[root] received result from task \(idx)")
            }
            print("[root] all child results received")
        }

        // After all child tasks complete, stop the main runloop to allow the program to exit.
        print("[root] stopping runloop")
        CFRunLoopStop(CFRunLoopGetMain())
    }

    // Keep the main thread's runloop alive so Swift Concurrency can schedule tasks and run the async code.
    CFRunLoopRun()
}

// Final message indicating all tasks have completed successfully.
print("All tasks completed ✅")

func runSync(taskCount: Int=5, secondsPerTask: UInt32=1) {
    let queue = DispatchQueue(label: "com.example.sync")

    queue.sync {
        print("[sync] starting sequental tasks")
        for i in 1...taskCount {
            print("  [sync task \(i)] starting")
            sleep(secondsPerTask)
            print("[sync task \(i)] completed")
        }
        print("[sync] all sequential tasks completed ✅")
    }
}

// Short, readable name for a DispatchQoS
func qosName(_ qos: DispatchQoS) -> String {
    switch qos.qosClass {
    case .userInteractive: return "userInteractive"
    case .userInitiated:   return "userInitiated"
    case .default:         return "default"
    case .utility:         return "utility"
    case .background:      return "background"
    case .unspecified:     return "unspecified"
    @unknown default:      return "unknown"
    }
}

// CPU-bound busy work to create real scheduler contention (shows QoS more clearly than sleep)
@inline(__always)
func busy(ms: Int) {
    let end = Date().addingTimeInterval(Double(ms) / 1000)
    var x = 0
    while Date() < end { x &+= 1 }
    _ = x // prevent optimization
}

func runPriorityTest(
    taskCount: Int = 50,                 // oversubscribe CPU to force contention
    workMillis: Int = 800,               // per-task CPU work (ms)
    useBusyWork: Bool = true,            // true: CPU loop; false: sleep
    usePerQoSGlobalQueues: Bool = true   // true: DispatchQueue.global(qos: ...), false: one shared concurrent queue
) {
    print("[priority test] starting concurrent tasks with varying priorities")

    let priorities: [DispatchQoS] = [.userInteractive, .userInitiated, .default, .utility, .background]
    let group = DispatchGroup()

    // Choose queue strategy
    let sharedQueue = DispatchQueue(label: "com.example.priority.shared", attributes: .concurrent)

    for i in 1...taskCount {
        let qos = priorities[(i - 1) % priorities.count]
        let label = qosName(qos)

        let q: DispatchQueue = usePerQoSGlobalQueues
            ? DispatchQueue.global(qos: qos.qosClass)
            : sharedQueue

        group.enter()
        q.async(group: group) {
            print("    [priority task \(i) - \(label)] starting")
            if useBusyWork {
                busy(ms: workMillis)
            } else {
                sleep(UInt32(max(1, workMillis / 1000)))
            }
            print("  [priority task \(i) - \(label)] completed")
            group.leave()
        }
    }

    group.wait()
    print("[priority test] all priority tasks finished")
}

/// Runs QoS tiers strictly: all `userInteractive` tasks must FINISH before any `userInitiated` task STARTS, etc.
/// This enforces priority by batching work per tier and waiting for completion between tiers.
func runPriorityTestStrict(
    tasksPerQoS: Int = 5,
    workMillis: Int = 800,
    useBusyWork: Bool = true
) {
    print("[priority strict] starting (tiers will run sequentially)")

    // Highest to lowest QoS order
    let tiers: [DispatchQoS] = [.userInteractive, .userInitiated, .default, .utility, .background]

    for qos in tiers {
        let label = qosName(qos)
        print("[priority strict] starting tier: \(label)")

        // Use a dedicated concurrent queue for this tier so we don't mix with other tiers
        let tierQueue = DispatchQueue(
            label: "com.example.priority.strict.\(label)",
            qos: qos,
            attributes: .concurrent
        )

        let group = DispatchGroup()
        for i in 1...tasksPerQoS {
            group.enter()
            tierQueue.async {
                print("  [tier \(label) task \(i)] starting")
                if useBusyWork {
                    busy(ms: workMillis)
                } else {
                    sleep(UInt32(max(1, workMillis / 1000)))
                }
                print("  [tier \(label) task \(i)] completed")
                group.leave()
            }
        }

        // BLOCK here so that no lower tier tasks are even submitted yet
        group.wait()
        print("[priority strict] finished tier: \(label)")
    }

    print("[priority strict] all tiers finished")
}

runAsync()
print()
print()
runSync()
print()
print()
runPriorityTestStrict(tasksPerQoS: 5, workMillis: 800, useBusyWork: true)