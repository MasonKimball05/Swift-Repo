import Foundation

@main
struct App {
    static func main() async {
        await MainActor.run {
            print("Starting on MainActor")
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...3 {
                group.addTask {
                    try? await Task.sleep(nanoseconds: UInt64(Int.random(in: 1...3)) * 1_000_000_000)
                    await MainActor.run {
                        print("Task \(i) completed (main? \(Thread.isMainThread))")
                    }
                }
            }
            await MainActor.run {
                print("All tasks completed (main? \(Thread.isMainThread))")
            }
        }
    }
}