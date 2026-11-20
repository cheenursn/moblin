import Foundation

extension Model {
    func updateYouTubeVideoTitle() {
        updateYouTubeStats()
        let videoIds = stream.youTubeVideoIds.trim()
        let authStream = stream.isYouTubeAuthorized() ? stream : youTubeAccount
        guard isStreamConfigured(), authStream.isYouTubeAuthorized() || isYouTubeAccountSignedIn(),
              !videoIds.isEmpty
        else {
            setYouTubeVideoTitle(nil)
            return
        }
        let streamId = stream.id
        getYouTubeApi(stream: authStream) { youTubeApi in
            youTubeApi?.listVideoTitles(videoIds: videoIds) { response in
                guard self.stream.id == streamId, case let .success(response) = response else {
                    return
                }
                self.setYouTubeVideoTitle(response.items.first?.snippet.title)
            }
        }
    }

    private func setYouTubeVideoTitle(_ title: String?) {
        let title = title?.trim().isEmpty == false ? title : nil
        if statusTopLeft.youTubeVideoTitle != title {
            statusTopLeft.youTubeVideoTitle = title
        }
    }
}
