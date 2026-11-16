import SwiftUI

struct WidgetBhoomiBrandingSettingsView: View {
    let model: Model
    let widget: SettingsWidget
    @ObservedObject var branding: SettingsWidgetBhoomiBranding

    private func update() {
        model.resetSelectedScene(changeScene: false)
    }

    var body: some View {
        Section {
            Toggle("Show logo", isOn: $branding.showLogo)
                .onChange(of: branding.showLogo) { _ in
                    update()
                }
            TextEditNavigationView(title: String(localized: "Header"), value: branding.header) {
                branding.header = $0
                update()
            }
            TextEditNavigationView(title: String(localized: "Footer"), value: branding.footer) {
                branding.footer = $0
                update()
            }
        } footer: {
            Text("Leave the header or footer empty to hide it.")
        }
        Section {
            Picker("Color scheme", selection: $branding.colorScheme) {
                ForEach(SettingsWidgetBhoomiBrandingColorScheme.allCases, id: \.self) {
                    Text($0.toString())
                }
            }
            .onChange(of: branding.colorScheme) { scheme in
                branding.setColorScheme(scheme)
                update()
            }
            RgbColorPickerView(title: "Background", color: $branding.backgroundColorColor, opacity: true) {
                guard $0 != branding.backgroundColor else {
                    return
                }
                branding.backgroundColor = $0
                branding.colorScheme = .custom
                update()
            }
            RgbColorPickerView(title: "Text", color: $branding.textColorColor) {
                guard $0 != branding.textColor else {
                    return
                }
                branding.textColor = $0
                branding.colorScheme = .custom
                update()
            }
            RgbColorPickerView(title: "Border", color: $branding.accentColorColor) {
                guard $0 != branding.accentColor else {
                    return
                }
                branding.accentColor = $0
                branding.colorScheme = .custom
                update()
            }
        } header: {
            Text("Colors")
        } footer: {
            Text("Changing a color switches the scheme to Custom.")
        }
        WidgetEffectsView(model: model, widget: widget)
    }
}
