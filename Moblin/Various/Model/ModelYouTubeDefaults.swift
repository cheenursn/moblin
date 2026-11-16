import Foundation

let youTubeRtmpsIngest = "rtmps://a.rtmps.youtube.com/live2"
let youTubeStudioLiveUrl = "https://studio.youtube.com/channel/UC/livestreaming"

enum YouTubeQualityPreset: CaseIterable {
    case p1080fps30
    case p1080fps60
    case p720fps30

    func toString() -> String {
        switch self {
        case .p1080fps30:
            String(localized: "1080p 30 fps (recommended)")
        case .p1080fps60:
            String(localized: "1080p 60 fps")
        case .p720fps30:
            String(localized: "720p 30 fps (weak network)")
        }
    }

    var resolution: SettingsStreamResolution {
        switch self {
        case .p1080fps30, .p1080fps60:
            .r1920x1080
        case .p720fps30:
            .r1280x720
        }
    }

    var fps: Int {
        switch self {
        case .p1080fps30, .p720fps30:
            30
        case .p1080fps60:
            60
        }
    }

    var bitrate: UInt32 {
        switch self {
        case .p1080fps30:
            6_000_000
        case .p1080fps60:
            9_000_000
        case .p720fps30:
            3_000_000
        }
    }
}

func applyYouTubeDefaults(stream: SettingsStream, quality: YouTubeQualityPreset) {
    stream.resolution = quality.resolution
    stream.fps = quality.fps
    stream.bitrate = quality.bitrate
    stream.codec = .h264avc
    stream.rateControl = .cbr
    stream.maxKeyFrameInterval = 2
    stream.audioCodec = .aac
    stream.audioBitrate = 128_000
    stream.adaptiveBitrate = true
    stream.rtmp.adaptiveBitrateEnabled = true
}
