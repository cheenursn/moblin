import UIKit

enum YouTubeBroadcastLatency: String, Codable, CaseIterable {
    case normal
    case low
    case ultraLow

    func toString() -> String {
        switch self {
        case .normal:
            String(localized: "Normal (best quality)")
        case .low:
            String(localized: "Low")
        case .ultraLow:
            String(localized: "Ultra low (no 1440p/4K)")
        }
    }
}

enum YouTubeBroadcastCategory: String, Codable, CaseIterable {
    case filmAndAnimation = "1"
    case music = "10"
    case travelAndEvents = "19"
    case gaming = "20"
    case peopleAndBlogs = "22"
    case comedy = "23"
    case entertainment = "24"
    case newsAndPolitics = "25"
    case howtoAndStyle = "26"
    case education = "27"
    case scienceAndTechnology = "28"

    func toString() -> String {
        switch self {
        case .filmAndAnimation:
            String(localized: "Film & Animation")
        case .music:
            String(localized: "Music")
        case .travelAndEvents:
            String(localized: "Travel & Events")
        case .gaming:
            String(localized: "Gaming")
        case .peopleAndBlogs:
            String(localized: "People & Blogs")
        case .comedy:
            String(localized: "Comedy")
        case .entertainment:
            String(localized: "Entertainment")
        case .newsAndPolitics:
            String(localized: "News & Politics")
        case .howtoAndStyle:
            String(localized: "Howto & Style")
        case .education:
            String(localized: "Education")
        case .scienceAndTechnology:
            String(localized: "Science & Technology")
        }
    }
}

private func youTubeThumbnailsDirectory() -> URL {
    let url = URL.documentsDirectory.appending(path: "YouTubeThumbnails")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

final class YouTubeBroadcastDetails: Codable, ObservableObject {
    @Published var enabled = false
    @Published var title = ""
    @Published var description = ""
    @Published var startNow = true
    @Published var startTime = Date().addingTimeInterval(3600)
    @Published var visibility: YouTubeApiLiveBroadcaseVisibility = .public
    @Published var category: YouTubeBroadcastCategory = .peopleAndBlogs
    @Published var tags = ""
    @Published var madeForKids = false
    @Published var autoStart = true
    @Published var autoStop = true
    @Published var dvr = true
    @Published var latency: YouTubeBroadcastLatency = .normal
    @Published var thumbnail: UIImage?
    var thumbnailFile = ""

    init() {}

    enum CodingKeys: CodingKey {
        case enabled
        case title
        case description
        case visibility
        case category
        case tags
        case madeForKids
        case autoStart
        case autoStop
        case dvr
        case latency
        case thumbnailFile
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(.enabled, enabled)
        try container.encode(.title, title)
        try container.encode(.description, description)
        try container.encode(.visibility, visibility)
        try container.encode(.category, category)
        try container.encode(.tags, tags)
        try container.encode(.madeForKids, madeForKids)
        try container.encode(.autoStart, autoStart)
        try container.encode(.autoStop, autoStop)
        try container.encode(.dvr, dvr)
        try container.encode(.latency, latency)
        try container.encode(.thumbnailFile, thumbnailFile)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = container.decode(.enabled, Bool.self, false)
        title = container.decode(.title, String.self, "")
        description = container.decode(.description, String.self, "")
        visibility = container.decode(.visibility, YouTubeApiLiveBroadcaseVisibility.self, .public)
        category = container.decode(.category, YouTubeBroadcastCategory.self, .peopleAndBlogs)
        tags = container.decode(.tags, String.self, "")
        madeForKids = container.decode(.madeForKids, Bool.self, false)
        autoStart = container.decode(.autoStart, Bool.self, true)
        autoStop = container.decode(.autoStop, Bool.self, true)
        dvr = container.decode(.dvr, Bool.self, true)
        latency = container.decode(.latency, YouTubeBroadcastLatency.self, .normal)
        thumbnailFile = container.decode(.thumbnailFile, String.self, "")
        if !thumbnailFile.isEmpty {
            thumbnail = UIImage(contentsOfFile: youTubeThumbnailsDirectory().appending(path: thumbnailFile).path)
        }
    }

    func clone() -> YouTubeBroadcastDetails {
        let new = YouTubeBroadcastDetails()
        new.enabled = enabled
        new.title = title
        new.description = description
        new.visibility = visibility
        new.category = category
        new.tags = tags
        new.madeForKids = madeForKids
        new.autoStart = autoStart
        new.autoStop = autoStop
        new.dvr = dvr
        new.latency = latency
        new.setThumbnail(thumbnail)
        return new
    }

    func setThumbnail(_ image: UIImage?) {
        if !thumbnailFile.isEmpty {
            try? FileManager.default.removeItem(at: youTubeThumbnailsDirectory().appending(path: thumbnailFile))
            thumbnailFile = ""
        }
        thumbnail = image
        guard let image, let data = image.jpegData(compressionQuality: 0.9) else {
            return
        }
        let name = "\(UUID().uuidString).jpg"
        if (try? data.write(to: youTubeThumbnailsDirectory().appending(path: name))) != nil {
            thumbnailFile = name
        }
    }

    func tagList() -> [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

extension Model {
    func createYouTubeBroadcast(stream: SettingsStream,
                                details: YouTubeBroadcastDetails,
                                startNow: Bool? = nil,
                                onCompleted: @escaping (String?) -> Void)
    {
        getYouTubeApi(stream: youTubeAccount) { youTubeApi in
            guard let youTubeApi else {
                onCompleted(String(localized: "Sign in under YouTube account first."))
                return
            }
            youTubeApi.listLiveStreams { response in
                guard case let .success(liveStreams) = response else {
                    onCompleted(String(localized: "Couldn't read your YouTube stream keys."))
                    return
                }
                let key = stream.url.split(separator: "/").last.map(String.init) ?? ""
                guard let liveStream = liveStreams.items.first(where: { $0.cdn.ingestionInfo.streamName == key })
                    ?? liveStreams.items.first
                else {
                    onCompleted(String(localized: "No stream key found on your channel."))
                    return
                }
                youTubeApi.insertLiveBroadcast(details: details, startNow: startNow ?? details.startNow) { response in
                    guard case let .success(broadcast) = response else {
                        onCompleted(String(localized: "YouTube refused to create the broadcast."))
                        return
                    }
                    youTubeApi.bindLiveBroadcast(boardcastId: broadcast.id, streamId: liveStream.id) { bound in
                        guard bound else {
                            onCompleted(String(localized: "Broadcast created but couldn't be linked to the key."))
                            return
                        }
                        stream.youTubeVideoIds = broadcast.id
                        stream.youTubeAuthState = self.youTubeAccount.youTubeAuthState
                        stream.youTubeWantsToBeLoggedIn = true
                        self.youTubeVideoIdUpdated()
                        self.finishYouTubeBroadcast(youTubeApi: youTubeApi,
                                                    videoId: broadcast.id,
                                                    details: details,
                                                    onCompleted: onCompleted)
                    }
                }
            }
        }
    }

    private func finishYouTubeBroadcast(youTubeApi: YouTubeApi,
                                        videoId: String,
                                        details: YouTubeBroadcastDetails,
                                        onCompleted: @escaping (String?) -> Void)
    {
        youTubeApi.updateVideoCategoryAndTags(videoId: videoId,
                                              title: details.title.isEmpty ? "Live" : details.title,
                                              description: details.description,
                                              categoryId: details.category.rawValue,
                                              tags: details.tagList())
        { categoryOk in
            guard let jpeg = details.thumbnail.flatMap(youTubeThumbnailJpeg) else {
                onCompleted(categoryOk ? nil : String(localized: "Broadcast created, but category and tags failed."))
                return
            }
            youTubeApi.setThumbnail(videoId: videoId, jpeg: jpeg) { thumbnailOk in
                if !thumbnailOk {
                    onCompleted(String(localized: """
                    Broadcast created, but the thumbnail was refused. Custom thumbnails need a verified \
                    YouTube account.
                    """))
                } else if !categoryOk {
                    onCompleted(String(localized: "Broadcast created, but category and tags failed."))
                } else {
                    onCompleted(nil)
                }
            }
        }
    }
}

private func youTubeThumbnailJpeg(_ image: UIImage) -> Data? {
    let target = CGSize(width: 1280, height: 720)
    let scale = max(target.width / image.size.width, target.height / image.size.height)
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
        image.draw(in: CGRect(x: (target.width - size.width) / 2,
                              y: (target.height - size.height) / 2,
                              width: size.width,
                              height: size.height))
    }
    var quality = 0.9
    while quality > 0.3 {
        if let data = resized.jpegData(compressionQuality: quality), data.count < 2_000_000 {
            return data
        }
        quality -= 0.1
    }
    return resized.jpegData(compressionQuality: 0.3)
}
