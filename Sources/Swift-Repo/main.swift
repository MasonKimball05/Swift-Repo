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

func runPriorityTest(taskCount: Int = 5, workSeconds: UInt32 = 2) {
    let queue = DispatchQueue(label: "com.example.priority", attributes: .concurrent)
    print("[priority test] starting concurrent tasks with varying priorities")

    let priorities: [DispatchQoS] = [.userInteractive, .userInitiated, .default, .utility, .background]
    let group = DispatchGroup()

    for i in 1...taskCount {
        let qos = priorities[(i - 1) % priorities.count]
        group.enter()
        queue.async(group: group, qos: qos) {
            let label = qosName(qos)
            print("    [priority task \(i) - \(label)] starting")
            sleep(workSeconds)
            print("  [priority task \(i) - \(label)] completed")
            group.leave()
        }
    }

    // Block until all async tasks finish
    group.wait()
    print("[priority test] all priority tasks finished")
}

runAsync()
print()
print()
runSync()
print()
print()
runPriorityTest()