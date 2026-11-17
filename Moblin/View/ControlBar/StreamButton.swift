import SwiftUI

private struct StreamButtonText: View {
    @ObservedObject var database: Database
    let text: String

    var body: some View {
        Text(text)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(.white)
            .frame(minWidth: 60)
            .padding(5)
            .background(RoundedRectangle(cornerRadius: 10).fill(database.streamButtonColorColor))
    }
}

private struct EndButtonView: View {
    @EnvironmentObject var model: Model
    @Binding var presentingGoLiveNotificationConfirm: Bool
    @State private var presentingStopConfirm = false

    var body: some View {
        StreamButtonText(database: model.database, text: String(localized: "End"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white)
            )
            .onTapGesture {
                presentingStopConfirm = true
            }
            .onLongPressGesture {
                model.toggleShowingPanel(type: nil, panel: .streamingButtonSettings)
            }
            .confirmationDialog("", isPresented: $presentingGoLiveNotificationConfirm) {
                Button("Send Go live notification") {
                    model.sendGoLiveNotification()
                }
            }
            .confirmationDialog("", isPresented: $presentingStopConfirm) {
                if model.stream.obsAutoStopStream, model.stream.obsAutoStopRecording {
                    Button("End but leave OBS streaming and recording") {
                        _ = model.stopStream(stopObsStreamIfEnabled: false, stopObsRecordingIfEnabled: false)
                    }
                } else if model.stream.obsAutoStopStream {
                    Button("End but leave OBS streaming") {
                        _ = model.stopStream(stopObsStreamIfEnabled: false)
                    }
                } else if model.stream.obsAutoStopRecording {
                    Button("End but leave OBS recording") {
                        _ = model.stopStream(stopObsRecordingIfEnabled: false)
                    }
                }
                Button("End") {
                    _ = model.stopStream()
                }
            }
    }
}

private struct GoLiveButtonView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var database: Database
    @ObservedObject var createStreamWizard: CreateStreamWizard
    @State private var presentingStreams = false

    var body: some View {
        StreamButtonText(database: database,
                         text: database.streams.isEmpty ? String(localized: "Setup") : String(localized: "Go Live"))
            .onTapGesture {
                presentingStreams = true
            }
            .onLongPressGesture {
                model.toggleShowingPanel(type: nil, panel: .streamingButtonSettings)
            }
            .sheet(isPresented: $presentingStreams) {
                NavigationStack {
                    YouTubeStreamsView(database: database, createStreamWizard: createStreamWizard) {
                        presentingStreams = false
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        CloseToolbar(presenting: $presentingStreams)
                    }
                }
            }
    }
}

struct StreamButton: View {
    @EnvironmentObject var model: Model
    @ObservedObject var show: Show
    @State private var presentingGoLiveNotificationConfirm = false

    var body: some View {
        if model.isLive {
            EndButtonView(presentingGoLiveNotificationConfirm: $presentingGoLiveNotificationConfirm)
                .disabled(show.chatPhone)
                .opacity(show.chatPhone ? 0.5 : 1)
        } else {
            GoLiveButtonView(database: model.database, createStreamWizard: model.createStreamWizard)
                .disabled(show.chatPhone)
                .opacity(show.chatPhone ? 0.5 : 1)
        }
    }
}
