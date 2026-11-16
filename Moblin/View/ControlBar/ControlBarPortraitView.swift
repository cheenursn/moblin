import SwiftUI

@available(iOS 17, *)
@MainActor
private struct ControlBarPageScrollTargetBehavior: @MainActor ScrollTargetBehavior {
    let model: Model

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.y = controlBarScrollTargetBehavior(
            model: model,
            containerWidth: context.containerSize.height,
            targetPosition: target.rect.minY
        )
    }
}

private struct QuickButtonsView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    @ObservedObject var quickButtonsSettings: SettingsQuickButtons
    let pairs: [QuickButtonPair]
    let height: Double

    private func buttonSize() -> Double {
        if quickButtonsSettings.bigButtons {
            controlBarQuickButtonSingleQuickButtonSize
        } else {
            controlBarButtonSize
        }
    }

    var body: some View {
        HStack {
            ForEach(pairs.reversed()) { pair in
                if quickButtonsSettings.twoColumns {
                    VStack(alignment: .trailing) {
                        QuickButtonsInnerView(
                            model: model,
                            quickButtons: quickButtons,
                            quickButtonsSettings: quickButtonsSettings,
                            orientation: model.orientation,
                            button: pair.first,
                            size: buttonSize(),
                            nameSize: buttonSize(),
                            nameWidth: buttonSize()
                        )
                        if let second = pair.second {
                            QuickButtonsInnerView(
                                model: model,
                                quickButtons: quickButtons,
                                quickButtonsSettings: quickButtonsSettings,
                                orientation: model.orientation,
                                button: second,
                                size: buttonSize(),
                                nameSize: buttonSize(),
                                nameWidth: buttonSize()
                            )
                        } else {
                            QuickButtonPlaceholderImage(size: buttonSize())
                        }
                    }
                } else {
                    QuickButtonsInnerView(
                        model: model,
                        quickButtons: quickButtons,
                        quickButtonsSettings: quickButtonsSettings,
                        orientation: model.orientation,
                        button: pair.first,
                        size: buttonSize(),
                        nameSize: buttonSize(),
                        nameWidth: buttonSize()
                    )
                    .frame(height: height - 10)
                    if let second = pair.second {
                        QuickButtonsInnerView(
                            model: model,
                            quickButtons: quickButtons,
                            quickButtonsSettings: quickButtonsSettings,
                            orientation: model.orientation,
                            button: second,
                            size: buttonSize(),
                            nameSize: buttonSize(),
                            nameWidth: buttonSize()
                        )
                        .frame(height: height - 10)
                    }
                }
            }
        }
    }
}

struct ControlBarPortraitPageView: View {
    let model: Model
    let quickButtons: QuickButtons
    @ObservedObject var quickButtonsSettings: SettingsQuickButtons
    let pairs: [QuickButtonPair]
    var height: Double
    @State private var scrollViewWidth: CGFloat = 0

    var body: some View {
        ScrollViewReader { scrollProxy in
            EndAnchoredScrollView(axis: .horizontal) {
                QuickButtonsView(model: model,
                                 quickButtons: quickButtons,
                                 quickButtonsSettings: quickButtonsSettings,
                                 pairs: pairs,
                                 height: height)
                    .frame(minWidth: scrollViewWidth, maxHeight: .infinity, alignment: .topTrailing)
                    .controlBarDoubleTapArea(model: model)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                scrollViewWidth = width
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(!quickButtonsSettings.enableScroll)
            .filterQuickButtonsOnOverscroll(model: model, axis: .horizontal)
            .scrollToQuickButton(model: model, quickButtons: quickButtons, pairs: pairs, proxy: scrollProxy)
        }
    }
}

private struct IconAndSettingsView: View {
    let model: Model
    @ObservedObject var store: Store

    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.toggleShowingPanel(type: nil, panel: .store)
            } label: {
                Image("BhoomiCreativesLogo")
                    .interpolation(.high)
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 4)
                    .offset(x: 2)
                    .frame(width: controlBarButtonSize, height: controlBarButtonSize)
            }
            .buttonStyle(.plain)
            Button {
                model.toggleShowingPanel(type: nil, panel: .settings)
            } label: {
                SettingsButtonImage()
            }
            .buttonStyle(.plain)
            .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
    }
}

private struct MainPageView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    let quickButtonsSettings: SettingsQuickButtons
    @ObservedObject var status: StatusOther
    var height: Double
    @State var presentingThermalState: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ControlBarPortraitPageView(model: model,
                                       quickButtons: quickButtons,
                                       quickButtonsSettings: quickButtonsSettings,
                                       pairs: quickButtons.pairs[0],
                                       height: height)
                .padding([.top, .leading], 5)
                .padding(.trailing, 0)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Button {
                        presentingThermalState.toggle()
                    } label: {
                        ThermalStateView(thermalState: status.thermalState)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
                .padding(.top, 3)
                .padding(.trailing, 5)
                .padding(.leading, 0)
                IconAndSettingsView(model: model, store: model.store)
                StreamButton(show: model.show)
                    .padding(.top, 10)
                    .padding(.horizontal, 5)
            }
            .padding(.leading, 0)
            .frame(width: controlBarWidthDefault)
            .padding(.trailing, isUnfoldedInnerDisplay() ? 18 : 0)
            .sheet(isPresented: $presentingThermalState) {
                ThermalStateSheetView(presenting: $presentingThermalState)
            }
        }
    }
}

private struct PagesView: View {
    let model: Model
    @ObservedObject var quickButtons: QuickButtons
    @ObservedObject var pages: QuickButtonsPages
    let quickButtonsSettings: SettingsQuickButtons
    var height: Double

    var body: some View {
        if #available(iOS 17, *) {
            ScrollView(.vertical) {
                LazyVStack {
                    Group {
                        MainPageView(model: model,
                                     quickButtons: quickButtons,
                                     quickButtonsSettings: quickButtonsSettings,
                                     status: model.statusOther,
                                     height: height)
                            .id(1)
                        ForEach(1 ..< controlBarPages, id: \.self) { page in
                            if !quickButtons.pairs[page].isEmpty {
                                ControlBarPortraitPageView(model: model,
                                                           quickButtons: quickButtons,
                                                           quickButtonsSettings: quickButtonsSettings,
                                                           pairs: quickButtons.pairs[page],
                                                           height: height)
                                    .id(page + 1)
                                    .padding([.top, .leading, .trailing], 5)
                            }
                        }
                    }
                    .containerRelativeFrame(.vertical, count: 1, spacing: 0, alignment: .top)
                    .controlBarDoubleTapArea(model: model)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(ControlBarPageScrollTargetBehavior(model: model))
            .scrollIndicators(.never)
            .scrollPosition(id: $pages.activePage)
            .ignoresSafeArea(.all, edges: [.bottom])
        } else {
            ScrollView(.vertical) {
                MainPageView(model: model,
                             quickButtons: quickButtons,
                             quickButtonsSettings: quickButtonsSettings,
                             status: model.statusOther,
                             height: height)
                    .controlBarDoubleTapArea(model: model)
            }
            .scrollIndicators(.never)
            .ignoresSafeArea(.all, edges: [.bottom])
        }
    }
}

private struct TallGroupedView: View {
    let model: Model
    @ObservedObject var status: StatusOther

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    RightGroupedQuickButtonsView(
                        model: model,
                        quickButtons: model.quickButtons,
                        quickButtonsSettings: model.database.quickButtonsGeneral,
                        columns: max(Int(geometry.size.width / (controlBarButtonSize + 12)), 1),
                        groups: [.capture] + QuickButtonGroup.right
                    )
                    .padding(.top, 5)
                    .controlBarDoubleTapArea(model: model)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.leading, 10)
            VStack(spacing: 0) {
                IconAndSettingsView(model: model, store: model.store)
                RightOverlayBottomView(database: model.database,
                                       show: model.database.show,
                                       streamOverlay: model.streamOverlay,
                                       zoom: model.zoom,
                                       width: 160)
                    .padding(.top, 8)
                StreamButton(show: model.show)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
            }
            .frame(width: 160)
            .padding(.trailing, 18)
        }
    }
}

struct ControlBarPortraitView: View {
    let model: Model
    @ObservedObject var quickButtons: SettingsQuickButtons
    @ObservedObject var orientation: Orientation

    var body: some View {
        if orientation.unfoldedPosture == .tallCameraTop {
            TallGroupedView(model: model, status: model.statusOther)
                .frame(height: 380)
                .controlBarFilter(model: model)
        } else {
            pages
        }
    }

    private var pages: some View {
        PagesView(model: model,
                  quickButtons: model.quickButtons,
                  pages: model.quickButtonsPages,
                  quickButtonsSettings: model.database.quickButtonsGeneral,
                  height: controlBarWidth(quickButtons: quickButtons))
            .frame(height: controlBarWidth(quickButtons: quickButtons))
            .controlBarFilter(model: model)
    }
}
