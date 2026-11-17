import Foundation

extension Model {
    func goLive(stream: SettingsStream) {
        let broadcast = stream.youTubeBroadcast
        guard broadcast.enabled, broadcast.startNow, isYouTubeAccountSignedIn() else {
            goLiveNow(stream: stream)
            return
        }
        makeToast(title: String(localized: "Creating YouTube broadcast…"))
        createYouTubeBroadcast(stream: stream, details: broadcast, startNow: true) { error in
            if let error {
                self.makeErrorToast(title: error)
            }
            self.storeSettings()
            self.goLiveNow(stream: stream)
        }
    }

    private func goLiveNow(stream: SettingsStream) {
        guard stream.id != self.stream.id else {
            startStream()
            return
        }
        guard setCurrentStream(streamId: stream.id) else {
            makeErrorToast(title: String(localized: "Failed to switch stream"))
            return
        }
        reloadStream()
        sceneUpdated(attachCamera: true, updateRemoteScene: false)
        setIsLive(value: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.startStream(delayed: true)
        }
    }

    func deleteStream(_ stream: SettingsStream) {
        let wasCurrent = stream.enabled
        database.streams.removeAll { $0 === stream }
        if wasCurrent {
            setCurrentStream()
            reloadStream()
            sceneUpdated(attachCamera: true, updateRemoteScene: false)
        }
        storeSettings()
    }

    func goLiveStreams() -> [SettingsStream] {
        (isStreamConfigured() ? [stream] : []) + database.streams.filter { $0.id != stream.id }
    }
}
