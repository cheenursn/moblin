import SwiftUI

struct StreamWizardYouTubeSettingsView: View {
    let model: Model
    @ObservedObject var createStreamWizard: CreateStreamWizard
    @ObservedObject var youTubeStream: SettingsStream

    private func fetchLiveStreams() {
        model.getYouTubeApi(stream: youTubeStream) { youTubeApi in
            youTubeApi?.listLiveStreams {
                switch $0 {
                case let .success(response):
                    if let liveStream = response.items.first {
                        let ingestionInfo = liveStream.cdn.ingestionInfo
                        createStreamWizard.directIngest = ingestionInfo.ingestionAddress
                        createStreamWizard.directStreamKey = ingestionInfo.streamName
                    }
                case .authError, .error:
                    break
                }
            }
        }
    }

    private func fetchChannelHandle() {
        model.getYouTubeApi(stream: youTubeStream) { youTubeApi in
            youTubeApi?.listChannels {
                switch $0 {
                case let .success(response):
                    if let handle = response.items.first?.snippet.customUrl {
                        createStreamWizard.youTubeHandle = handle
                    }
                case .authError, .error:
                    break
                }
            }
        }
    }

    private func canCreate() -> Bool {
        !createStreamWizard.name.trim().isEmpty && !createStreamWizard.directStreamKey.trim().isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $createStreamWizard.name)
                    .disableAutocorrection(true)
            } header: {
                Text("Stream name")
            } footer: {
                Text("For example the show or topic, so you can pick it quickly when going live.")
            }
            Section {
                TextField(String("xxxx-xxxx-xxxx-xxxx-xxxx"), text: $createStreamWizard.directStreamKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            } header: {
                Text("Stream key")
            } footer: {
                VStack(alignment: .leading) {
                    Text("Copy it from YouTube Studio → Go live → Stream:")
                    Link(youTubeStudioLiveUrl, destination: URL(string: youTubeStudioLiveUrl)!)
                        .font(.footnote)
                }
            }
            Section {
                Picker("Quality", selection: $createStreamWizard.youTubeQuality) {
                    ForEach(YouTubeQualityPreset.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
            } footer: {
                Text("H.264 over encrypted RTMPS with a 2 second keyframe interval, as YouTube recommends.")
            }
            Section {
                if !youTubeStream.isYouTubeAuthorized() {
                    TextButtonView("Fill in with Google login") {
                        model.youTubeSignIn(stream: youTubeStream)
                    }
                } else {
                    TextButtonView("Logout") {
                        model.youTubeSignOut(stream: youTubeStream)
                    }
                }
            } footer: {
                Text("Optional. Fills in the stream key and enables chat.")
            }
            Section {
                TextButtonView("Create") {
                    model.createStreamFromWizard()
                    createStreamWizard.presenting = false
                    createStreamWizard.presentingSetup = false
                }
                .disabled(!canCreate())
            }
        }
        .onAppear {
            createStreamWizard.platform = .youTube
            createStreamWizard.networkSetup = .direct
            if createStreamWizard.name.isEmpty {
                createStreamWizard.name = makeUniqueName(name: String(localized: "YouTube"),
                                                         existingNames: model.database.streams)
            }
            if createStreamWizard.directIngest.isEmpty {
                createStreamWizard.directIngest = youTubeRtmpsIngest
            }
            youTubeStream.youTubeAuthState = nil
        }
        .onChange(of: youTubeStream.youTubeAuthState) { authState in
            if authState != nil {
                fetchLiveStreams()
                fetchChannelHandle()
            }
        }
        .navigationTitle("YouTube")
        .toolbar {
            CreateStreamWizardToolbar(createStreamWizard: createStreamWizard)
        }
    }
}
