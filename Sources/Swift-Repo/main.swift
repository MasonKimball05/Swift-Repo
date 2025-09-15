import Foundation

// Flush prints immediately
setbuf(stdout, nil)

print("Starting…")

Task {
    print("[root] async Task started")

    await withTaskGroup(of: Int.self) { group in
        print("[root] creating child tasks")
        for i in 1...3 {
            group.addTask {
                print("  [child \(i)] scheduled")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                print("  [child \(i)] returning")
                return i
            }
        }

        print("[root] awaiting child results…")
        for await idx in group {
            print("[root] received result from task \(idx)")
        }
        print("[root] all child results received")
    }

    print("[root] stopping runloop")
    CFRunLoopStop(CFRunLoopGetMain())
}

// Keep the main thread's runloop alive so Swift Concurrency can schedule tasks
CFRunLoopRun()

print("All tasks completed ✅")