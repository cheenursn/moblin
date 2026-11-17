import SwiftUI

private func youTubeStreamKey(_ stream: SettingsStream) -> String {
    guard let slash = stream.url.lastIndex(of: "/") else {
        return ""
    }
    return String(stream.url[stream.url.index(after: slash)...])
}

private func youTubeIngest(_ stream: SettingsStream) -> String {
    guard let slash = stream.url.lastIndex(of: "/") else {
        return youTubeRtmpsIngest
    }
    return String(stream.url[..<slash])
}

private func youTubeQuality(_ stream: SettingsStream) -> YouTubeQualityPreset? {
    YouTubeQualityPreset.allCases.first {
        $0.resolution == stream.resolution && $0.fps == stream.fps
    }
}

private func qualityText(_ stream: SettingsStream) -> String {
    if let quality = youTubeQuality(stream) {
        return quality.toString()
    }
    return "\(stream.resolution.shortString()) \(stream.fps) fps"
}

private struct YouTubeStreamEditView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var database: Database
    @ObservedObject var stream: SettingsStream
    @Environment(\.dismiss) var dismiss
    @State private var streamKey = ""
    @State private var quality: YouTubeQualityPreset = .p1080fps30
    @State private var presentingDeleteConfirm = false

    private func isLocked() -> Bool {
        stream.enabled && (model.isLive || model.isRecording)
    }

    private func saveStreamKey() {
        let key = streamKey.trim()
        guard !key.isEmpty, key != youTubeStreamKey(stream) else {
            return
        }
        stream.url = "\(youTubeIngest(stream))/\(key)"
        model.reloadStreamIfEnabled(stream: stream)
        model.storeSettings()
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $stream.name)
                    .disableAutocorrection(true)
                    .onSubmit {
                        model.storeSettings()
                    }
            } header: {
                Text("Stream name")
            }
            Section {
                TextField(String("xxxx-xxxx-xxxx-xxxx-xxxx"), text: $streamKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onSubmit {
                        saveStreamKey()
                    }
                    .disabled(isLocked())
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
                Picker("Quality", selection: $quality) {
                    ForEach(YouTubeQualityPreset.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
                .disabled(isLocked())
                .onChange(of: quality) { quality in
                    guard quality != youTubeQuality(stream) else {
                        return
                    }
                    applyYouTubeDefaults(stream: stream, quality: quality)
                    model.reloadStreamIfEnabled(stream: stream)
                    model.storeSettings()
                }
            }
            YouTubeBroadcastFieldsView(details: stream.youTubeBroadcast,
                                       signedIn: model.isYouTubeAccountSignedIn(),
                                       stream: stream)
            Section {
                NavigationLink {
                    StreamSettingsView(database: database, stream: stream)
                } label: {
                    Text("Advanced settings")
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Button(role: .destructive) {
                    presentingDeleteConfirm = true
                } label: {
                    HCenter {
                        Text("Delete stream")
                    }
                }
                .disabled(isLocked())
                .confirmationDialog("Delete \(stream.name)?",
                                    isPresented: $presentingDeleteConfirm,
                                    titleVisibility: .visible)
                {
                    Button("Delete", role: .destructive) {
                        model.deleteStream(stream)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(stream.name)
        .onAppear {
            streamKey = youTubeStreamKey(stream)
            quality = youTubeQuality(stream) ?? .p1080fps30
        }
        .onDisappear {
            saveStreamKey()
            model.storeSettings()
        }
    }
}

private struct YouTubeStreamRowView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var database: Database
    @ObservedObject var stream: SettingsStream
    let onGoLive: () -> Void

    var body: some View {
        HStack {
            NavigationLink {
                YouTubeStreamEditView(database: database, stream: stream)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stream.name)
                            .font(.headline)
                        if stream.enabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                    Text(qualityText(stream))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if youTubeStreamKey(stream).isEmpty {
                        Text("No stream key")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            if model.isLive, stream.enabled {
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.red))
            } else {
                Button {
                    onGoLive()
                } label: {
                    Text("Go live")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.red))
                }
                .buttonStyle(.borderless)
                .disabled(model.isLive || youTubeStreamKey(stream).isEmpty)
                .opacity(model.isLive ? 0.4 : 1)
            }
        }
    }
}

private struct YouTubeAccountView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var database: Database
    @ObservedObject var account: SettingsStream
    @State private var fetching = false
    @State private var fetchFailed = false
    @State private var presentingLogoutConfirm = false
    @State private var manualKey = ""

    private func fetch() {
        fetching = true
        fetchFailed = false
        model.fetchYouTubeAccountDetails { ok in
            fetching = false
            fetchFailed = !ok
        }
    }

    var body: some View {
        Section {
            if account.isYouTubeAuthorized() {
                HStack {
                    Text("Signed in")
                    Spacer()
                    Text(database.youTubeAccountHandle.isEmpty ? String(localized: "Google") : database
                        .youTubeAccountHandle)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Stream key")
                    Spacer()
                    if fetching {
                        ProgressView()
                    } else if database.youTubeAccountStreamKey.isEmpty {
                        Text("Not found")
                            .foregroundStyle(.red)
                    } else {
                        Text(maskedStreamKey(database.youTubeAccountStreamKey))
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Get stream key again") {
                    fetch()
                }
                .disabled(fetching)
                Button("Log out", role: .destructive) {
                    presentingLogoutConfirm = true
                }
                .confirmationDialog("Log out of YouTube?",
                                    isPresented: $presentingLogoutConfirm,
                                    titleVisibility: .visible)
                {
                    Button("Log out", role: .destructive) {
                        model.youTubeAccountSignOut()
                    }
                }
            } else {
                Button {
                    model.youTubeAccountSignIn()
                } label: {
                    Label("Sign in with Google", systemImage: "person.crop.circle.badge.checkmark")
                }
                if !database.youTubeAccountStreamKey.isEmpty {
                    HStack {
                        Text("Saved stream key")
                        Spacer()
                        Text(maskedStreamKey(database.youTubeAccountStreamKey))
                            .foregroundStyle(.secondary)
                    }
                    Button("Forget stream key", role: .destructive) {
                        database.youTubeAccountStreamKey = ""
                        model.storeSettings()
                    }
                } else {
                    TextField("Or paste stream key", text: $manualKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onSubmit {
                            let key = manualKey.trim()
                            guard !key.isEmpty else {
                                return
                            }
                            database.youTubeAccountStreamKey = key
                            manualKey = ""
                            model.storeSettings()
                        }
                }
            }
        } header: {
            Text("YouTube account")
        } footer: {
            if fetchFailed {
                Text("Couldn't get the stream key. Check that live streaming is enabled in YouTube Studio.")
                    .foregroundStyle(.red)
            } else if account.isYouTubeAuthorized() {
                Text("New streams use this key and sign-in. Logging out keeps your saved streams.")
            } else {
                Text("Sign in once to get your stream key. It's saved for all new streams.")
            }
        }
        .onChange(of: account.youTubeAuthState) { authState in
            if authState != nil {
                model.youTubeAccountSignedIn()
                fetching = true
                fetchFailed = false
                model.fetchYouTubeAccountDetails { ok in
                    fetching = false
                    fetchFailed = !ok
                }
            }
        }
    }
}

struct YouTubeStreamsView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var database: Database
    @ObservedObject var createStreamWizard: CreateStreamWizard
    let onGoLive: () -> Void

    var body: some View {
        Form {
            YouTubeAccountView(database: database, account: model.youTubeAccount)
            Section {
                if database.streams.isEmpty {
                    Text("No streams yet. Tap Add YouTube stream below.")
                        .foregroundStyle(.secondary)
                }
                ForEach(database.streams) { stream in
                    YouTubeStreamRowView(database: database, stream: stream) {
                        model.goLive(stream: stream)
                        onGoLive()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !(stream.enabled && (model.isLive || model.isRecording)) {
                            SwipeLeftToDeleteButtonView {
                                model.deleteStream(stream)
                            }
                        }
                    }
                }
            } header: {
                Text("Streams")
            } footer: {
                Text("Tap Go live to start streaming. Tap a stream to change its name, key, quality, title, visibility, thumbnail and schedule.")
            }
            Section {
                Button {
                    model.resetWizard()
                    createStreamWizard.presentingYouTube = true
                } label: {
                    Label("Add YouTube stream", systemImage: "plus.circle.fill")
                }
                .disabled(model.isLive || model.isRecording)
            }
        }
        .navigationTitle("YouTube streams")
        .sheet(isPresented: $createStreamWizard.presentingYouTube) {
            NavigationStack {
                StreamWizardYouTubeSettingsView(model: model,
                                                createStreamWizard: createStreamWizard,
                                                youTubeStream: createStreamWizard.youTubeStream)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
