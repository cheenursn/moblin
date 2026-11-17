import Foundation

private let youTubeAccountId = UUID(uuidString: "B400D1E0-0000-4000-8000-000000000001")!

func makeYouTubeAccountStream() -> SettingsStream {
    let stream = SettingsStream(name: "YouTube account")
    stream.id = youTubeAccountId
    return stream
}

extension Model {
    func isYouTubeAccountSignedIn() -> Bool {
        youTubeAccount.isYouTubeAuthorized()
    }

    func youTubeAccountSignIn() {
        youTubeSignIn(stream: youTubeAccount)
    }

    func youTubeAccountSignedIn() {
        youTubeAccount.storeToKeychain()
    }

    func fetchYouTubeAccountDetails(onCompleted: ((Bool) -> Void)? = nil) {
        getYouTubeApi(stream: youTubeAccount) { youTubeApi in
            guard let youTubeApi else {
                onCompleted?(false)
                return
            }
            youTubeApi.listLiveStreams {
                switch $0 {
                case let .success(response):
                    if let streamName = response.items.first?.cdn.ingestionInfo.streamName {
                        self.database.youTubeAccountStreamKey = streamName
                        self.storeSettings()
                        onCompleted?(true)
                    } else {
                        onCompleted?(false)
                    }
                case .authError, .error:
                    onCompleted?(false)
                }
            }
            youTubeApi.listChannels {
                if case let .success(response) = $0, let handle = response.items.first?.snippet.customUrl {
                    self.database.youTubeAccountHandle = handle
                    self.storeSettings()
                }
            }
        }
    }

    func youTubeAccountSignOut() {
        youTubeSignOut(stream: youTubeAccount)
        database.youTubeAccountStreamKey = ""
        database.youTubeAccountHandle = ""
        storeSettings()
    }
}
