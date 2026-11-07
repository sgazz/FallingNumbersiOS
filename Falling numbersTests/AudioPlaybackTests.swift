import AVFoundation
import Foundation
import Testing
@testable import Falling_numbers

@MainActor
struct AudioPlaybackTests {
    @Test(arguments: [190.0, 220, 280, 430, 460, 500, 540, 620, 700, 780, 860, 920])
    func generatedTonesDecodeAsValidPCM(frequency: Double) throws {
        let data = try #require(TonePlayer.makeToneData(frequency: frequency, duration: 0.12))
        #expect(String(data: data.prefix(4), encoding: .ascii) == "RIFF")
        #expect(String(data: data[8..<12], encoding: .ascii) == "WAVE")
        let decoder = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
        #expect(decoder.numberOfChannels == 1)
        #expect(abs(decoder.duration - 0.12) < 0.001)
        #expect(decoder.format.sampleRate == 44100)
        #expect(data.dropFirst(44).contains { $0 != 0 })
    }

    @Test
    func realPlayerStartsAdvancesAndStops() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        let tone = TonePlayer(frequency: 620, duration: 0.5, volume: 0.25)
        defer { tone.stop() }
        #expect(tone.play())
        #expect(tone.isPlaying)
        try await Task.sleep(for: .milliseconds(120))
        #expect(tone.currentTime > 0)
        tone.stop()
        #expect(!tone.isPlaying)
        #expect(tone.currentTime == 0)
        #expect(tone.play())
    }

    @Test
    func actualAudioClientSubmitsGameplayEffects() async {
        let audio = UIKitAudioClient()
        for event in [SoundEvent.move, .lock, .clear, .hardDrop, .perfectClear, .rowClear, .columnClear, .reorder, .gameOver] {
            let started = await withCheckedContinuation { continuation in
                audio.trigger(event) { continuation.resume(returning: $0) }
            }
            #expect(started)
            audio.stop()
        }
        #expect(AVAudioSession.sharedInstance().category == .playback)
        #expect(AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers))
    }

    @Test
    func soundPreviewRespectsMuteAndPlaysOnEnable() {
        let audio = RecordingAudioClient()
        let vm = GameScreenViewModel(settingsStore: TestSettingsStore(initial: .default),
                                     haptics: NoopHapticsClient(), audio: audio)
        vm.testSound()
        #expect(audio.events == [.clear])
        vm.setSoundEnabled(false)
        vm.testSound()
        #expect(audio.events == [.clear])
        #expect(audio.stopCount == 1)
        vm.setSoundEnabled(true)
        #expect(audio.events == [.clear, .clear])
    }
}
