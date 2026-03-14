import Testing
@testable import WhisperDictation

@Suite("AudioBufferManager")
struct AudioBufferManagerTests {
    @Test("Append and consume returns all samples")
    func appendAndConsume() {
        let buffer = AudioBufferManager()
        let samples: [Float] = [1.0, 2.0, 3.0]
        buffer.append(samples)
        let result = buffer.consumeAll()
        #expect(result == samples)
    }

    @Test("Consume empties buffer")
    func consumeEmptiesBuffer() {
        let buffer = AudioBufferManager()
        buffer.append([1.0, 2.0])
        _ = buffer.consumeAll()
        let second = buffer.consumeAll()
        #expect(second.isEmpty)
    }

    @Test("Clear resets buffer")
    func clearResetsBuffer() {
        let buffer = AudioBufferManager()
        buffer.append([1.0, 2.0, 3.0])
        buffer.clear()
        let result = buffer.consumeAll()
        #expect(result.isEmpty)
    }

    @Test("Thread safety with concurrent appends")
    func threadSafety() async {
        let buffer = AudioBufferManager()
        let iterations = 1000

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<iterations {
                        buffer.append([Float(i * iterations + j)])
                    }
                }
            }
        }

        let result = buffer.consumeAll()
        #expect(result.count == 10 * iterations)
    }

    @Test("Consume preserves order")
    func consumePreservesOrder() {
        let buffer = AudioBufferManager()
        let samples: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        buffer.append(samples)
        let result = buffer.consumeAll()
        #expect(result == samples)
    }

    @Test("Multiple append/consume cycles")
    func multipleAppendCycles() {
        let buffer = AudioBufferManager()
        buffer.append([1.0, 2.0])
        let first = buffer.consumeAll()
        #expect(first == [1.0, 2.0])

        buffer.append([3.0, 4.0])
        let second = buffer.consumeAll()
        #expect(second == [3.0, 4.0])
    }

    @Test("Empty buffer consume returns empty")
    func emptyBufferConsume() {
        let buffer = AudioBufferManager()
        let result = buffer.consumeAll()
        #expect(result.isEmpty)
    }

    @Test("Append after clear works")
    func appendAfterClear() {
        let buffer = AudioBufferManager()
        buffer.append([1.0])
        buffer.clear()
        buffer.append([2.0, 3.0])
        let result = buffer.consumeAll()
        #expect(result == [2.0, 3.0])
    }

    @Test("Multiple appends accumulate")
    func multipleAppendsAccumulate() {
        let buffer = AudioBufferManager()
        buffer.append([1.0, 2.0])
        buffer.append([3.0, 4.0])
        buffer.append([5.0])
        let result = buffer.consumeAll()
        #expect(result == [1.0, 2.0, 3.0, 4.0, 5.0])
    }
}
