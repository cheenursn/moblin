import SwiftUI

struct BhoomiTextStyleSettingsView: View {
    @ObservedObject var style: SettingsBhoomiTextStyle
    let onChange: () -> Void

    var body: some View {
        Picker("Font", selection: $style.design) {
            ForEach(SettingsFontDesign.allCases, id: \.self) {
                Text($0.toString())
            }
        }
        .onChange(of: style.design) { _ in
            onChange()
        }
        Picker("Weight", selection: $style.weight) {
            ForEach(SettingsBhoomiFontWeight.allCases, id: \.self) {
                Text($0.toString())
            }
        }
        .onChange(of: style.weight) { _ in
            onChange()
        }
        HStack {
            Text("Size")
            Slider(value: $style.sizePercent, in: 50 ... 200, step: 5) { editing in
                if !editing {
                    onChange()
                }
            }
            Text("\(Int(style.sizePercent))%")
                .frame(width: 50, alignment: .trailing)
                .monospacedDigit()
        }
        Picker("Alignment", selection: $style.alignment) {
            ForEach(SettingsHorizontalAlignment.allCases, id: \.self) {
                Text($0.toString())
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: style.alignment) { _ in
            onChange()
        }
    }
}
