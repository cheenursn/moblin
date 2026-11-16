import PhotosUI
import SwiftUI

private struct OverlayTextDrafts {
    var texts: [UUID: String] = [:]
    var headers: [UUID: String] = [:]
    var footers: [UUID: String] = [:]
    var colors: [UUID: SettingsWidgetBhoomiBrandingColorScheme] = [:]
}

private struct OverlayColorSwatchesView: View {
    @Binding var selected: SettingsWidgetBhoomiBrandingColorScheme?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(SettingsWidgetBhoomiBrandingColorScheme.allCases.filter { $0 != .custom }, id: \.self) { scheme in
                    if let colors = scheme.colors() {
                        Button {
                            selected = scheme
                        } label: {
                            Circle()
                                .fill(colors.background.color())
                                .overlay(Circle().stroke(colors.accent.color(), lineWidth: 4))
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(colors.text.color())
                                        .opacity(selected == scheme ? 1 : 0)
                                )
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(scheme.toString())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct OverlayEditTextView: View {
    let model: Model
    let scene: SettingsScene
    @Binding var drafts: OverlayTextDrafts
    let onDone: () -> Void

    private func textWidgets() -> [SettingsWidget] {
        model.widgetsInScene(scene).filter { $0.type == .text }
    }

    private func brandingWidgets() -> [SettingsWidget] {
        model.widgetsInScene(scene).filter { $0.type == .bhoomiBranding }
    }

    private func binding(_ dictionary: WritableKeyPath<OverlayTextDrafts, [UUID: String]>,
                         _ id: UUID) -> Binding<String>
    {
        Binding(get: {
            drafts[keyPath: dictionary][id] ?? ""
        }, set: {
            drafts[keyPath: dictionary][id] = $0
        })
    }

    private func save() {
        for widget in textWidgets() {
            if let text = drafts.texts[widget.id], text != widget.text.formatString {
                widget.text.formatString = text
                model.textWidgetTextChanged(widget: widget)
            }
        }
        var brandingChanged = false
        for widget in brandingWidgets() {
            if let header = drafts.headers[widget.id], header != widget.bhoomiBranding.header {
                widget.bhoomiBranding.header = header
                brandingChanged = true
            }
            if let footer = drafts.footers[widget.id], footer != widget.bhoomiBranding.footer {
                widget.bhoomiBranding.footer = footer
                brandingChanged = true
            }
            if let color = drafts.colors[widget.id], color != widget.bhoomiBranding.colorScheme {
                widget.bhoomiBranding.setColorScheme(color)
                brandingChanged = true
            }
        }
        if brandingChanged {
            model.resetSelectedScene(changeScene: false)
        }
        onDone()
    }

    var body: some View {
        let textWidgets = textWidgets()
        let brandingWidgets = brandingWidgets()
        if textWidgets.isEmpty, brandingWidgets.isEmpty {
            Text("This overlay has no text to edit.")
                .foregroundStyle(.secondary)
        }
        ForEach(textWidgets) { widget in
            VStack(alignment: .leading) {
                Text(widget.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MultiLineTextFieldView(value: binding(\.texts, widget.id),
                                       placeholder: String(localized: "Text"))
                    .disableAutocorrection(true)
            }
        }
        ForEach(brandingWidgets) { widget in
            VStack(alignment: .leading) {
                Text(widget.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(widget.bhoomiBranding.style == .frame ? String(localized: "Title") : String(localized: "Header"),
                          text: binding(\.headers, widget.id))
                    .disableAutocorrection(true)
                TextField(String(localized: "Footer"), text: binding(\.footers, widget.id))
                    .disableAutocorrection(true)
                OverlayColorSwatchesView(selected: Binding(get: {
                    drafts.colors[widget.id]
                }, set: {
                    drafts.colors[widget.id] = $0
                }))
                DisclosureGroup("Title style") {
                    BhoomiTextStyleSettingsView(style: widget.bhoomiBranding.titleStyle) {
                        model.resetSelectedScene(changeScene: false)
                    }
                }
                DisclosureGroup("Footer style") {
                    BhoomiTextStyleSettingsView(style: widget.bhoomiBranding.footerStyle) {
                        model.resetSelectedScene(changeScene: false)
                    }
                }
            }
        }
        if !textWidgets.isEmpty || !brandingWidgets.isEmpty {
            HStack {
                Button("Cancel") {
                    onDone()
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Save") {
                    save()
                }
                .buttonStyle(.borderless)
                .bold()
            }
        }
    }
}

private struct OverlayItemView: View {
    let model: Model
    @ObservedObject var scene: SettingsScene
    let isSelected: Bool
    let isEditing: Bool
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button {
                model.selectScene(id: scene.id)
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                        .opacity(isSelected ? 1 : 0)
                        .foregroundStyle(.blue)
                    Text(scene.name)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            Button(isEditing ? String(localized: "Close") : String(localized: "Edit text")) {
                onEdit()
            }
            .buttonStyle(.borderless)
        }
    }
}

private struct ImageStepItemView: View {
    let model: Model
    let step: SettingsWidget
    let number: Int
    let isShown: Bool
    let onTap: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                DraggableItemPrefixView()
                Image(systemName: "checkmark")
                    .opacity(isShown ? 1 : 0)
                    .foregroundStyle(.blue)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 36)
                } else {
                    Image(systemName: "photo")
                        .frame(width: 64, height: 36)
                }
                Text(String(localized: "Step \(number)"))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .onAppear {
            if thumbnail == nil, let data = model.imageStorage.tryRead(id: step.id) {
                thumbnail = UIImage(data: data)
            }
        }
    }
}

private struct ImageStepsView: View {
    let model: Model
    @ObservedObject var database: Database
    @ObservedObject var sceneSelector: SceneSelector
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var shownStepId: UUID?

    private func updateShownStep() {
        shownStepId = model.shownImageStepInSelectedScene()?.id
    }

    private func addImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else {
            return
        }
        selectedItems = []
        Task { @MainActor in
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    model.addImageStep(data: data)
                }
            }
        }
    }

    var body: some View {
        let steps = imageSteps(database: database)
        Section {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                ImageStepItemView(model: model,
                                  step: step,
                                  number: index + 1,
                                  isShown: shownStepId == step.id)
                {
                    model.toggleImageStep(step)
                    updateShownStep()
                }
            }
            .onMove { fromOffsets, toOffset in
                model.reorderImageSteps(fromOffsets: fromOffsets, toOffset: toOffset)
            }
            .onDelete { offsets in
                for index in offsets {
                    model.deleteImageStep(steps[index])
                }
                updateShownStep()
            }
            HStack {
                PhotosPicker(selection: $selectedItems, matching: .images) {
                    Label(String(localized: "Add images"), systemImage: "plus")
                }
                .buttonStyle(.borderless)
                Spacer()
                if !steps.isEmpty {
                    Button(String(localized: "Hide")) {
                        if let step = model.shownImageStepInSelectedScene() {
                            model.toggleImageStep(step)
                        }
                        updateShownStep()
                    }
                    .buttonStyle(.borderless)
                    .disabled(shownStepId == nil)
                    Button(String(localized: "Next")) {
                        model.showNextImageStep()
                        updateShownStep()
                    }
                    .buttonStyle(.borderless)
                    .bold()
                    .padding(.leading)
                }
            }
        } header: {
            Text("Images")
        } footer: {
            Text("Tap a step to show it on stream, tap it again to hide it. Next shows the following step.")
        }
        .onChange(of: selectedItems) { items in
            addImages(items)
        }
        .onChange(of: sceneSelector.sceneIndex) { _ in
            updateShownStep()
        }
        .onAppear {
            model.checkPhotoLibraryAuthorization()
            updateShownStep()
        }
    }
}

private struct NewOverlayView: View {
    let model: Model
    @ObservedObject var database: Database
    let onCreated: (SettingsScene) -> Void
    @State private var sourceSceneId: UUID?
    @State private var name = ""

    private func create() {
        guard let sourceSceneId, let scene = database.findScene(id: sourceSceneId) else {
            return
        }
        let newScene = model.duplicateSceneWithWidgets(scene, name: name.trim())
        name = ""
        model.makeToast(title: String(localized: "Created \(newScene.name)"))
        onCreated(newScene)
    }

    var body: some View {
        Section {
            Picker("From", selection: $sourceSceneId) {
                Text("Select").tag(nil as UUID?)
                ForEach(database.scenes) { scene in
                    Text(scene.name).tag(scene.id as UUID?)
                }
            }
            TextField(String(localized: "Name"), text: $name)
                .disableAutocorrection(true)
            Button("Create") {
                create()
            }
            .disabled(sourceSceneId == nil || name.trim().isEmpty)
        } header: {
            Text("New overlay from…")
        } footer: {
            Text("Copies the overlay and its widgets, so edits leave the original unchanged.")
        }
    }
}

struct QuickButtonOverlaysView: View {
    let model: Model
    @ObservedObject var database: Database
    @ObservedObject var sceneSelector: SceneSelector
    @State private var editingSceneId: UUID?
    @State private var drafts = OverlayTextDrafts()

    init(model: Model, database: Database) {
        self.model = model
        self.database = database
        sceneSelector = model.sceneSelector
    }

    private func startEditing(scene: SettingsScene) {
        var newDrafts = OverlayTextDrafts()
        for widget in model.widgetsInScene(scene) {
            switch widget.type {
            case .text:
                newDrafts.texts[widget.id] = widget.text.formatString
            case .bhoomiBranding:
                newDrafts.headers[widget.id] = widget.bhoomiBranding.header
                newDrafts.footers[widget.id] = widget.bhoomiBranding.footer
                newDrafts.colors[widget.id] = widget.bhoomiBranding.colorScheme
            default:
                break
            }
        }
        drafts = newDrafts
        editingSceneId = scene.id
    }

    private func toggleEditing(scene: SettingsScene) {
        if editingSceneId == scene.id {
            editingSceneId = nil
        } else {
            startEditing(scene: scene)
        }
    }

    var body: some View {
        Form {
            Section {
                ForEach(model.enabledScenes) { scene in
                    OverlayItemView(model: model,
                                    scene: scene,
                                    isSelected: sceneSelector.selectedSceneId == scene.id,
                                    isEditing: editingSceneId == scene.id)
                    {
                        toggleEditing(scene: scene)
                    }
                    if editingSceneId == scene.id {
                        OverlayEditTextView(model: model, scene: scene, drafts: $drafts) {
                            editingSceneId = nil
                        }
                    }
                }
            } footer: {
                Text("Tap an overlay to show it.")
            }
            ImageStepsView(model: model, database: database, sceneSelector: sceneSelector)
            NewOverlayView(model: model, database: database) { scene in
                if scene.enabled {
                    startEditing(scene: scene)
                }
            }
        }
        .navigationTitle("Overlays")
    }
}
