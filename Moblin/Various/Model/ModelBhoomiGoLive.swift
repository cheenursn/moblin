import Foundation

extension Model {
    func goLive(stream: SettingsStream) {
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

    func goLiveStreams() -> [SettingsStream] {
        [stream] + database.streams.filter { $0.id != stream.id }
    }
}
