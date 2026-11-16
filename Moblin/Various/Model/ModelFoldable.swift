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
    guard isPhone(), let screen = applicationWindowScene()?.screen else {
        return false
    }
    return min(screen.bounds.width, screen.bounds.height) >= 600
}

@MainActor
func isWindowPortrait() -> Bool {
    guard let size = applicationWindowScene()?.coordinateSpace.bounds.size else {
        return false
    }
    return size.height > size.width
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
