import CoreGraphics
import Foundation
import ImageIO

private struct IconImage {
    let filename: String
    let pixels: Int
}

private let outputDirectory = URL(fileURLWithPath: "CodexConfigSwitcher/Assets.xcassets/AppIcon.appiconset")

private let images: [IconImage] = [
    IconImage(filename: "icon_16x16.png", pixels: 16),
    IconImage(filename: "icon_16x16@2x.png", pixels: 32),
    IconImage(filename: "icon_32x32.png", pixels: 32),
    IconImage(filename: "icon_32x32@2x.png", pixels: 64),
    IconImage(filename: "icon_128x128.png", pixels: 128),
    IconImage(filename: "icon_128x128@2x.png", pixels: 256),
    IconImage(filename: "icon_256x256.png", pixels: 256),
    IconImage(filename: "icon_256x256@2x.png", pixels: 512),
    IconImage(filename: "icon_512x512.png", pixels: 512),
    IconImage(filename: "icon_512x512@2x.png", pixels: 1024)
]

private func cgColor(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

private func fillRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, color: CGColor) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color)
    context.fillPath()
}

private func strokeRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, color: CGColor, lineWidth: CGFloat) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    context.strokePath()
}

private func drawIcon(size pixelSize: Int) -> CGImage {
    let side = CGFloat(pixelSize)
    let scale = side / 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    context.scaleBy(x: scale, y: scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let tileRect = CGRect(x: 54, y: 54, width: 916, height: 916)
    let tilePath = CGPath(roundedRect: tileRect, cornerWidth: 214, cornerHeight: 214, transform: nil)

    context.saveGState()
    context.addPath(tilePath)
    context.clip()

    let baseGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(34, 37, 118),
            cgColor(92, 74, 218),
            cgColor(40, 190, 219)
        ] as CFArray,
        locations: [0, 0.54, 1]
    )!
    context.drawLinearGradient(
        baseGradient,
        start: CGPoint(x: 96, y: 92),
        end: CGPoint(x: 940, y: 940),
        options: []
    )

    context.setBlendMode(.screen)
    context.setFillColor(cgColor(255, 255, 255, 0.14))
    context.fillEllipse(in: CGRect(x: 88, y: 110, width: 520, height: 400))
    context.setFillColor(cgColor(89, 242, 255, 0.16))
    context.fillEllipse(in: CGRect(x: 500, y: 488, width: 470, height: 430))
    context.restoreGState()

    context.addPath(tilePath)
    context.setStrokeColor(cgColor(255, 255, 255, 0.22))
    context.setLineWidth(4)
    context.strokePath()

    let glassRect = CGRect(x: 168, y: 150, width: 688, height: 724)
    let glassPath = CGPath(roundedRect: glassRect, cornerWidth: 148, cornerHeight: 148, transform: nil)

    context.saveGState()
    context.addPath(glassPath)
    context.clip()
    let glassGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(255, 255, 255, 0.43),
            cgColor(255, 255, 255, 0.12),
            cgColor(255, 255, 255, 0.22)
        ] as CFArray,
        locations: [0, 0.58, 1]
    )!
    context.drawLinearGradient(
        glassGradient,
        start: CGPoint(x: 178, y: 148),
        end: CGPoint(x: 850, y: 876),
        options: []
    )
    context.restoreGState()

    strokeRoundedRect(
        context,
        rect: glassRect,
        radius: 148,
        color: cgColor(255, 255, 255, 0.55),
        lineWidth: 7
    )

    let leftCard = CGRect(x: 250, y: 266, width: 250, height: 332)
    let rightCard = CGRect(x: 524, y: 426, width: 250, height: 332)

    context.setShadow(offset: CGSize(width: 0, height: 18), blur: 28, color: cgColor(15, 24, 78, 0.24))
    fillRoundedRect(context, rect: leftCard, radius: 44, color: cgColor(255, 255, 255, 0.78))
    fillRoundedRect(context, rect: rightCard, radius: 44, color: cgColor(255, 255, 255, 0.78))
    context.setShadow(offset: .zero, blur: 0, color: nil)

    strokeRoundedRect(context, rect: leftCard, radius: 44, color: cgColor(255, 255, 255, 0.76), lineWidth: 5)
    strokeRoundedRect(context, rect: rightCard, radius: 44, color: cgColor(255, 255, 255, 0.76), lineWidth: 5)

    let lineColor = cgColor(48, 78, 172, 0.58)
    let knobColor = cgColor(60, 117, 255, 0.9)
    for (index, y) in [340, 408, 476].enumerated() {
        let yPosition = CGFloat(y)
        context.setStrokeColor(lineColor)
        context.setLineWidth(22)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: 296, y: yPosition))
        context.addLine(to: CGPoint(x: 454, y: yPosition))
        context.strokePath()

        let knobX = index == 1 ? CGFloat(372) : CGFloat(320 + index * 86)
        context.setFillColor(knobColor)
        context.fillEllipse(in: CGRect(x: knobX - 22, y: yPosition - 22, width: 44, height: 44))
    }

    for (index, y) in [498, 566, 634].enumerated() {
        let yPosition = CGFloat(y)
        context.setStrokeColor(lineColor)
        context.setLineWidth(22)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: 570, y: yPosition))
        context.addLine(to: CGPoint(x: 728, y: yPosition))
        context.strokePath()

        let knobX = index == 0 ? CGFloat(690) : CGFloat(604 + index * 32)
        context.setFillColor(cgColor(45, 208, 219, 0.9))
        context.fillEllipse(in: CGRect(x: knobX - 22, y: yPosition - 22, width: 44, height: 44))
    }

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(cgColor(255, 255, 255, 0.88))
    context.setLineWidth(34)

    context.move(to: CGPoint(x: 386, y: 682))
    context.addLine(to: CGPoint(x: 514, y: 682))
    context.addLine(to: CGPoint(x: 514, y: 622))
    context.strokePath()

    context.move(to: CGPoint(x: 638, y: 314))
    context.addLine(to: CGPoint(x: 510, y: 314))
    context.addLine(to: CGPoint(x: 510, y: 374))
    context.strokePath()

    context.setFillColor(cgColor(255, 255, 255, 0.9))
    context.move(to: CGPoint(x: 346, y: 682))
    context.addLine(to: CGPoint(x: 408, y: 640))
    context.addLine(to: CGPoint(x: 408, y: 724))
    context.closePath()
    context.fillPath()

    context.move(to: CGPoint(x: 678, y: 314))
    context.addLine(to: CGPoint(x: 616, y: 272))
    context.addLine(to: CGPoint(x: 616, y: 356))
    context.closePath()
    context.fillPath()

    context.setFillColor(cgColor(255, 255, 255, 0.84))
    context.fillEllipse(in: CGRect(x: 744, y: 252, width: 58, height: 58))

    return context.makeImage()!
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for image in images {
    let icon = drawIcon(size: image.pixels)
    try writePNG(icon, to: outputDirectory.appendingPathComponent(image.filename))
}

print("Generated \(images.count) app icon images in \(outputDirectory.path)")
