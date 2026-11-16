import Foundation
@testable import Moblin
import Testing

@MainActor
struct YouTubeStreamPersistenceSuite {
    @Test
    func youTubeStreamSurvivesSaveAndReload() throws {
        let database = Database()
        let stream = SettingsStream(name: "Bhoomi live")
        stream.url = "\(youTubeRtmpsIngest)/abcd-efgh-ijkl-mnop-qrst"
        stream.youTubeVideoIds = "UVbP2jKDoF4"
        stream.youTubeHandle = "@bhoomicreatives"
        applyYouTubeDefaults(stream: stream, quality: .p1080fps30)
        database.streams.append(stream)
        let reloaded = try #require(try Database.fromString(settings: database.toString()).streams.first)
        #expect(reloaded.url == "rtmps://a.rtmps.youtube.com/live2/abcd-efgh-ijkl-mnop-qrst")
        #expect(reloaded.youTubeVideoIds == "UVbP2jKDoF4")
        #expect(reloaded.youTubeHandle == "@bhoomicreatives")
        #expect(reloaded.bitrate == 6_000_000)
        #expect(reloaded.codec == .h264avc)
        #expect(reloaded.maxKeyFrameInterval == 2)
    }
}
