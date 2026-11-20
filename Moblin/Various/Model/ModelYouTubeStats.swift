import Foundation

struct YouTubeVideoStats: Equatable {
    var liveViewers: Int?
    var views: Int?
    var likes: Int?
    var comments: Int?
    var isLive = false
}

@MainActor private var lastYouTubeStatsUpdate: ContinuousClock.Instant?

extension Model {
    func updateYouTubeStatsIfNeeded() {
        let interval: Duration = isLive ? .seconds(15) : .seconds(60)
        if let last = lastYouTubeStatsUpdate, last.duration(to: .now) < interval {
            return
        }
        lastYouTubeStatsUpdate = .now
        updateYouTubeStats()
    }

    func updateYouTubeStats() {
        guard let videoId = stream.getYouTubeVideoIds().last, isStreamConfigured() else {
            setYouTubeStats(nil)
            return
        }
        let authStream = stream.isYouTubeAuthorized() ? stream : youTubeAccount
        guard authStream.isYouTubeAuthorized() || isYouTubeAccountSignedIn() else {
            setYouTubeStats(nil)
            return
        }
        let streamId = stream.id
        getYouTubeApi(stream: authStream) { youTubeApi in
            youTubeApi?.listVideoStats(videoId: videoId) { response in
                guard self.stream.id == streamId, case let .success(response) = response,
                      let item = response.items.first
                else {
                    return
                }
                let details = item.liveStreamingDetails
                self.setYouTubeStats(YouTubeVideoStats(
                    liveViewers: details?.concurrentViewers.flatMap { Int($0) },
                    views: item.statistics?.viewCount.flatMap { Int($0) },
                    likes: item.statistics?.likeCount.flatMap { Int($0) },
                    comments: item.statistics?.commentCount.flatMap { Int($0) },
                    isLive: details?.isLive() ?? false
                ))
            }
        }
    }

    private func setYouTubeStats(_ stats: YouTubeVideoStats?) {
        if statusTopLeft.youTubeStats != stats {
            statusTopLeft.youTubeStats = stats
        }
    }
}
