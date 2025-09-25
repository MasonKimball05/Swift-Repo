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
                    print("    [child \(i)] scheduled")
                    var seconds = UInt64(Int.random(in: 1...5))
                    try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                    print("    [child \(i)] completed after \(seconds) seconds")
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

func runSync(taskCount: Int=5, secondsPerTask: UInt32=1) -> [Int] {
    let queue = DispatchQueue(label: "com.example.sync")
    var syncNum: [Int] = []

    queue.sync {
        print("[sync] starting sequental tasks")
        for i in 1...taskCount {
            print("  [sync task \(i)] starting")
            sleep(secondsPerTask)
            print("[sync task \(i)] completed")
            var numToAdd = Int.random(in: 1...200)
            syncNum.append(numToAdd)
        }
        print("[sync] all sequential tasks completed ✅")
    }
    print(syncNum)
    return syncNum 
}



/// Executes tasks in order of priority based on values in a provided array.
///
/// This function processes a specified number of tasks by selecting the highest priority task
/// (determined by the highest value in the provided array) each time. Each task is executed
/// asynchronously on a serial queue but the function waits for all tasks to complete before returning.
///
/// - Parameters:
///   - taskCount: The number of tasks to execute. Default is 5.
///   - secondsPerTask: The duration in seconds that each task should take to complete. Default is 1.
///   - numList: An array of integers where each value represents the priority level of a task.
///              Higher values indicate higher priority.
///
/// - Note: This implementation uses a dispatch group to track when all tasks have completed.
///         The function will block the current thread until all tasks have finished.
///
/// ## Example usage:
/// ```
/// let priorities = [3, 1, 5, 2, 4]
/// runPriority(taskCount: 3, secondsPerTask: 2, numList: priorities)
/// ```
func runPriority(taskCount: Int=5, secondsPerTask: UInt32=1, numList: [Int]) {
    let queue = DispatchQueue(label: "com.example.priority")
    var numsList = numList
    let group = DispatchGroup() // Add tasks to a group for concurrent execution


    /*
    queue.sync {
        print("[async priority] starting tasks with priority")
        for i in 1...taskCount {
            let maxValue = numsList.max()!
            let index = numsList.firstIndex(of: maxValue)!
            let ei = numList.firstIndex(of: numsList[index])!
            print("[priority task \(ei + 1)] starting; priority level: \(maxValue)")
            sleep(secondsPerTask)
            print("[priority task \(ei + 1)] completed")
            numsList.remove(at: index)
        }

        print("[priority] all priority tasks completed ✅" )
    }
    */

    print("[priority] starting tasks with priority")
    for i in 1...taskCount { //Runs for task count
        group.enter()
        queue.async(group: group) {
            let maxValue = numsList.max()! //Max value in list
            let index = numsList.firstIndex(of: maxValue)! //Index of max value in mutable list
            let ei = numList.firstIndex(of: numsList[index])! //Index of max value in original list
            print("[priority task \(ei + 1)] starting; priority level: \(maxValue)")
            sleep(secondsPerTask)
            print("[priority task \(ei + 1)] completed")
            numsList.remove(at: index)
            group.leave()
        }

        
    }
    group.wait()
    print("[priority] all priority tasks completed ✅" )
}

runAsync()
print()
print()
var list = runSync()
print()
print()
runPriority(numList: list)
