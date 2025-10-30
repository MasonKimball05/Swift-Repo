func bufferManipulationExample() {    
    let count = 3
    print("Allocating memory for \(count) Int values...")
    let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
    print("Memory allocated at address: \(pointer)")

    print("Initializing buffer with zeros...")
    pointer.initialize(repeating: 0, count: count)
    print("Initial buffer state: [\(pointer[0]), \(pointer[1]), \(pointer[2])]")

    for i in 0..<count {
        pointer[i] = i * 10
        let address = pointer.advanced(by: i)
        print("Set pointer[\(i)] = \(pointer[i])")
        print("Address of pointer[\(i)] = \(address), value = \(address.pointee)")
    }

    print("Creating UnsafeBufferPointer to view memory...")
    let buffer = UnsafeBufferPointer(start: pointer, count: count)
    print("Buffer contents: \(buffer.map { $0 })")  // [0, 10, 20]

    print("Deinitializing memory...")
    pointer.deinitialize(count: count)
    print("Deallocating memory...")
    pointer.deallocate()
    print("Memory successfully freed.")
}

bufferManipulationExample()
