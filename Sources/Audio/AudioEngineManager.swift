import AVFoundation
import os

final class AudioEngineManager {
    private var engine: AVAudioEngine?
    private let bufferManager = AudioBufferManager()

    /// Current RMS audio level (0.0–1.0 range, updated from audio tap).
    private(set) var currentLevel: Float = 0

    /// Optional callback for real-time audio feed (used by fast streaming mode).
    var onAudioSamples: (([Float]) -> Void)?

    func startCapture() {
        let engine = AVAudioEngine()
        self.engine = engine

        let inputNode = engine.inputNode
        let nativeFormat = inputNode.inputFormat(forBus: 0)

        Logger.audio.info("Native audio format: \(nativeFormat.sampleRate)Hz, \(nativeFormat.channelCount)ch")

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        let converter = AVAudioConverter(from: nativeFormat, to: targetFormat)!

        bufferManager.clear()

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [bufferManager, weak self] pcmBuffer, _ in
            let frameCount = pcmBuffer.frameLength
            guard frameCount > 0 else { return }

            let ratio = 16000.0 / nativeFormat.sampleRate
            let outputFrameCount = AVAudioFrameCount(Double(frameCount) * ratio)
            guard outputFrameCount > 0 else { return }

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputFrameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return pcmBuffer
            }

            if status == .error {
                Logger.audio.error("Conversion error: \(error?.localizedDescription ?? "unknown")")
                return
            }

            if let channelData = outputBuffer.floatChannelData {
                let samples = Array(UnsafeBufferPointer(
                    start: channelData[0],
                    count: Int(outputBuffer.frameLength)
                ))
                bufferManager.append(samples)
                // Update RMS level for audio indicator
                let rms = Self.rmsLevel(samples)
                DispatchQueue.main.async { [weak self] in
                    self?.currentLevel = rms
                }
                self?.onAudioSamples?(samples)
            }
        }

        do {
            try engine.start()
            Logger.audio.info("Audio capture started")
        } catch {
            Logger.audio.error("Failed to start audio engine: \(error.localizedDescription)")
            inputNode.removeTap(onBus: 0)
            self.engine = nil
        }
    }

    /// Snapshot current audio without stopping capture (for streaming mode).
    func snapshotAudio() -> [Float] {
        return bufferManager.snapshotAll()
    }

    private static func rmsLevel(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(Float(0)) { $0 + $1 * $1 }
        return sqrt(sum / Float(samples.count))
    }

    func stopCapture() -> [Float] {
        guard let engine else {
            Logger.audio.warning("stopCapture called but no engine running")
            return []
        }

        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        self.engine = nil

        let samples = bufferManager.consumeAll()
        Logger.audio.info("Audio capture stopped, collected \(samples.count) samples")
        return samples
    }
}
