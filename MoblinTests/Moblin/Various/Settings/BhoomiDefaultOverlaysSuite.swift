import Foundation
@testable import Moblin
import Testing

private let frameNames = ["Live", "Starting soon", "Be right back", "Thanks for watching"]
private let overlayNames = frameNames + frameNames

@MainActor
private func databaseWithOverlays() -> Database {
    let database = Database()
    addBhoomiDefaultOverlaysOnce(database: database)
    return database
}

@MainActor
struct BhoomiDefaultOverlaysSuite {
    @Test
    func freshDatabaseGetsFourOverlays() {
        let database = Database()
        addBhoomiDefaultOverlaysOnce(database: database)
        #expect(database.scenes.map { $0.name } == overlayNames)
        #expect(database.widgets.count == 8)
        #expect(database.bhoomiOverlaysAdded)
    }

    @Test
    func addingAgainDoesNothing() {
        let database = databaseWithOverlays()
        addBhoomiDefaultOverlaysOnce(database: database)
        #expect(database.scenes.map { $0.name } == overlayNames)
        #expect(database.widgets.count == 8)
    }

    @Test
    func settingsWithoutFlagGetOverlaysOnLoad() throws {
        let database = try Database.fromString(settings: "{}")
        #expect(database.scenes.map { $0.name } == overlayNames)
        #expect(database.bhoomiOverlaysAdded)
    }

    @Test
    func reloadDoesNotAddOverlaysAgain() throws {
        let settings = try databaseWithOverlays().toString()
        let database = try Database.fromString(settings: settings)
        #expect(database.scenes.map { $0.name } == overlayNames)
        #expect(database.widgets.count == 8)
    }

    @Test
    func deletedOverlaysAreNotAddedAgain() throws {
        let database = databaseWithOverlays()
        database.scenes.removeAll()
        database.widgets.removeAll()
        let reloaded = try Database.fromString(settings: database.toString())
        #expect(reloaded.scenes.isEmpty)
        #expect(reloaded.widgets.isEmpty)
    }

    @Test
    func sceneWidgetsReferenceAddedWidgets() {
        let database = databaseWithOverlays()
        let widgetIds = Set(database.widgets.map { $0.id })
        #expect(database.scenes.allSatisfy { scene in
            !scene.widgets.isEmpty && scene.widgets.allSatisfy { widgetIds.contains($0.widgetId) }
        })
    }

    @Test
    func overlaysAreFramesInDifferentColors() {
        let database = databaseWithOverlays()
        let branding = database.widgets.map { $0.bhoomiBranding }
        #expect(branding.allSatisfy { $0.style == .frame })
        #expect(Set(branding.map { $0.colorScheme }).count == 4)
        #expect(branding.count == 8)
        #expect(database.scenes.allSatisfy { $0.widgets.first?.layout.size == 100 })
    }

    @Test
    func cardOverlaysAreUpgradedToFramesOnce() throws {
        let database = Database()
        database.scenes.append(SettingsScene(name: "My scene"))
        for name in frameNames {
            let card = SettingsWidget(name: name)
            card.type = .bhoomiBranding
            database.widgets.append(card)
            let scene = SettingsScene(name: name)
            scene.widgets.append(SettingsSceneWidget(widget: card))
            database.scenes.append(scene)
        }
        database.bhoomiOverlaysAdded = true
        let reloaded = try Database.fromString(settings: database.toString())
        #expect(reloaded.scenes.map { $0.name } == ["My scene"] + overlayNames)
        #expect(reloaded.widgets.count == 8)
        #expect(reloaded.widgets.allSatisfy { $0.bhoomiBranding.style == .frame })
        #expect(reloaded.bhoomiFramesAdded)
        #expect(reloaded.bhoomiPortraitFramesAdded)
        let again = try Database.fromString(settings: reloaded.toString())
        #expect(again.scenes.count == 9)
    }
}

@MainActor
struct BhoomiTextStyleSuite {
    @Test
    func textStyleSurvivesReload() throws {
        let database = Database()
        addBhoomiDefaultOverlaysOnce(database: database)
        let branding = database.widgets[0].bhoomiBranding
        branding.titleStyle.design = .serif
        branding.titleStyle.weight = .black
        branding.titleStyle.sizePercent = 150
        branding.footerStyle.alignment = .trailing
        let reloaded = try Database.fromString(settings: database.toString()).widgets[0].bhoomiBranding
        #expect(reloaded.titleStyle.design == .serif)
        #expect(reloaded.titleStyle.weight == .black)
        #expect(reloaded.titleStyle.sizePercent == 150)
        #expect(reloaded.titleStyle.alignment == .leading)
        #expect(reloaded.footerStyle.alignment == .trailing)
    }
}

@MainActor
struct BhoomiSceneOrientationSuite {
    @Test
    func freshDatabaseHasLandscapeAndPortraitFrames() {
        let database = Database()
        addBhoomiDefaultOverlaysOnce(database: database)
        let landscape = database.scenes.filter { $0.orientation == .landscape }.map(\.name)
        let portrait = database.scenes.filter { $0.orientation == .portrait }.map(\.name)
        #expect(landscape == ["Live", "Starting soon", "Be right back", "Thanks for watching"])
        #expect(portrait == landscape)
    }

    @Test(arguments: [
        (SettingsSceneOrientation.any, false, true),
        (.any, true, true),
        (.landscape, false, true),
        (.landscape, true, false),
        (.portrait, false, false),
        (.portrait, true, true),
    ])
    func sceneMatchesStreamShape(orientation: SettingsSceneOrientation, portrait: Bool, expected: Bool) {
        #expect(orientation.matches(portraitStream: portrait) == expected)
    }

    @Test
    func orientationSurvivesReload() throws {
        let database = Database()
        let scene = SettingsScene(name: "Mine")
        scene.orientation = .portrait
        database.scenes.append(scene)
        let reloaded = try Database.fromString(settings: database.toString())
        #expect(reloaded.scenes.first { $0.name == "Mine" }?.orientation == .portrait)
    }
}
