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
        let rendered = widget.style == .frame ? renderFrame(size: size) : renderCard()
        guard let cgImage = rendered.cgImage else {
            return
        }
        cardImage = CIImage(cgImage: cgImage).toEffectImage(isOpaque: false)
    }

    private func renderFrame(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let side = min(size.width, size.height)
            let border = (side * 0.012).rounded()
            let topBand = (size.height * 0.12).rounded()
            let bottomBand = (size.height * 0.08).rounded()
            widget.backgroundColor.uiColor().setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: topBand)).fill()
            if !widget.footer.isEmpty {
                UIBezierPath(rect: CGRect(x: 0,
                                          y: size.height - bottomBand,
                                          width: size.width,
                                          height: bottomBand)).fill()
            }
            let frame = UIBezierPath(rect: CGRect(origin: .zero, size: size).insetBy(dx: border / 2, dy: border / 2))
            frame.lineWidth = border
            widget.accentColor.uiColor().setStroke()
            frame.stroke()
            var titleX = border * 3
            if widget.showLogo, let logo = UIImage(named: "BhoomiCreativesLogo") {
                let logoSide = topBand - border * 2.5
                let logoRect = CGRect(x: border * 2, y: (topBand - logoSide) / 2, width: logoSide, height: logoSide)
                context.cgContext.saveGState()
                UIBezierPath(ovalIn: logoRect).addClip()
                logo.draw(in: logoRect)
                context.cgContext.restoreGState()
                titleX = logoRect.maxX + border * 2
            }
            drawLine(widget.header,
                     in: CGRect(x: titleX, y: 0, width: size.width - titleX - border * 3, height: topBand),
                     style: widget.titleStyle,
                     baseSize: topBand * 0.42)
            if !widget.footer.isEmpty {
                drawLine(widget.footer,
                         in: CGRect(x: border * 3,
                                    y: size.height - bottomBand,
                                    width: size.width - border * 6,
                                    height: bottomBand),
                         style: widget.footerStyle,
                         baseSize: bottomBand * 0.45)
            }
        }
    }

    private func drawLine(_ text: String,
                          in rect: CGRect,
                          style: SettingsBhoomiTextStyle,
                          baseSize: Double)
    {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = style.textAlignment()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font(baseSize: baseSize),
            .foregroundColor: widget.textColor.uiColor(),
            .paragraphStyle: paragraph,
        ]
        let height = (text as NSString).size(withAttributes: attributes).height
        (text as NSString).draw(in: CGRect(x: rect.minX,
                                           y: rect.midY - height / 2,
                                           width: rect.width,
                                           height: height),
                                withAttributes: attributes)
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
                drawLine(widget.header,
                         in: CGRect(x: 30, y: y, width: cardSize.width - 60, height: 90),
                         style: widget.titleStyle,
                         baseSize: 56)
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
                drawLine(widget.footer,
                         in: CGRect(x: 30, y: y, width: cardSize.width - 60, height: 70),
                         style: widget.footerStyle,
                         baseSize: 40)
            }
        }
    }
}
