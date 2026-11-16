import SwiftUI

struct WidgetWizardBhoomiBrandingSettingsView: View {
    let model: Model
    let database: Database
    @ObservedObject var branding: SettingsWidgetBhoomiBranding
    let createWidgetWizard: CreateWidgetWizard
    @Binding var presentingCreateWizard: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Show logo", isOn: $branding.showLogo)
                TextField(String(localized: "Header"), text: $branding.header)
                    .disableAutocorrection(true)
                TextField(String(localized: "Footer"), text: $branding.footer)
                    .disableAutocorrection(true)
            } footer: {
                Text("Leave the header or footer empty to hide it.")
            }
            WidgetWizardSelectScenesNavigationView(model: model,
                                                   database: database,
                                                   createWidgetWizard: createWidgetWizard,
                                                   presentingCreateWizard: $presentingCreateWizard)
        }
        .navigationTitle(basicWidgetSettingsTitle(createWidgetWizard))
        .toolbar {
            CloseToolbar(presenting: $presentingCreateWizard)
        }
    }
}
