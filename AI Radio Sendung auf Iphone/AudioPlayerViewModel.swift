import AVFoundation
import Combine
import Foundation
import MediaPlayer

struct AudioTrack: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let fileName: String
    let url: URL
    let listedDuration: TimeInterval?
}

@MainActor
final class AudioPlayerViewModel: NSObject, ObservableObject {
    @Published private(set) var shows: [ShowItem]
    @Published private(set) var selectedIndex: Int
    @Published private(set) var isPlaying = false
    @Published private(set) var trackTitle = ""
    @Published private(set) var statusMessage: String?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var playlist: [AudioTrack] = []
    private var trackDurations: [TimeInterval] = []
    private var currentTrackIndex = 0
    private let fileManager = FileManager.default
    private var nowPlayingArtworkCache: [String: MPMediaItemArtwork] = [:]
    private static let selectedShowIDKey = "selectedShowID"
    private static let selectedShowIndexKey = "selectedShowIndex"

    var selectedShow: ShowItem {
        shows[wrapped(selectedIndex, count: shows.count)]
    }

    override init() {
        self.shows = ShowItem.examples
        self.selectedIndex = Self.restoredSelectedIndex(in: ShowItem.examples)
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        loadSelectedShow(autoplay: false)
    }

    init(shows: [ShowItem]) {
        self.shows = shows
        self.selectedIndex = Self.restoredSelectedIndex(in: shows)
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        loadSelectedShow(autoplay: false)
    }

    func selectShow(_ index: Int, autoplay: Bool? = nil) {
        guard !shows.isEmpty else { return }
        let nextIndex = wrapped(index, count: shows.count)
        let shouldAutoplay = autoplay ?? isPlaying

        guard nextIndex != selectedIndex else {
            if shouldAutoplay && !isPlaying {
                play()
            }
            return
        }

        selectedIndex = nextIndex
        persistSelectedShow()
        loadSelectedShow(autoplay: shouldAutoplay)
    }

    func selectNextShow(autoplay: Bool? = nil) {
        selectShow(selectedIndex + 1, autoplay: autoplay)
    }

    func selectPreviousShow(autoplay: Bool? = nil) {
        selectShow(selectedIndex - 1, autoplay: autoplay)
    }

    func selectNextTrack() {
        selectTrack(currentTrackIndex + 1, autoplay: isPlaying)
    }

    func selectPreviousTrack() {
        selectTrack(currentTrackIndex - 1, autoplay: isPlaying)
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        if playlist.isEmpty {
            loadSelectedShow(autoplay: false)
            guard !playlist.isEmpty else { return }
        }

        if audioPlayer == nil, !loadTrack(at: currentTrackIndex) {
            return
        }

        audioPlayer?.play()
        isPlaying = true
        updateProgress()
        updateNowPlayingInfo()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        updateProgress()
        updateNowPlayingInfo()
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTrackIndex = 0
        _ = loadTrack(at: currentTrackIndex)
        currentTime = 0
        updateNowPlayingInfo()
    }

    func skip(seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func seek(to newTime: TimeInterval) {
        guard !playlist.isEmpty else { return }

        let clampedTime = max(0, min(newTime, max(duration, 0)))
        let wasPlaying = isPlaying
        let targetIndex = trackIndex(for: clampedTime)
        let targetOffset = accumulatedDuration(before: targetIndex)

        if targetIndex != currentTrackIndex || audioPlayer == nil {
            currentTrackIndex = targetIndex
            _ = loadTrack(at: currentTrackIndex)
        }

        audioPlayer?.currentTime = max(0, clampedTime - targetOffset)
        currentTime = clampedTime

        if wasPlaying {
            audioPlayer?.play()
            isPlaying = true
        }

        updateNowPlayingInfo()
    }

    func updateProgress() {
        guard let audioPlayer else { return }

        let offset = accumulatedDuration(before: currentTrackIndex)
        currentTime = min(offset + audioPlayer.currentTime, max(duration, offset + audioPlayer.duration))
        duration = max(duration, offset + audioPlayer.duration)
        updateNowPlayingInfo()
    }

    static func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let seconds = Int(time.rounded())
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    func persistCurrentState() {
        persistSelectedShow()
    }

    private static func restoredSelectedIndex(in shows: [ShowItem]) -> Int {
        if let savedID = UserDefaults.standard.string(forKey: selectedShowIDKey),
           let savedIndex = shows.firstIndex(where: { $0.id == savedID }) {
            return savedIndex
        }

        let savedIndex = UserDefaults.standard.integer(forKey: selectedShowIndexKey)
        guard shows.indices.contains(savedIndex) else { return 0 }
        return savedIndex
    }

    private func persistSelectedShow() {
        UserDefaults.standard.set(selectedShow.id, forKey: Self.selectedShowIDKey)
        UserDefaults.standard.set(selectedIndex, forKey: Self.selectedShowIndexKey)
        UserDefaults.standard.synchronize()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            statusMessage = "Audio konnte nicht vorbereitet werden."
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.play()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pause()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.togglePlayPause()
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.selectPreviousTrack()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.selectNextTrack()
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.skip(seconds: -15)
            }
            return .success
        }

        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.skip(seconds: 30)
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task { @MainActor [weak self] in
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    private func loadSelectedShow(autoplay: Bool) {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentTrackIndex = 0

        playlist = loadPlaylist(for: selectedShow)
        trackDurations = playlist.map { max($0.listedDuration ?? 0, 0) }
        duration = trackDurations.reduce(0, +)

        guard !playlist.isEmpty else {
            trackTitle = ""
            statusMessage = "Keine lokale Audiodatei fuer diese Show gefunden."
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        _ = loadTrack(at: 0)

        if autoplay {
            play()
        }
    }

    private func loadTrack(at index: Int) -> Bool {
        guard playlist.indices.contains(index) else { return false }

        let track = playlist[index]

        do {
            let player = try AVAudioPlayer(contentsOf: track.url)
            player.delegate = self
            player.prepareToPlay()
            audioPlayer = player

            if player.duration.isFinite && player.duration > 0 {
                trackDurations[index] = player.duration
                duration = max(trackDurations.reduce(0, +), player.duration)
            }

            trackTitle = track.title
            statusMessage = nil
            updateNowPlayingInfo()
            return true
        } catch {
            audioPlayer = nil
            trackTitle = track.title
            statusMessage = "Diese Audiodatei kann nicht abgespielt werden."
            updateNowPlayingInfo()
            return false
        }
    }

    private func selectTrack(_ index: Int, autoplay: Bool) {
        if playlist.isEmpty {
            loadSelectedShow(autoplay: autoplay)
            return
        }

        currentTrackIndex = wrapped(index, count: playlist.count)
        currentTime = accumulatedDuration(before: currentTrackIndex)

        guard loadTrack(at: currentTrackIndex) else {
            isPlaying = false
            return
        }

        audioPlayer?.currentTime = 0

        if autoplay {
            play()
        } else {
            isPlaying = false
            updateNowPlayingInfo()
        }
    }

    private func loadPlaylist(for show: ShowItem) -> [AudioTrack] {
        guard let showURL = showFolderURL(for: show) else { return [] }

        let playlistURL = showURL.appendingPathComponent(show.playlistFileName)

        if fileManager.fileExists(atPath: playlistURL.path),
           let playlistContent = try? String(contentsOf: playlistURL, encoding: .utf8) {
            let parsedTracks = parseM3U(content: playlistContent, folderURL: showURL)
            if !parsedTracks.isEmpty {
                return parsedTracks
            }
        }

        if let audioFileName = show.audioFileName {
            let audioURL = showURL.appendingPathComponent(audioFileName)
            if fileManager.fileExists(atPath: audioURL.path) {
                return [
                    AudioTrack(
                        title: audioURL.deletingPathExtension().lastPathComponent,
                        fileName: audioFileName,
                        url: audioURL,
                        listedDuration: show.durationHint
                    )
                ]
            }
        }

        return localAudioFiles(in: showURL)
    }

    private func showFolderURL(for show: ShowItem) -> URL? {
        let documentsRoot = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("10_AI_Radio_Exports")
            .appendingPathComponent(show.folderName)

        if let documentsRoot, fileManager.fileExists(atPath: documentsRoot.path) {
            return documentsRoot
        }

        let bundledRoot = Bundle.main.resourceURL?
            .appendingPathComponent("10_AI_Radio_Exports")
            .appendingPathComponent(show.folderName)

        if let bundledRoot, fileManager.fileExists(atPath: bundledRoot.path) {
            return bundledRoot
        }

        return documentsRoot
    }

    private func parseM3U(content: String, folderURL: URL) -> [AudioTrack] {
        var tracks: [AudioTrack] = []
        var pendingTitle: String?
        var pendingDuration: TimeInterval?

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("#EXTINF:") {
                let info = String(line.dropFirst("#EXTINF:".count))
                let parts = info.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                pendingDuration = TimeInterval(parts.first ?? "0")
                pendingTitle = parts.count > 1 ? String(parts[1]) : nil
                continue
            }

            if line.hasPrefix("#") {
                continue
            }

            let audioURL = folderURL.appendingPathComponent(line)
            guard fileManager.fileExists(atPath: audioURL.path) else {
                pendingTitle = nil
                pendingDuration = nil
                continue
            }

            tracks.append(
                AudioTrack(
                    title: pendingTitle?.isEmpty == false ? pendingTitle! : audioURL.deletingPathExtension().lastPathComponent,
                    fileName: line,
                    url: audioURL,
                    listedDuration: pendingDuration
                )
            )

            pendingTitle = nil
            pendingDuration = nil
        }

        return tracks
    }

    private func localAudioFiles(in folderURL: URL) -> [AudioTrack] {
        let supportedExtensions = Set(["mp3", "m4a", "wav", "aac", "flac"])

        guard let files = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return files
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map {
                AudioTrack(
                    title: $0.deletingPathExtension().lastPathComponent,
                    fileName: $0.lastPathComponent,
                    url: $0,
                    listedDuration: nil
                )
            }
    }

    private func handleTrackEnded() {
        if currentTrackIndex + 1 < playlist.count {
            currentTrackIndex += 1
            if loadTrack(at: currentTrackIndex) {
                play()
            }
        } else {
            isPlaying = false
            currentTime = duration
            updateNowPlayingInfo()
        }
    }

    private func updateNowPlayingInfo() {
        guard !playlist.isEmpty else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: selectedShow.title,
            MPMediaItemPropertyArtist: trackTitle.isEmpty ? selectedShow.subtitle : trackTitle,
            MPMediaItemPropertyAlbumTitle: "AI Radio",
            MPMediaItemPropertyPlaybackDuration: max(duration, 0),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(currentTime, 0),
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        if let artwork = artwork(for: selectedShow) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func artwork(for show: ShowItem) -> MPMediaItemArtwork? {
        if let cachedArtwork = nowPlayingArtworkCache[show.coverImageName] {
            return cachedArtwork
        }

        guard let image = UIImage(named: show.coverImageName) else {
            return nil
        }

        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        nowPlayingArtworkCache[show.coverImageName] = artwork
        return artwork
    }

    private func trackIndex(for time: TimeInterval) -> Int {
        guard !trackDurations.isEmpty else { return 0 }

        var cursor: TimeInterval = 0

        for index in trackDurations.indices {
            let segmentDuration = max(trackDurations[index], 0.01)
            if time <= cursor + segmentDuration {
                return index
            }
            cursor += segmentDuration
        }

        return max(trackDurations.count - 1, 0)
    }

    private func accumulatedDuration(before index: Int) -> TimeInterval {
        guard index > 0 else { return 0 }
        return trackDurations.prefix(index).reduce(0, +)
    }

    private func wrapped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (index % count + count) % count
    }
}

extension AudioPlayerViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.handleTrackEnded()
        }
    }
}
