import AVFoundation
import UIKit

enum UnfoldedPosture {
    case wideCameraTop
    case tallCameraTop

    var cameraOrientation: AVCaptureVideoOrientation {
        switch self {
        case .wideCameraTop:
            .portrait
        case .tallCameraTop:
            .landscapeRight
        }
    }

    var isTall: Bool {
        self == .tallCameraTop
    }

    var fillsHeightAlignedLeft: Bool {
        self == .wideCameraTop
    }

    var packsQuickButtonPages: Bool {
        self == .wideCameraTop
    }
}

@MainActor
private func applicationWindowScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.session.role == .windowApplication }
}

@MainActor
func isUnfoldedInnerDisplay() -> Bool {
    guard isPhone() else {
        return false
    }
    let bounds = applicationWindowScene()?.screen.bounds ?? UIScreen.main.bounds
    return min(bounds.width, bounds.height) >= 600
}

@MainActor
func isWindowPortrait() -> Bool {
    guard let scene = applicationWindowScene() else {
        return false
    }
    switch scene.effectiveGeometry.interfaceOrientation {
    case .portrait, .portraitUpsideDown:
        return true
    case .landscapeLeft, .landscapeRight:
        return false
    default:
        let size = scene.coordinateSpace.bounds.size
        return size.height > size.width
    }
}

extension Model {
    func updateUnfoldedPosture() {
        let posture: UnfoldedPosture? = if isUnfoldedInnerDisplay() {
            isWindowPortrait() ? .tallCameraTop : .wideCameraTop
        } else {
            nil
        }
        if orientation.unfoldedPosture != posture {
            orientation.unfoldedPosture = posture
        }
        let unsupported = posture != nil
            && [.portraitUpsideDown, .landscapeRight].contains(UIDevice.current.orientation)
        if orientation.unsupportedUnfoldedPosition != unsupported {
            orientation.unsupportedUnfoldedPosition = unsupported
        }
    }

    func innerDisplayCameraOrientation() -> AVCaptureVideoOrientation? {
        guard isUnfoldedInnerDisplay() else {
            return nil
        }
        return orientation.unfoldedPosture?.cameraOrientation ?? .portrait
    }

    func handleDisplayChanged() {
        guard media != nil else {
            return
        }
        updateOrientationLock()
        updateOrientation()
    }
}

extension StreamOverlay {
    var showingWidePane: Bool {
        showingReplay || showingBeauty || showingVideoPreview
    }
}

extension Model {
    func tallControlBarHeight() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.session.role == .windowApplication })?
            .windows.first
        else {
            return 380
        }
        let insets = window.safeAreaInsets
        let width = window.bounds.width
        let videoHeight = width / stream.dimensions().aspectRatio()
        let available = window.bounds.height - insets.top - insets.bottom - videoHeight
        return min(max(available.rounded(.down) - 2, 200), 600)
    }
}
