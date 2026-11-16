import CoreImage
import MetalPetal
import UIKit

final class BhoomiBrandingEffect: VideoEffect, @unchecked Sendable {
    private let widget: SettingsWidgetBhoomiBranding
    private var newSceneWidget: SettingsSceneWidget?
    private var sceneWidget: SettingsSceneWidget?
    private var size: CGSize = .zero
    private var cardImage: EffectImageCiImage?

    init(widget: SettingsWidgetBhoomiBranding) {
        self.widget = widget
        super.init()
    }

    func setSceneWidget(sceneWidget: SettingsSceneWidget) {
        processorPipelineQueue.async {
            self.newSceneWidget = sceneWidget
        }
    }

    override func execute(_ image: CIImage, _ info: VideoEffectInfo) -> CIImage {
        guard let newSceneWidget else {
            return image
        }
        update(newSceneWidget: newSceneWidget, size: image.extent.size)
        guard let cardImage else {
            return image
        }
        return applyEffectsResizeMirrorMove(cardImage.getCiImage(),
                                            newSceneWidget,
                                            false,
                                            image.extent,
                                            info)
            .composited(over: image)
    }

    override func executeMetalPetal(_ image: MTIImage, _ info: VideoEffectInfo) -> MTIImage {
        guard let newSceneWidget else {
            return image
        }
        update(newSceneWidget: newSceneWidget, size: image.extent.size)
        guard let cardImage else {
            return image
        }
        return applyEffectsResizeMirrorMoveMetalPetal(cardImage.getMetalPetalImage(),
                                                      newSceneWidget,
                                                      false,
                                                      image,
                                                      info)
    }

    private func update(newSceneWidget: SettingsSceneWidget, size: CGSize) {
        guard newSceneWidget.layout.extent() != sceneWidget?.layout.extent() || size != self.size
            || cardImage == nil
        else {
            return
        }
        sceneWidget = newSceneWidget
        self.size = size
        guard let cgImage = renderCard().cgImage else {
            return
        }
        cardImage = CIImage(cgImage: cgImage).toEffectImage(isOpaque: false)
    }

    private func renderCard() -> UIImage {
        let cardSize = widget.cardSize()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: cardSize, format: format).image { context in
            let rect = CGRect(origin: .zero, size: cardSize)
            let background = UIBezierPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerRadius: 40)
            widget.backgroundColor.uiColor().setFill()
            background.fill()
            widget.accentColor.uiColor().setStroke()
            background.lineWidth = 10
            background.stroke()
            var y = 20.0
            if !widget.header.isEmpty {
                drawText(widget.header, y: y, height: 90, fontSize: 56, weight: .bold, width: cardSize.width)
                y += 90
            }
            if widget.showLogo, let logo = UIImage(named: "BhoomiCreativesLogo") {
                let side = 380.0
                let logoRect = CGRect(x: (cardSize.width - side) / 2, y: y + 10, width: side, height: side)
                context.cgContext.saveGState()
                UIBezierPath(ovalIn: logoRect).addClip()
                logo.draw(in: logoRect)
                context.cgContext.restoreGState()
                y += 400
            }
            if !widget.footer.isEmpty {
                drawText(widget.footer,
                         y: y,
                         height: 70,
                         fontSize: 40,
                         weight: .semibold,
                         width: cardSize.width)
            }
        }
    }

    private func drawText(_ text: String,
                          y: Double,
                          height: Double,
                          fontSize: Double,
                          weight: UIFont.Weight,
                          width: Double)
    {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
            .foregroundColor: widget.textColor.uiColor(),
            .paragraphStyle: paragraph,
        ]
        let textHeight = (text as NSString).size(withAttributes: attributes).height
        let rect = CGRect(x: 30, y: y + (height - textHeight) / 2, width: width - 60, height: textHeight)
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}
