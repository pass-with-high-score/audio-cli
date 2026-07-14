import AVFoundation
import Foundation

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {

    // MARK: Published State

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var volume: Float = 1.0

    // MARK: Callback

    /// Called on the main actor when the current track finishes playing naturally.
    var onTrackFinished: (() -> Void)?

    // MARK: Private

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - Playback Controls

    /// Loads and plays an audio file from the given local URL.
    func play(fileURL: URL) {
        stopProgressTimer()

        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.delegate = self
            player.volume = volume
            player.prepareToPlay()
            player.play()

            audioPlayer = player
            duration = player.duration
            currentTime = 0.0
            isPlaying = true

            startProgressTimer()
        } catch {
            isPlaying = false
            duration = 0.0
            currentTime = 0.0
            print("[AudioPlayerService] Failed to play file: \(error.localizedDescription)")
        }
    }

    /// Pauses the currently playing audio.
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    /// Resumes playback from the current position.
    func resume() {
        guard let player = audioPlayer else { return }
        player.play()
        isPlaying = true
        startProgressTimer()
    }

    /// Toggles between play and pause states.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    /// Seeks to the specified time in seconds.
    func seek(to seconds: Double) {
        guard let player = audioPlayer else { return }
        let clamped = max(0, min(seconds, player.duration))
        player.currentTime = clamped
        currentTime = clamped
    }

    /// Sets the playback volume (0.0 to 1.0).
    func setVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        volume = clamped
        audioPlayer?.volume = clamped
    }

    /// Stops playback and releases resources.
    func stop() {
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
            self.onTrackFinished?()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
            if let error {
                print("[AudioPlayerService] Decode error: \(error.localizedDescription)")
            }
        }
    }
}
