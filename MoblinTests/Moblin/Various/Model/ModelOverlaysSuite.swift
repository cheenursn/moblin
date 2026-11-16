import Foundation
@testable import Moblin
import Testing

@MainActor
private final class Fixture {
    let database = Database()
    let scene = SettingsScene(name: "Live")
    let text = SettingsWidget(name: "Lower third")
    let branding = SettingsWidget(name: "Logo")

    init() {
        text.type = .text
        text.text.formatString = "Hello {time}"
        branding.type = .bhoomiBranding
        branding.bhoomiBranding.header = "Bhoomi"
        branding.bhoomiBranding.footer = "Live now"
        database.widgets = [text, branding]
        scene.widgets = [SettingsSceneWidget(widget: text), SettingsSceneWidget(widget: branding)]
        database.scenes = [scene]
    }
}

@MainActor
struct ModelOverlaysSuite {
    @Test
    func copyGetsNewWidgetIds() {
        let fixture = Fixture()
        let copy = copySceneWithWidgets(database: fixture.database, scene: fixture.scene, name: "Giveaway")
        let copiedIds = Set(copy.widgets.map(\.widgetId))
        #expect(copiedIds.count == 2)
        #expect(copiedIds.isDisjoint(with: [fixture.text.id, fixture.branding.id]))
        #expect(copiedIds.allSatisfy { fixture.database.findWidget(id: $0) != nil })
        #expect(copy.id != fixture.scene.id)
        #expect(copy.name == "Giveaway")
    }

    @Test
    func copyKeepsWidgetContent() throws {
        let fixture = Fixture()
        let copy = copySceneWithWidgets(database: fixture.database, scene: fixture.scene, name: "Giveaway")
        let text = try #require(fixture.database.findWidget(id: copy.widgets[0].widgetId))
        let branding = try #require(fixture.database.findWidget(id: copy.widgets[1].widgetId))
        #expect(text.type == .text)
        #expect(text.text.formatString == "Hello {time}")
        #expect(branding.type == .bhoomiBranding)
        #expect(branding.bhoomiBranding.header == "Bhoomi")
        #expect(branding.bhoomiBranding.footer == "Live now")
    }

    @Test
    func editingCopyLeavesOriginalUntouched() throws {
        let fixture = Fixture()
        let copy = copySceneWithWidgets(database: fixture.database, scene: fixture.scene, name: "Giveaway")
        let text = try #require(fixture.database.findWidget(id: copy.widgets[0].widgetId))
        let branding = try #require(fixture.database.findWidget(id: copy.widgets[1].widgetId))
        text.text.formatString = "Giveaway!"
        branding.bhoomiBranding.header = "Giveaway"
        #expect(fixture.text.text.formatString == "Hello {time}")
        #expect(fixture.branding.bhoomiBranding.header == "Bhoomi")
        #expect(fixture.scene.widgets.map(\.widgetId) == [fixture.text.id, fixture.branding.id])
        #expect(fixture.database.scenes.map(\.name) == ["Live", "Giveaway"])
        #expect(fixture.database.widgets.count == 4)
    }
}

@MainActor
private final class ImageStepsFixture {
    let database = Database()
    let scene = SettingsScene(name: "Live")
    let other = SettingsWidget(name: "Other image")
    var steps: [SettingsWidget] = []

    init() {
        other.type = .image
        database.widgets.append(other)
        steps = (0 ..< 3).map { _ in makeImageStep(database: database) }
        scene.widgets = [SettingsSceneWidget(widget: other)]
        database.scenes = [scene]
    }

    func stepIdsInScene() -> [UUID] {
        let stepIds = Set(steps.map(\.id))
        return scene.widgets.map(\.widgetId).filter { stepIds.contains($0) }
    }
}

@MainActor
struct ImageStepsSuite {
    @Test
    func stepsKeepAddOrderAndSkipOtherImages() {
        let fixture = ImageStepsFixture()
        #expect(imageSteps(database: fixture.database).map(\.id) == fixture.steps.map(\.id))
    }

    @Test
    func showingStepReplacesShownStep() {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[0])
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[2])
        #expect(fixture.stepIdsInScene() == [fixture.steps[2].id])
        #expect(fixture.scene.widgets.contains { $0.widgetId == fixture.other.id })
    }

    @Test
    func shownStepIsCenteredAndLarge() throws {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[1])
        let sceneWidget = try #require(fixture.scene.widgets.last)
        #expect(sceneWidget.layout.alignment == .center)
        #expect(sceneWidget.layout.size == 80)
    }

    @Test
    func hidingRemovesOnlySteps() {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[1])
        hideImageSteps(database: fixture.database, scene: fixture.scene)
        #expect(fixture.scene.widgets.map(\.widgetId) == [fixture.other.id])
    }

    @Test
    func nextStartsAtFirstStep() {
        let fixture = ImageStepsFixture()
        #expect(nextImageStep(database: fixture.database, scene: fixture.scene) === fixture.steps[0])
    }

    @Test
    func nextFollowsShownStep() {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[1])
        #expect(nextImageStep(database: fixture.database, scene: fixture.scene) === fixture.steps[2])
    }

    @Test
    func nextAfterLastStepIsNone() {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[2])
        #expect(nextImageStep(database: fixture.database, scene: fixture.scene) == nil)
    }

    @Test
    func movingStepsReordersThem() {
        let fixture = ImageStepsFixture()
        moveImageSteps(database: fixture.database, fromOffsets: [2], toOffset: 0)
        #expect(imageSteps(database: fixture.database).map(\.id)
            == [fixture.steps[2].id, fixture.steps[0].id, fixture.steps[1].id])
        #expect(fixture.database.widgets.first === fixture.other)
    }

    @Test
    func imageStepFlagSurvivesReload() throws {
        let fixture = ImageStepsFixture()
        let database = try Database.fromString(settings: fixture.database.toString())
        #expect(imageSteps(database: database).map(\.id) == fixture.steps.map(\.id))
    }

    @Test
    func duplicatingSceneSharesImageSteps() {
        let fixture = ImageStepsFixture()
        showImageStep(database: fixture.database, scene: fixture.scene, step: fixture.steps[0])
        let copy = copySceneWithWidgets(database: fixture.database, scene: fixture.scene, name: "Copy")
        #expect(copy.widgets.contains { $0.widgetId == fixture.steps[0].id })
        #expect(imageSteps(database: fixture.database).count == 3)
    }
}
