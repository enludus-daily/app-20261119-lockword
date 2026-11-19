import AVFoundation

/// 効果音（端末の中で作る。録音したファイルは持たない）。
/// 古い屋敷の夜：鍵盤は木のコツッ、言葉が解けると真鍮の鈴、道具は小さな鈴の連なり、錠は金属のカチャリ、
/// 違うと低い木の音、扉が開くと和音。消音スイッチに従い、ほかのアプリの音と混ぜる（.ambient）
@MainActor
final class SoundBox {
    static let shared = SoundBox()

    enum Cue: Hashable {
        case key, word, item, wrong, unlock, locked, door, page, hint, letter, escape
    }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private var prepared = false
    private let rate = 44_100.0
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)

    /// 音量の段階（五十音マインスイーパーの段階にならう：触る 0.4・開く 0.6・当たり 0.8）
    private func volume(_ cue: Cue) -> Float {
        switch cue {
        case .key, .page: 0.4
        case .hint, .locked, .door: 0.6
        case .wrong, .unlock: 0.7
        case .word, .item, .letter, .escape: 0.8
        }
    }

    private func prepare() -> Bool {
        if prepared { return engine.isRunning || ((try? engine.start()) != nil) }
        guard let format else { return false }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for _ in 0..<6 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        prepared = true
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    func play(_ cue: Cue) {
        guard prepare(), engine.isRunning else { return }
        let buffer: AVAudioPCMBuffer
        if let b = buffers[cue] {
            buffer = b
        } else {
            guard let b = make(cue) else { return }
            buffers[cue] = b
            buffer = b
        }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.volume = volume(cue)
        player.scheduleBuffer(buffer, at: nil, options: [])
        player.play()
    }

    // MARK: - 音を作る

    private struct Partial {
        var freq: Double
        var amp: Double
        var decay: Double
        var delay: Double = 0
        var sweepTo: Double? = nil
    }

    private func make(_ cue: Cue) -> AVAudioPCMBuffer? {
        switch cue {
        case .key:
            // 木の鍵盤：短いコツッ
            return synth(0.08, noise: 0.18, noiseDecay: 90, partials: [Partial(freq: 1900, amp: 0.25, decay: 70), Partial(freq: 620, amp: 0.3, decay: 55)])
        case .page:
            // 羊皮紙をめくる：さらっとした雑音
            return synth(0.28, noise: 0.35, noiseDecay: 14, partials: [Partial(freq: 300, amp: 0.05, decay: 20)])
        case .word:
            // 真鍮の鈴：2 音が上がる
            return synth(0.7, noise: 0, partials: [Partial(freq: 1318.5, amp: 0.35, decay: 6), Partial(freq: 2637, amp: 0.08, decay: 9), Partial(freq: 1760, amp: 0.35, decay: 5, delay: 0.1), Partial(freq: 3520, amp: 0.06, decay: 8, delay: 0.1)])
        case .item:
            // 道具：小さな鈴が 4 つ連なる
            let notes = [1568.0, 1975.5, 2349.3, 3136.0]
            return synth(0.9, noise: 0.03, noiseDecay: 12, partials: notes.enumerated().map { i, f in Partial(freq: f, amp: 0.28, decay: 7, delay: Double(i) * 0.07) })
        case .wrong:
            // 低い木の音が 2 回
            return synth(0.45, noise: 0.1, noiseDecay: 25, partials: [Partial(freq: 180, amp: 0.55, decay: 14, sweepTo: 140), Partial(freq: 160, amp: 0.45, decay: 14, delay: 0.14, sweepTo: 120)])
        case .unlock:
            // 錠が外れる：カチャリ
            return synth(0.4, noise: 0.3, noiseDecay: 45, partials: [Partial(freq: 2400, amp: 0.3, decay: 60), Partial(freq: 900, amp: 0.4, decay: 30, delay: 0.09), Partial(freq: 1400, amp: 0.25, decay: 40, delay: 0.16)])
        case .locked:
            // 開かない錠：にぶいガチッ
            return synth(0.25, noise: 0.25, noiseDecay: 40, partials: [Partial(freq: 520, amp: 0.4, decay: 35, sweepTo: 380)])
        case .door:
            // 重い扉がきしむ
            return synth(0.7, noise: 0.12, noiseDecay: 5, partials: [Partial(freq: 95, amp: 0.45, decay: 4, sweepTo: 70), Partial(freq: 420, amp: 0.08, decay: 3, sweepTo: 520)])
        case .hint:
            return synth(0.45, noise: 0, partials: [Partial(freq: 880, amp: 0.25, decay: 8), Partial(freq: 1318.5, amp: 0.22, decay: 8, delay: 0.09)])
        case .letter:
            // 文字盤がひとつ回る
            return synth(0.6, noise: 0.08, noiseDecay: 30, partials: [Partial(freq: 660, amp: 0.3, decay: 6), Partial(freq: 990, amp: 0.25, decay: 6, delay: 0.12)])
        case .escape:
            // 扉が開く：鐘と和音
            let notes = [392.0, 493.9, 587.3, 784.0]
            return synth(1.8, noise: 0.05, noiseDecay: 4, partials: notes.enumerated().flatMap { i, f in
                [Partial(freq: f, amp: 0.32, decay: 2.2, delay: Double(i) * 0.14), Partial(freq: f * 2.76, amp: 0.06, decay: 4, delay: Double(i) * 0.14)]
            })
        }
    }

    private func synth(_ seconds: Double, noise: Double, noiseDecay: Double = 60, partials: [Partial]) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let frames = AVAudioFrameCount(seconds * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames), let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        var rng = SeededRandom(seed: 42)
        var phases = Array(repeating: 0.0, count: partials.count)
        for i in 0..<Int(frames) {
            let t = Double(i) / rate
            var v = 0.0
            for (k, p) in partials.enumerated() where t >= p.delay {
                let local = t - p.delay
                var f = p.freq
                if let to = p.sweepTo { f = p.freq + (to - p.freq) * min(1, local / seconds) }
                phases[k] += 2 * .pi * f / rate
                // 立ち上がりを 3ms でならす（ぷつっと鳴らない）
                let attack = min(1, local / 0.003)
                v += sin(phases[k]) * p.amp * exp(-local * p.decay) * attack
            }
            if noise > 0 {
                let n = Double(rng.next() % 20_000) / 10_000 - 1
                v += n * noise * exp(-t * noiseDecay)
            }
            // 終わりを 10ms でならす
            let tail = min(1, (seconds - t) / 0.01)
            data[i] = Float(max(-1, min(1, v * tail)))
        }
        return buffer
    }
}
