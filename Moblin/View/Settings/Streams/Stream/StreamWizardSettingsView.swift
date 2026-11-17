import SwiftUI

struct WizardNextButtonView: View {
    var body: some View {
        HCenter {
            Text("Next")
                .foregroundStyle(Color.accentColor)
        }
    }
}

struct WizardSkipButtonView: View {
    var body: some View {
        HCenter {
            Text("Skip")
                .foregroundStyle(Color.accentColor)
        }
    }
}

struct CreateStreamWizardToolbar: ToolbarContent {
    @ObservedObject var createStreamWizard: CreateStreamWizard

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                createStreamWizard.presenting = false
                createStreamWizard.presentingSetup = false
                createStreamWizard.presentingYouTube = false
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
}

struct StreamWizardSettingsView: View {
    let model: Model
    let createStreamWizard: CreateStreamWizard

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    StreamWizardYouTubeSettingsView(
                        model: model,
                        createStreamWizard: createStreamWizard,
                        youTubeStream: createStreamWizard.youTubeStream
                    )
                } label: {
                    YouTubeLogoAndNameView()
                }
            } header: {
                Text("Bhoomi Creatives")
            } footer: {
                Text("Paste your YouTube stream key once, then go live with one tap.")
            }
            Section {
                NavigationLink {
                    StreamWizardOthersSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    Text("Others")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Create stream wizard")
        .toolbar {
            CreateStreamWizardToolbar(createStreamWizard: createStreamWizard)
        }
    }
}

private struct StreamWizardOthersSettingsView: View {
    let model: Model
    let createStreamWizard: CreateStreamWizard

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    StreamWizardTwitchSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    TwitchLogoAndNameView()
                }
                NavigationLink {
                    StreamWizardKickSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    KickLogoAndNameView()
                }
                NavigationLink {
                    StreamWizardSoopSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    SoopLogoAndNameView()
                }
                NavigationLink {
                    StreamWizardObsSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    ObsLogoAndNameView()
                }
            } header: {
                Text("Platforms")
            }
            if !isMac() {
                Section {
                    NavigationLink {
                        StreamWizardMobcamSettingsView(model: model, createStreamWizard: createStreamWizard)
                    } label: {
                        MobcamLogoAndNameView()
                    }
                }
            }
            Section {
                NavigationLink {
                    StreamWizardCustomSettingsView(model: model, createStreamWizard: createStreamWizard)
                } label: {
                    Text("Custom")
                }
            } footer: {
                Text("For advanced users or if your platform is not in the list above.")
            }
        }
        .navigationTitle("Others")
        .toolbar {
            CreateStreamWizardToolbar(createStreamWizard: createStreamWizard)
        }
    }
}
