import PhotosUI
import SwiftUI

struct YouTubeBroadcastFieldsView: View {
    @EnvironmentObject var model: Model
    @ObservedObject var details: YouTubeBroadcastDetails
    let signedIn: Bool
    var stream: SettingsStream?
    @State private var selectedImage: PhotosPickerItem?
    @State private var scheduling = false
    @State private var scheduleMessage: String?

    var body: some View {
        Section {
            Toggle("Set title, visibility and more", isOn: $details.enabled)
        } header: {
            Text("YouTube broadcast")
        } footer: {
            if !signedIn {
                Text("Needs the YouTube account sign-in at the top of YouTube streams. Off: YouTube uses the title and settings from YouTube Studio.")
            } else if details.enabled {
                Text("Applied to YouTube each time you go live with this stream.")
            } else {
                Text("Off: YouTube uses the title and settings from YouTube Studio.")
            }
        }
        if details.enabled {
            Section {
                TextField("Title", text: $details.title)
                TextField("Description", text: $details.description, axis: .vertical)
                    .lineLimit(3 ... 8)
                Picker("Visibility", selection: $details.visibility) {
                    ForEach(YouTubeApiLiveBroadcaseVisibility.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
            } header: {
                Text("Details")
            }
            Section {
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    if let thumbnail = details.thumbnail {
                        HStack {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(16 / 9, contentMode: .fill)
                                .frame(width: 128, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Change image")
                        }
                    } else {
                        Label("Choose image", systemImage: "photo")
                    }
                }
                if details.thumbnail != nil {
                    Button("Remove image", role: .destructive) {
                        details.setThumbnail(nil)
                        selectedImage = nil
                    }
                }
            } header: {
                Text("Thumbnail")
            } footer: {
                Text("Cropped to 1280×720. Custom thumbnails need a verified YouTube account.")
            }
            .onChange(of: selectedImage) { item in
                item?.loadTransferable(type: Data.self) { result in
                    guard case let .success(data?) = result, let image = UIImage(data: data) else {
                        return
                    }
                    DispatchQueue.main.async {
                        details.setThumbnail(image)
                    }
                }
            }
            Section {
                Picker("Category", selection: $details.category) {
                    ForEach(YouTubeBroadcastCategory.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
                TextField("Tags, separated by commas", text: $details.tags)
                    .textInputAutocapitalization(.never)
                Toggle("Made for kids", isOn: $details.madeForKids)
            } header: {
                Text("Audience and category")
            }
            Section {
                Picker("Latency", selection: $details.latency) {
                    ForEach(YouTubeBroadcastLatency.allCases, id: \.self) {
                        Text($0.toString())
                    }
                }
                Toggle("DVR (viewers can rewind)", isOn: $details.dvr)
                Toggle("Auto-start when video arrives", isOn: $details.autoStart)
                Toggle("Auto-end when video stops", isOn: $details.autoStop)
            } header: {
                Text("Broadcast options")
            }
            Section {
                Picker("Start", selection: $details.startNow) {
                    Text("When I go live").tag(true)
                    Text("At a set time").tag(false)
                }
                if !details.startNow {
                    DatePicker("Start time", selection: $details.startTime, in: Date()...)
                    if let stream {
                        if scheduling {
                            HCenter {
                                ProgressView()
                            }
                        } else {
                            TextButtonView("Schedule on YouTube") {
                                scheduling = true
                                scheduleMessage = nil
                                model.createYouTubeBroadcast(stream: stream, details: details, startNow: false) {
                                    scheduling = false
                                    scheduleMessage = $0 ?? String(localized: "Scheduled. It shows as upcoming on your channel.")
                                    model.storeSettings()
                                }
                            }
                            .disabled(!signedIn)
                        }
                    }
                }
            } header: {
                Text("Schedule")
            } footer: {
                if let scheduleMessage {
                    Text(scheduleMessage)
                } else if details.startNow {
                    Text("A broadcast is created on YouTube when you tap Go live.")
                } else {
                    Text("Scheduled broadcasts appear on your channel as upcoming, so viewers can set a reminder.")
                }
            }
        }
    }
}

