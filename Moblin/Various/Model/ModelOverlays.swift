import Foundation

func deepCopyWidget(_ widget: SettingsWidget) -> SettingsWidget {
    let data = try! JSONEncoder().encode(widget)
    let copy = try! JSONDecoder().decode(SettingsWidget.self, from: data)
    copy.id = UUID()
    return copy
}

@MainActor
func copySceneWithWidgets(database: Database, scene: SettingsScene, name: String) -> SettingsScene {
    let newScene = scene.clone()
    newScene.name = makeUniqueName(name: name.isEmpty ? scene.name : name, existingNames: database.scenes)
    var copiedWidgetIds: [UUID: UUID] = [:]
    for sceneWidget in newScene.widgets {
        if let copiedWidgetId = copiedWidgetIds[sceneWidget.widgetId] {
            sceneWidget.widgetId = copiedWidgetId
            continue
        }
        guard let widget = database.findWidget(id: sceneWidget.widgetId), !widget.imageStep else {
            continue
        }
        let copy = deepCopyWidget(widget)
        copy.name = makeUniqueName(name: "\(newScene.name) \(widget.name)", existingNames: database.widgets)
        database.widgets.append(copy)
        copiedWidgetIds[widget.id] = copy.id
        sceneWidget.widgetId = copy.id
    }
    database.scenes.append(newScene)
    return newScene
}

func imageSteps(database: Database) -> [SettingsWidget] {
    database.widgets.filter { $0.type == .image && $0.imageStep }
}

func shownImageStep(database: Database, scene: SettingsScene) -> SettingsWidget? {
    let steps = imageSteps(database: database)
    for sceneWidget in scene.widgets {
        if let step = steps.first(where: { $0.id == sceneWidget.widgetId }) {
            return step
        }
    }
    return nil
}

func makeImageStep(database: Database) -> SettingsWidget {
    let widget = SettingsWidget(name: makeUniqueName(name: String(localized: "Image step"),
                                                     existingNames: database.widgets))
    widget.type = .image
    widget.imageStep = true
    database.widgets.append(widget)
    return widget
}

func showImageStep(database: Database, scene: SettingsScene, step: SettingsWidget) {
    let otherStepIds = Set(imageSteps(database: database).map(\.id)).subtracting([step.id])
    scene.widgets.removeAll { otherStepIds.contains($0.widgetId) }
    if !scene.widgets.contains(where: { $0.widgetId == step.id }) {
        let sceneWidget = SettingsSceneWidget(widget: step)
        sceneWidget.layout.alignment = .center
        sceneWidget.layout.x = 0
        sceneWidget.layout.y = 0
        sceneWidget.layout.size = 80
        sceneWidget.layout.updateXString()
        sceneWidget.layout.updateYString()
        sceneWidget.layout.updateSizeString()
        scene.widgets.append(sceneWidget)
    }
    step.enabled = true
}

func hideImageSteps(database: Database, scene: SettingsScene) {
    let stepIds = Set(imageSteps(database: database).map(\.id))
    scene.widgets.removeAll { stepIds.contains($0.widgetId) }
}

func nextImageStep(database: Database, scene: SettingsScene) -> SettingsWidget? {
    let steps = imageSteps(database: database)
    guard let shown = shownImageStep(database: database, scene: scene) else {
        return steps.first
    }
    guard let index = steps.firstIndex(where: { $0 === shown }), index + 1 < steps.count else {
        return nil
    }
    return steps[index + 1]
}

func moveImageSteps(database: Database, fromOffsets: IndexSet, toOffset: Int) {
    var steps = imageSteps(database: database)
    steps.move(fromOffsets: fromOffsets, toOffset: toOffset)
    var widgets = database.widgets
    var stepIndex = 0
    for index in widgets.indices where widgets[index].type == .image && widgets[index].imageStep {
        widgets[index] = steps[stepIndex]
        stepIndex += 1
    }
    database.widgets = widgets
}

extension Model {
    func addImageStep(data: Data) {
        let step = makeImageStep(database: database)
        imageStorage.write(id: step.id, data: data)
        resetSelectedScene(changeScene: false, attachCamera: false)
    }

    func deleteImageStep(_ step: SettingsWidget) {
        database.widgets.removeAll(where: { $0 === step })
        removeDeadWidgetsFromScenes()
        imageStorage.remove(id: step.id)
        resetSelectedScene(changeScene: false, attachCamera: false)
    }

    func reorderImageSteps(fromOffsets: IndexSet, toOffset: Int) {
        moveImageSteps(database: database, fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func toggleImageStep(_ step: SettingsWidget) {
        guard let scene = getSelectedScene() else {
            return
        }
        if shownImageStep(database: database, scene: scene) === step {
            hideImageSteps(database: database, scene: scene)
        } else {
            showImageStep(database: database, scene: scene, step: step)
        }
        sceneUpdated()
    }

    func showNextImageStep() {
        guard let scene = getSelectedScene() else {
            return
        }
        if let step = nextImageStep(database: database, scene: scene) {
            showImageStep(database: database, scene: scene, step: step)
        } else {
            hideImageSteps(database: database, scene: scene)
        }
        sceneUpdated()
    }

    func shownImageStepInSelectedScene() -> SettingsWidget? {
        guard let scene = getSelectedScene() else {
            return nil
        }
        return shownImageStep(database: database, scene: scene)
    }

    @discardableResult
    func duplicateSceneWithWidgets(_ scene: SettingsScene, name: String) -> SettingsScene {
        let newScene = copySceneWithWidgets(database: database, scene: scene, name: name)
        fixAlertMedias()
        resetSelectedScene(changeScene: false, attachCamera: false)
        for widget in widgetsInScene(newScene) where widget.type == .text {
            textWidgetTextChanged(widget: widget)
        }
        return newScene
    }

    func widgetsInScene(_ scene: SettingsScene) -> [SettingsWidget] {
        scene.widgets.compactMap { database.findWidget(id: $0.widgetId) }
    }
}
