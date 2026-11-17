import SwiftUI

struct TallRightColumnView: View {
    let model: Model
    let database: Database
    @ObservedObject var show: SettingsShow
    @ObservedObject var zoom: Zoom
    let width: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            if show.zoomPresets, zoom.hasZoom {
                StreamOverlayRightZoomPresetSelctorView(model: model, zoom: zoom, width: width)
            }
            StreamOverlayRightSceneVSelectorView(database: database,
                                                 sceneSelector: model.sceneSelector,
                                                 width: width,
                                                 segmentWidth: width - 10)
        }
        .frame(width: width)
    }
}

private struct TallSliderZoneView: View {
    let model: Model
    @ObservedObject var database: Database
    @ObservedObject var show: SettingsShow
    @ObservedObject var streamOverlay: StreamOverlay
    @ObservedObject var zoom: Zoom

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            StreamOverlayRightFaceView(model: model, face: database.face)
            if streamOverlay.showingPixellate {
                StreamOverlayRightPixellateView(model: model, database: database)
            }
            if streamOverlay.showingWhirlpool {
                StreamOverlayRightWhirlpoolView(model: model, database: database)
            }
            if streamOverlay.showingPinch {
                StreamOverlayRightPinchView(model: model, database: database)
            }
            if streamOverlay.isTorchOn, !streamOverlay.isFrontCameraSelected {
                StreamOverlayRightTorchView(model: model, database: database)
            }
            if show.zoomSlider, zoom.hasZoom {
                StreamOverlayRightZoomSliderView(model: model)
                    .frame(width: sliderWidth)
            }
        }
    }
}

private struct TallPaneZoneView: View {
    let model: Model
    @ObservedObject var database: Database
    @ObservedObject var streamOverlay: StreamOverlay

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if streamOverlay.showMediaPlayerControls {
                StreamOverlayRightMediaPlayerControlsView(model: model, mediaPlayer: model.mediaPlayerPlayer)
            }
            if streamOverlay.showingReplay {
                StreamOverlayRightReplayView(model: model, replay: model.replay, orientation: model.orientation)
            } else if streamOverlay.showingBeauty {
                StreamOverlayRightBeautyView(model: model, beauty: database.beauty)
            } else if streamOverlay.showingVideoPreview {
                StreamOverlayRightVideoPreviewView(model: model,
                                                   orientation: model.orientation,
                                                   videoPreview: model.videoPreview)
            }
        }
    }
}

struct TallVideoControlsView: View {
    let model: Model
    @ObservedObject var database: Database
    let show: SettingsShow
    @ObservedObject var streamOverlay: StreamOverlay
    let zoom: Zoom

    var body: some View {
        if !model.showDrawOnStream, database.appMode == .streaming {
            VStack(spacing: 8) {
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 8) {
                    TallSliderZoneView(model: model,
                                       database: database,
                                       show: show,
                                       streamOverlay: streamOverlay,
                                       zoom: zoom)
                    Spacer(minLength: 0)
                    TallPaneZoneView(model: model, database: database, streamOverlay: streamOverlay)
                }
                .padding(.leading, 12)
                .padding(.trailing, 80)
                if streamOverlay.showingCamera {
                    StreamOverlayRightCameraSettingsControlView(model: model,
                                                                camera: model.camera,
                                                                show: model.camera.show)
                }
            }
            .padding(.top, 70)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
