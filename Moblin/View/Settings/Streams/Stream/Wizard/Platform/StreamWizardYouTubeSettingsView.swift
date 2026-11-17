import SwiftUI

struct StreamWizardYouTubeSettingsView: View {
    let model: Model
    @ObservedObject var createStreamWizard: CreateStreamWizard
    @ObservedObject var youTubeStream: SettingsStream
    @ObservedObject var database: Database
    @State private var useOtherKey = false
    @StateObject private var broadcast = YouTubeBroadcastDetails()
    @State private var creating = false
    @State private var broadcastError: String?

    init(model: Model, createStreamWizard: CreateStreamWizard, youTubeStream: SettingsStream) {
        self.model = model
        self.createStreamWizard = createStreamWizard
        self.youTubeStream = youTubeStream
        database = model.database
    }

    private func accountKey() -> String {
        database.youTubeAccountStreamKey
    }

    private func canCreate() -> Bool {
        !createStreamWizard.name.trim().isEmpty && !createStreamWizard.directStreamKey.trim().isEmpty
    }

    private func create() {
        createStreamWizard.directIngest = youTubeRtmpsIngest
        if model.isYouTubeAccountSignedIn() {
            youTubeStream.youTubeAuthState = model.youTubeAccount.youTubeAuthState
            youTubeStream.youTubeWantsToBeLoggedIn = true
            createStreamWizard.youTubeHandle = database.youTubeAccountHandle
        } else {
            youTubeStream.youTubeAuthState = nil
        }
        model.createStreamFromWizard()
        guard let stream = model.database.streams.last else {
            close()
            return
        }
        if broadcast.title.trim().isEmpty {
            broadcast.title = stream.name
        }
        stream.youTubeBroadcast = broadcast
        model.storeSettings()
        guard broadcast.enabled, !broadcast.startNow else {
            close()
            return
        }
        creating = true
        model.createYouTubeBroadcast(stream: stream, details: broadcast) { error in
            creating = false
            model.storeSettings()
            if let error {
                broadcastError = String(localized: "Stream saved. ") + error
            } else {
                close()
            }
        }
    }

    private func close() {
        createStreamWizard.presenting = false
        createStreamWizard.presentingSetup = false
        createStreamWizard.presentingYouTube = false
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
                Picker("Quality", selection: $createStreamWizard.youTubeQuality) {
                    ForEach(YouTubeQualityPreset.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
            } footer: {
                Text("H.264 over encrypted RTMPS with a 2 second keyframe interval, as YouTube recommends.")
            }
            Section {
                if !accountKey().isEmpty, !useOtherKey {
                    HStack {
                        Text("Stream key")
                        Spacer()
                        Text(maskedStreamKey(accountKey()))
                            .foregroundStyle(.secondary)
                    }
                    Button("Use a different key") {
                        useOtherKey = true
                        createStreamWizard.directStreamKey = ""
                    }
                } else {
                    TextField(String("xxxx-xxxx-xxxx-xxxx-xxxx"), text: $createStreamWizard.directStreamKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            } header: {
                Text("Stream key")
            } footer: {
                if !accountKey().isEmpty, !useOtherKey {
                    Text("From your YouTube account.")
                } else {
                    VStack(alignment: .leading) {
                        Text("Sign in under YouTube account to fill this in, or copy it from YouTube Studio:")
                        Link(youTubeStudioLiveUrl, destination: URL(string: youTubeStudioLiveUrl)!)
                            .font(.footnote)
                    }
                }
            }
            YouTubeBroadcastFieldsView(details: broadcast,
                                       signedIn: model.isYouTubeAccountSignedIn())
            Section {
                if creating {
                    HCenter {
                        ProgressView()
                    }
                } else if broadcastError != nil {
                    TextButtonView("Done") {
                        close()
                    }
                } else {
                    TextButtonView("Create") {
                        create()
                    }
                    .disabled(!canCreate())
                }
            } footer: {
                if let broadcastError {
                    Text(broadcastError)
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            createStreamWizard.platform = .youTube
            createStreamWizard.networkSetup = .direct
            createStreamWizard.directIngest = youTubeRtmpsIngest
            if createStreamWizard.name.isEmpty {
                createStreamWizard.name = makeUniqueName(name: String(localized: "YouTube"),
                                                         existingNames: model.database.streams)
            }
            if createStreamWizard.directStreamKey.isEmpty {
                createStreamWizard.directStreamKey = accountKey()
            }
        }
        .navigationTitle("Add YouTube stream")
        .toolbar {
            CreateStreamWizardToolbar(createStreamWizard: createStreamWizard)
        }
    }
}

func maskedStreamKey(_ key: String) -> String {
    guard key.count > 4 else {
        return key
    }
    return "••••" + key.suffix(4)
}
