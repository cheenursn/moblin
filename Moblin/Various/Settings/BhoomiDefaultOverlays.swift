import Foundation

private struct BhoomiFrameOverlay {
    let name: String
    let title: String
    let footer: String
    let colorScheme: SettingsWidgetBhoomiBrandingColorScheme
}

private func bhoomiFrameOverlays() -> [BhoomiFrameOverlay] {
    [
        .init(name: String(localized: "Live"),
              title: "Bhoomi Creatives",
              footer: String(localized: "Live"),
              colorScheme: .gold),
        .init(name: String(localized: "Starting soon"),
              title: String(localized: "Starting soon"),
              footer: "Bhoomi Creatives",
              colorScheme: .royalBlue),
        .init(name: String(localized: "Be right back"),
              title: String(localized: "Be right back"),
              footer: "Bhoomi Creatives",
              colorScheme: .emerald),
        .init(name: String(localized: "Thanks for watching"),
              title: String(localized: "Thanks for watching"),
              footer: String(localized: "Subscribe to Bhoomi Creatives"),
              colorScheme: .crimson),
    ]
}

@MainActor
func addBhoomiDefaultOverlaysOnce(database: Database) {
    guard !database.bhoomiOverlaysAdded else {
        upgradeBhoomiOverlaysToFramesOnce(database: database)
        addBhoomiPortraitFramesOnce(database: database)
        return
    }
    addBhoomiFrameOverlays(database: database, orientation: .landscape)
    addBhoomiFrameOverlays(database: database, orientation: .portrait)
    database.bhoomiOverlaysAdded = true
    database.bhoomiFramesAdded = true
    database.bhoomiPortraitFramesAdded = true
}

@MainActor
private func addBhoomiPortraitFramesOnce(database: Database) {
    guard !database.bhoomiPortraitFramesAdded else {
        return
    }
    let names = Set(bhoomiFrameOverlays().map(\.name))
    for scene in database.scenes where names.contains(scene.name) && scene.orientation == .any {
        scene.orientation = .landscape
    }
    addBhoomiFrameOverlays(database: database, orientation: .portrait)
    database.bhoomiPortraitFramesAdded = true
}

@MainActor
private func upgradeBhoomiOverlaysToFramesOnce(database: Database) {
    guard !database.bhoomiFramesAdded else {
        return
    }
    let names = Set(bhoomiFrameOverlays().map(\.name))
    let isOldCard: (SettingsScene) -> Bool = { names.contains($0.name) && $0.orientation == .any }
    let oldScenes = database.scenes.filter(isOldCard)
    let oldWidgetIds = Set(oldScenes.flatMap { $0.widgets.map(\.widgetId) })
    database.scenes.removeAll(where: isOldCard)
    let stillUsed = Set(database.scenes.flatMap { $0.widgets.map(\.widgetId) })
    database.widgets.removeAll { oldWidgetIds.contains($0.id) && !stillUsed.contains($0.id) }
    addBhoomiFrameOverlays(database: database, orientation: .landscape)
    database.bhoomiFramesAdded = true
}

private func addBhoomiFrameOverlays(database: Database, orientation: SettingsSceneOrientation) {
    for overlay in bhoomiFrameOverlays() {
        let scene = SettingsScene(name: overlay.name)
        scene.orientation = orientation
        scene.videoSource.cameraPosition = defaultBackCameraPosition
        scene.videoSource.backCameraId = bestBackCameraId
        let frame = SettingsWidget(name: overlay.name)
        frame.type = .bhoomiBranding
        frame.bhoomiBranding.style = .frame
        frame.bhoomiBranding.titleStyle.alignment = .leading
        frame.bhoomiBranding.showLogo = true
        frame.bhoomiBranding.header = overlay.title
        frame.bhoomiBranding.footer = overlay.footer
        frame.bhoomiBranding.setColorScheme(overlay.colorScheme)
        database.widgets.append(frame)
        let sceneWidget = SettingsSceneWidget(widget: frame)
        sceneWidget.layout.alignment = .center
        sceneWidget.layout.x = 0
        sceneWidget.layout.y = 0
        sceneWidget.layout.size = 100
        sceneWidget.layout.updateXString()
        sceneWidget.layout.updateYString()
        sceneWidget.layout.updateSizeString()
        scene.widgets.append(sceneWidget)
        database.scenes.append(scene)
    }
}
