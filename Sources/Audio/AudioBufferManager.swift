import Foundation

final class AudioBufferManager {
    private var buffer: [Float] = []
    private let lock = NSLock()

    func append(_ samples: [Float]) {
        lock.lock()
        buffer.append(contentsOf: samples)
        lock.unlock()
    }

    func consumeAll() -> [Float] {
        lock.lock()
        let result = buffer
        buffer.removeAll(keepingCapacity: true)
        lock.unlock()
        return result
    }

    /// Read all samples without consuming them (for streaming transcription).
    func snapshotAll() -> [Float] {
        lock.lock()
        let result = buffer
        lock.unlock()
        return result
    }

    func clear() {
        lock.lock()
        buffer.removeAll(keepingCapacity: true)
        lock.unlock()
    }
}
