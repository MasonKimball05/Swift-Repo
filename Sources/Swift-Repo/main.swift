import Foundation


// This file demonstrates how to use Swift Concurrency with Task groups to run multiple asynchronous child tasks, collect their results, and coordinate completion.

// Flush prints immediately to ensure output appears in real-time without buffering delays.
setbuf(stdout, nil)


//Function version of the previous code allowing for reuse
// Task allows async context to run, but async functions can be written above the entry of the context, basically im relearning how functions work


func runAsync(){
    print("Starting…")
    Task { //Enter the async context
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

    // Final message indicating all tasks have completed successfully.
    print("All tasks completed ✅")
}

runAsync()
