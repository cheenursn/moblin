import SwiftUI

enum QuickButtonGroup: Int, CaseIterable {
    case capture = 1
    case cameraAndSound
    case scenesAndOverlays
    case effects
    case chat
    case connectionAndDevices
    case screen

    init(type: SettingsQuickButtonType) {
        switch type {
        case .stream, .record, .snapshot, .photoShoot, .previewStream, .instantReplay, .replay,
             .streamMarker, .live:
            self = .capture
        case .mic, .mute, .torch, .gimbalTracking, .cameraMan, .cameraLevel, .grid, .fourThree,
             .portrait, .image:
            self = .cameraAndSound
        case .sceneEditor, .widgets, .localOverlays, .browser, .interactiveBrowserWidgets,
             .reloadBrowserWidgets, .draw, .poll, .macros, .autoSceneSwitcher:
            self = .scenesAndOverlays
        case .luts, .beauty, .moblinInMouth, .twin, .triple, .sepia, .grayScale, .pixellate, .crt, .movie,
             .sparkle, .glasses, .blurText, .blurFaces, .whirlpool, .pinch, .privacy:
            self = .effects
        case .chat, .interactiveChat, .predefinedMessages, .moderation, .pauseTts, .skipCurrentTts:
            self = .chat
        case .blackScreen, .lockScreen:
            self = .screen
        default:
            self = .connectionAndDevices
        }
    }

    static let left: [QuickButtonGroup] = [.capture]
    static let right: [QuickButtonGroup] = [.cameraAndSound, .scenesAndOverlays, .effects]
    static let more: [QuickButtonGroup] = [.chat, .connectionAndDevices, .screen]
}

@MainActor
private func allQuickButtons(_ quickButtons: QuickButtons) -> [SettingsQuickButton] {
    quickButtons.pairs.flatMap { page in
        page.reversed().flatMap { pair in
            [pair.first] + (pair.second.map { [$0] } ?? [])
        }
    }
}

@MainActor
private func buttons(_ quickButtons: QuickButtons, in group: QuickButtonGroup) -> [SettingsQuickButton] {
    allQuickButtons(quickButtons).filter { QuickButtonGroup(type: $0.type) == group }
}

private struct QuickButtonsGridView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    @ObservedObject var quickButtonsSettings: SettingsQuickButtons
    let buttons: [SettingsQuickButton]
    let columns: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(controlBarButtonSize + 6), spacing: 6),
                                 count: columns),
                  alignment: .leading,
                  spacing: 6)
        {
            ForEach(buttons) { button in
                QuickButtonsInnerView(
                    model: model,
                    quickButtons: quickButtons,
                    quickButtonsSettings: quickButtonsSettings,
                    orientation: model.orientation,
                    button: button,
                    size: controlBarButtonSize,
                    nameSize: controlBarQuickButtonNameSize,
                    nameWidth: controlBarButtonSize
                )
            }
        }
    }
}

private struct GroupSeparatorView: View {
    var body: some View {
        Rectangle()
            .fill(.secondary)
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}

private struct QuickButtonGroupsView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    @ObservedObject var quickButtonsSettings: SettingsQuickButtons
    let groups: [QuickButtonGroup]
    let columns: Int

    var body: some View {
        let nonEmpty = groups.filter { !buttons(quickButtons, in: $0).isEmpty }
        ForEach(Array(nonEmpty.enumerated()), id: \.element) { index, group in
            if index > 0 {
                GroupSeparatorView()
            }
            QuickButtonsGridView(model: model,
                                 quickButtons: quickButtons,
                                 quickButtonsSettings: quickButtonsSettings,
                                 buttons: buttons(quickButtons, in: group),
                                 columns: columns)
        }
    }
}

struct LeftCaptureButtonsView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuickButtonGroupsView(model: model,
                                  quickButtons: quickButtons,
                                  quickButtonsSettings: model.database.quickButtonsGeneral,
                                  groups: QuickButtonGroup.left,
                                  columns: 3)
        }
    }
}

private struct MoreButtonView: View {
    @Binding var showingMore: Bool

    var body: some View {
        Button {
            showingMore.toggle()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: showingMore ? "chevron.up" : "ellipsis")
                    .frame(width: controlBarButtonSize, height: controlBarButtonSize)
                    .background(Circle().fill(Color(white: 0.25)))
                    .foregroundStyle(.white)
                Text(showingMore ? "Less" : "More")
                    .font(.system(size: controlBarQuickButtonNameSize))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct RightGroupedQuickButtonsView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    @ObservedObject var quickButtonsSettings: SettingsQuickButtons
    let columns: Int
    @State private var showingMore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuickButtonGroupsView(model: model,
                                  quickButtons: quickButtons,
                                  quickButtonsSettings: quickButtonsSettings,
                                  groups: QuickButtonGroup.right,
                                  columns: columns)
            GroupSeparatorView()
            MoreButtonView(showingMore: $showingMore)
            if showingMore {
                GroupSeparatorView()
                QuickButtonGroupsView(model: model,
                                      quickButtons: quickButtons,
                                      quickButtonsSettings: quickButtonsSettings,
                                      groups: QuickButtonGroup.more,
                                      columns: columns)
            }
        }
    }
}
