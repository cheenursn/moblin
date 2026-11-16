import Foundation

extension Model {
    func resetBhoomiBrandingVideoEffects(widgets: [SettingsWidget]) {
        bhoomiBrandingEffects.removeAll()
        for widget in widgets where widget.type == .bhoomiBranding {
            let effect = BhoomiBrandingEffect(widget: widget.bhoomiBranding.clone())
            effect.effects = widget.getEffects(model: self)
            bhoomiBrandingEffects[widget.id] = effect
        }
    }

    func addSceneBhoomiBrandingEffects(
        _ sceneWidget: SettingsSceneWidget,
        _ widget: SettingsWidget,
        _ effects: inout [VideoEffect]
    ) {
        guard let effect = bhoomiBrandingEffects[widget.id], !effects.contains(effect) else {
            return
        }
        effect.setSceneWidget(sceneWidget: sceneWidget.clone())
        effects.append(effect)
    }
}
