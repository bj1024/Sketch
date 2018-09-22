//
//  SketchTool.swift
//  Sketch
//
//  Created by daihase on 04/06/2018.
//  Copyright (c) 2018 daihase. All rights reserved.
//

import UIKit

protocol SketchTool {
    var lineWidth: CGFloat { get set }
    var lineColor: UIColor { get set }
    var lineAlpha: CGFloat { get set }

    func setInitialPoint(_ firstPoint: CGPoint)
    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint)
    func draw()
}

public enum PenType {
    case normal
    case blur
    case neon
}

class PenTool: UIBezierPath, SketchTool {
    var path: CGMutablePath
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var drawingPenType: PenType

    override init() {
        path = CGMutablePath.init()
        lineColor = .black
        lineAlpha = 0
        drawingPenType = .normal
        super.init()
        lineCapStyle = CGLineCap.round
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setInitialPoint(_ firstPoint: CGPoint) {}

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {}

    func createBezierRenderingBox(_ previousPoint2: CGPoint, widhPreviousPoint previousPoint1: CGPoint, withCurrentPoint cpoint: CGPoint) -> CGRect {
        let mid1 = middlePoint(previousPoint1, previousPoint2: previousPoint2)
        let mid2 = middlePoint(cpoint, previousPoint2: previousPoint1)
        let subpath = CGMutablePath.init()

        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint1.x, y: previousPoint1.y))
        path.addPath(subpath)
        
        var boundingBox: CGRect = subpath.boundingBox
        boundingBox.origin.x -= lineWidth * 2.0
        boundingBox.origin.y -= lineWidth * 2.0
        boundingBox.size.width += lineWidth * 4.0
        boundingBox.size.height += lineWidth * 4.0

        return boundingBox
    }

    private func middlePoint(_ previousPoint1: CGPoint, previousPoint2: CGPoint) -> CGPoint {
        return CGPoint(x: (previousPoint1.x + previousPoint2.x) * 0.5, y: (previousPoint1.y + previousPoint2.y) * 0.5)
    }
    
    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
            switch drawingPenType {
            case .normal:
                context.addPath(path)
                context.setLineCap(.round)
                context.setLineWidth(lineWidth)
                context.setStrokeColor(lineColor.cgColor)
                context.setBlendMode(.normal)
                context.setAlpha(lineAlpha)
                context.strokePath()
            case .blur:
                context.addPath(path)
                context.setLineCap(.round)
                context.setLineWidth(lineWidth)
                context.setStrokeColor(lineColor.cgColor)
                context.setShadow(offset: CGSize(width: 0, height: 0), blur: lineWidth / 1.25, color: lineColor.cgColor)
                context.setAlpha(lineAlpha)
                context.strokePath()
            case .neon:
                let shadowColor = lineColor
                let transparentShadowColor = shadowColor.withAlphaComponent(lineAlpha)

                context.addPath(path)
                context.setLineCap(.round)
                context.setLineWidth(lineWidth)
                context.setStrokeColor(UIColor.white.cgColor)
                context.setShadow(offset: CGSize(width: 0, height: 0), blur: lineWidth / 1.25, color: transparentShadowColor.cgColor)
                context.setBlendMode(.screen)
                context.strokePath()
            }
    }
}

class EraserTool: PenTool {
    override func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.addPath(path)
        context.setLineCap(.round)
        context.setLineWidth(lineWidth)
        context.setBlendMode(.clear)
        context.strokePath()
        context.restoreGState()
    }
}

class LineTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var firstPoint: CGPoint
    var lastPoint: CGPoint

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        self.lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(lineColor.cgColor)
        context.setLineCap(.square)
        context.setLineWidth(lineWidth)
        context.setAlpha(lineAlpha)
        context.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        context.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        context.strokePath()
    }

    func angleWithFirstPoint(first: CGPoint, second: CGPoint) -> Float {
        let dx: CGFloat = second.x - first.x
        let dy: CGFloat = second.y - first.y
        let angle = atan2f(Float(dy), Float(dx))

        return angle
    }

    func pointWithAngle(angle: CGFloat, distance: CGFloat) -> CGPoint {
        let x = Float(distance) * cosf(Float(angle))
        let y = Float(distance) * sinf(Float(angle))

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

class ArrowTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var firstPoint: CGPoint
    var lastPoint: CGPoint

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .black
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
    }

    func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        lastPoint = endPoint
    }

    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let capHeight = lineWidth * 4.0
        let angle = angleWithFirstPoint(first: firstPoint, second: lastPoint)
        var point1 = pointWithAngle(angle: CGFloat(angle + Float(6.0 * .pi / 8.0)), distance: capHeight)
        var point2 = pointWithAngle(angle:  CGFloat(angle - Float(6.0 * .pi / 8.0)), distance: capHeight)
        let endPointOffset = pointWithAngle(angle: CGFloat(angle), distance: lineWidth)

        context.setStrokeColor(lineColor.cgColor)
        context.setLineCap(.square)
        context.setLineWidth(lineWidth)
        context.setAlpha(lineAlpha)
        context.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        context.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))

        point1 = CGPoint(x: lastPoint.x + point1.x, y: lastPoint.y + point1.y)
        point2 = CGPoint(x: lastPoint.x + point2.x, y: lastPoint.y + point2.y)

        context.move(to: CGPoint(x: point1.x, y: point1.y))
        context.addLine(to: CGPoint(x: lastPoint.x + endPointOffset.x, y: lastPoint.y + endPointOffset.y))
        context.addLine(to: CGPoint(x: point2.x, y: point2.y))
        context.strokePath()
    }

    func angleWithFirstPoint(first: CGPoint, second: CGPoint) -> Float {
        let dx: CGFloat = second.x - first.x
        let dy: CGFloat = second.y - first.y
        let angle = atan2f(Float(dy), Float(dx))

        return angle
    }

    func pointWithAngle(angle: CGFloat, distance: CGFloat) -> CGPoint {
        let x = Float(distance) * cosf(Float(angle))
        let y = Float(distance) * sinf(Float(angle))

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

class RectTool: SketchTool {
    var lineWidth: CGFloat
    var lineAlpha: CGFloat
    var lineColor: UIColor
    var firstPoint: CGPoint
    var lastPoint: CGPoint
    var isFill: Bool

    init() {
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
        isFill = false
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        self.lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let rectToFill = CGRect(x: firstPoint.x, y: firstPoint.y, width: lastPoint.x - self.firstPoint.x, height: lastPoint.y - firstPoint.y)
        
        context.setAlpha(lineAlpha)
        if self.isFill {
            context.setFillColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.fill(rectToFill)
        } else {
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(lineWidth)
            UIGraphicsGetCurrentContext()!.stroke(rectToFill)
        }
    }
}

class EllipseTool: SketchTool {
    var eraserWidth: CGFloat
    var lineWidth: CGFloat
    var lineAlpha: CGFloat
    var lineColor: UIColor
    var firstPoint: CGPoint
    var lastPoint: CGPoint
    var isFill: Bool

    init() {
        eraserWidth = 0
        lineWidth = 1.0
        lineAlpha = 1.0
        lineColor = .blue
        firstPoint = CGPoint(x: 0, y: 0)
        lastPoint = CGPoint(x: 0, y: 0)
        isFill = false
    }

    internal func setInitialPoint(_ firstPoint: CGPoint) {
        self.firstPoint = firstPoint
    }

    internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
        lastPoint = endPoint
    }

    internal func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setAlpha(lineAlpha)
        context.setLineWidth(lineWidth)
        let rectToFill = CGRect(x: firstPoint.x, y: firstPoint.y, width: lastPoint.x - self.firstPoint.x, height: lastPoint.y - firstPoint.y)
        if self.isFill {
            context.setFillColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.fillEllipse(in: rectToFill)
        } else {
            context.setStrokeColor(lineColor.cgColor)
            UIGraphicsGetCurrentContext()!.strokeEllipse(in: rectToFill)
        }
    }
}

class StampTool: SketchTool {
    var lineWidth: CGFloat
    var lineColor: UIColor
    var lineAlpha: CGFloat
    var touchPoint: CGPoint
    var stampImage: UIImage?

    init() {
        lineWidth = 0
        lineColor = .blue
        lineAlpha = 0
        touchPoint = CGPoint(x: 0, y: 0)
    }

    func setInitialPoint(_ firstPoint: CGPoint) {
        touchPoint = firstPoint
    }

    func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {}

    func setStampImage(image: UIImage?) {
        if let image = image {
            stampImage = image
        }
    }

    func getStamImage() -> UIImage? {
        return stampImage
    }

    func draw() {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setShadow(offset: CGSize(width :0, height: 0), blur: 0, color: nil)

        if let image = self.getStamImage() {
            let imageX = touchPoint.x  - (image.size.width / 2.0)
            let imageY = touchPoint.y - (image.size.height / 2.0)
            let imageWidth = image.size.width
            let imageHeight = image.size.height

            image.draw(in: CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight))
        }
    }
}

class KinokoTool: SketchTool {
	var eraserWidth: CGFloat
	var lineWidth: CGFloat
	var lineAlpha: CGFloat
	var lineColor: UIColor
	var firstPoint: CGPoint
	var lastPoint: CGPoint

	init() {
		eraserWidth = 0
		lineWidth = 1.0
		lineAlpha = 1.0
		lineColor = .blue
		firstPoint = CGPoint(x: 0, y: 0)
		lastPoint = CGPoint(x: 0, y: 0)
	}

	internal func setInitialPoint(_ firstPoint: CGPoint) {
		self.firstPoint = firstPoint
	}

	internal func moveFromPoint(_ startPoint: CGPoint, toPoint endPoint: CGPoint) {
		lastPoint = endPoint
	}

	internal func draw() {
		guard let ctx = UIGraphicsGetCurrentContext() else { return }

		let rect = CGRect(x: min(firstPoint.x,lastPoint.x),
						  y: min(firstPoint.y,lastPoint.y),
						  width: abs(firstPoint.x - lastPoint.x),
						  height: abs(firstPoint.y - lastPoint.y))
		ctx.translateBy(x: rect.minX, y: rect.minY)
		let scalefactor:CGFloat = min(rect.width / 500.0 ,
									  rect.height / 500.0)
		ctx.scaleBy(x: scalefactor,y:scalefactor)

		/*  Shape   */
		let pathRef = CGMutablePath()
		pathRef.move(to: CGPoint(x: 103.872, y: 253.301))
		pathRef.addCurve(to: CGPoint(x: 121.872, y: 264.504), control1: CGPoint(x: 111.76, y: 253.38), control2: CGPoint(x: 117.189, y: 258.83))
		pathRef.addCurve(to: CGPoint(x: 105.133, y: 330.801), control1: CGPoint(x: 108.797, y: 283.835), control2: CGPoint(x: 105.393, y: 307.922))
		pathRef.addCurve(to: CGPoint(x: 115.543, y: 385.722), control1: CGPoint(x: 105.272, y: 349.533), control2: CGPoint(x: 107.722, y: 368.529))
		pathRef.addCurve(to: CGPoint(x: 118.551, y: 391.476), control1: CGPoint(x: 116.439, y: 387.692), control2: CGPoint(x: 117.548, y: 389.558))
		pathRef.addCurve(to: CGPoint(x: 121.872, y: 391.301), control1: CGPoint(x: 119.653, y: 391.245), control2: CGPoint(x: 118.568, y: 391.472))
		pathRef.addCurve(to: CGPoint(x: 154.111, y: 424.301), control1: CGPoint(x: 139.677, y: 391.301), control2: CGPoint(x: 154.111, y: 406.075))
		pathRef.addCurve(to: CGPoint(x: 121.872, y: 457.301), control1: CGPoint(x: 154.111, y: 442.526), control2: CGPoint(x: 139.677, y: 457.301))
		pathRef.addCurve(to: CGPoint(x: 89.634, y: 424.301), control1: CGPoint(x: 104.067, y: 457.301), control2: CGPoint(x: 89.634, y: 442.526))
		pathRef.addCurve(to: CGPoint(x: 93.525, y: 408.571), control1: CGPoint(x: 89.583, y: 418.763), control2: CGPoint(x: 91.105, y: 413.515))
		pathRef.addCurve(to: CGPoint(x: 95.284, y: 405.904), control1: CGPoint(x: 93.993, y: 407.614), control2: CGPoint(x: 94.698, y: 406.793))
		pathRef.addCurve(to: CGPoint(x: 69.133, y: 330.801), control1: CGPoint(x: 73.929, y: 391.395), control2: CGPoint(x: 69.401, y: 354.393))
		pathRef.addCurve(to: CGPoint(x: 103.872, y: 253.301), control1: CGPoint(x: 69.134, y: 287.999), control2: CGPoint(x: 84.687, y: 253.301))
		pathRef.addLine(to: CGPoint(x: 103.872, y: 253.301))
		pathRef.closeSubpath()

		ctx.setFillColor(red: 0.969, green: 0.918, blue: 0.722, alpha: 1)
		ctx.addPath(pathRef)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef)
		ctx.strokePath()


		/*  Shape 2  */
		let pathRef2 = CGMutablePath()
		pathRef2.move(to: CGPoint(x: 395.261, y: 253.301))
		pathRef2.addCurve(to: CGPoint(x: 377.261, y: 264.504), control1: CGPoint(x: 387.374, y: 253.38), control2: CGPoint(x: 381.944, y: 258.83))
		pathRef2.addCurve(to: CGPoint(x: 394, y: 330.801), control1: CGPoint(x: 390.337, y: 283.835), control2: CGPoint(x: 393.741, y: 307.922))
		pathRef2.addCurve(to: CGPoint(x: 383.591, y: 385.722), control1: CGPoint(x: 393.862, y: 349.533), control2: CGPoint(x: 391.411, y: 368.529))
		pathRef2.addCurve(to: CGPoint(x: 380.582, y: 391.476), control1: CGPoint(x: 382.695, y: 387.692), control2: CGPoint(x: 381.585, y: 389.558))
		pathRef2.addCurve(to: CGPoint(x: 377.261, y: 391.301), control1: CGPoint(x: 379.48, y: 391.245), control2: CGPoint(x: 380.566, y: 391.472))
		pathRef2.addCurve(to: CGPoint(x: 345.022, y: 424.301), control1: CGPoint(x: 359.456, y: 391.301), control2: CGPoint(x: 345.022, y: 406.075))
		pathRef2.addCurve(to: CGPoint(x: 377.261, y: 457.301), control1: CGPoint(x: 345.022, y: 442.526), control2: CGPoint(x: 359.456, y: 457.301))
		pathRef2.addCurve(to: CGPoint(x: 409.5, y: 424.301), control1: CGPoint(x: 395.066, y: 457.301), control2: CGPoint(x: 409.5, y: 442.526))
		pathRef2.addCurve(to: CGPoint(x: 405.609, y: 408.571), control1: CGPoint(x: 409.55, y: 418.763), control2: CGPoint(x: 408.029, y: 413.515))
		pathRef2.addCurve(to: CGPoint(x: 403.849, y: 405.904), control1: CGPoint(x: 405.141, y: 407.614), control2: CGPoint(x: 404.436, y: 406.793))
		pathRef2.addCurve(to: CGPoint(x: 430, y: 330.801), control1: CGPoint(x: 425.205, y: 391.395), control2: CGPoint(x: 429.733, y: 354.393))
		pathRef2.addCurve(to: CGPoint(x: 395.261, y: 253.301), control1: CGPoint(x: 430, y: 287.999), control2: CGPoint(x: 414.447, y: 253.301))
		pathRef2.addLine(to: CGPoint(x: 395.261, y: 253.301))
		pathRef2.closeSubpath()

		ctx.setFillColor(red: 0.969, green: 0.918, blue: 0.722, alpha: 1)
		ctx.addPath(pathRef2)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef2)
		ctx.strokePath()


		/*  Shape 3  */
		let pathRef3 = CGMutablePath()
		pathRef3.move(to: CGPoint(x: 248.519, y: 441.301))
		pathRef3.addCurve(to: CGPoint(x: 168.039, y: 367.65), control1: CGPoint(x: 204.071, y: 441.301), control2: CGPoint(x: 168.039, y: 408.326))
		pathRef3.addCurve(to: CGPoint(x: 248.519, y: 294), control1: CGPoint(x: 168.039, y: 326.974), control2: CGPoint(x: 204.071, y: 294))
		pathRef3.addCurve(to: CGPoint(x: 329, y: 367.65), control1: CGPoint(x: 292.968, y: 294), control2: CGPoint(x: 329, y: 326.974))
		pathRef3.addCurve(to: CGPoint(x: 248.519, y: 441.301), control1: CGPoint(x: 329, y: 408.326), control2: CGPoint(x: 292.968, y: 441.301))
		pathRef3.closeSubpath()

		ctx.setFillColor(red: 0.969, green: 0.918, blue: 0.722, alpha: 1)
		ctx.addPath(pathRef3)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef3)
		ctx.strokePath()


		/*  Shape 4  */
		let pathRef4 = CGMutablePath()
		pathRef4.move(to: CGPoint(x: 250, y: 307))
		pathRef4.addCurve(to: CGPoint(x: 61.5, y: 161.5), control1: CGPoint(x: 145.894, y: 307), control2: CGPoint(x: 61.5, y: 241.857))
		pathRef4.addCurve(to: CGPoint(x: 250, y: 16), control1: CGPoint(x: 61.5, y: 81.143), control2: CGPoint(x: 145.894, y: 16))
		pathRef4.addCurve(to: CGPoint(x: 438.5, y: 161.5), control1: CGPoint(x: 354.106, y: 16), control2: CGPoint(x: 438.5, y: 81.143))
		pathRef4.addCurve(to: CGPoint(x: 250, y: 307), control1: CGPoint(x: 438.5, y: 241.857), control2: CGPoint(x: 354.106, y: 307))
		pathRef4.closeSubpath()

		ctx.setFillColor(red: 0.388, green: 0.482, blue: 0.906, alpha: 1)
		ctx.addPath(pathRef4)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef4)
		ctx.strokePath()


		/*  Shape 5  */
		let pathRef5 = CGMutablePath()
		pathRef5.move(to: CGPoint(x: 193.705, y: 203.454))
		pathRef5.addCurve(to: CGPoint(x: 168.039, y: 176.797), control1: CGPoint(x: 179.53, y: 203.454), control2: CGPoint(x: 168.039, y: 191.519))
		pathRef5.addCurve(to: CGPoint(x: 193.705, y: 150.141), control1: CGPoint(x: 168.039, y: 162.075), control2: CGPoint(x: 179.53, y: 150.141))
		pathRef5.addCurve(to: CGPoint(x: 219.371, y: 176.797), control1: CGPoint(x: 207.88, y: 150.141), control2: CGPoint(x: 219.371, y: 162.075))
		pathRef5.addCurve(to: CGPoint(x: 193.705, y: 203.454), control1: CGPoint(x: 219.371, y: 191.519), control2: CGPoint(x: 207.88, y: 203.454))
		pathRef5.closeSubpath()

		ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
		ctx.addPath(pathRef5)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef5)
		ctx.strokePath()


		/*  Shape 6  */
		let pathRef6 = CGMutablePath()
		pathRef6.move(to: CGPoint(x: 303.334, y: 203.454))
		pathRef6.addCurve(to: CGPoint(x: 277.668, y: 176.797), control1: CGPoint(x: 289.159, y: 203.454), control2: CGPoint(x: 277.668, y: 191.519))
		pathRef6.addCurve(to: CGPoint(x: 303.334, y: 150.141), control1: CGPoint(x: 277.668, y: 162.075), control2: CGPoint(x: 289.159, y: 150.141))
		pathRef6.addCurve(to: CGPoint(x: 329, y: 176.797), control1: CGPoint(x: 317.509, y: 150.141), control2: CGPoint(x: 329, y: 162.075))
		pathRef6.addCurve(to: CGPoint(x: 303.334, y: 203.454), control1: CGPoint(x: 329, y: 191.519), control2: CGPoint(x: 317.509, y: 203.454))
		pathRef6.closeSubpath()

		ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
		ctx.addPath(pathRef6)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef6)
		ctx.strokePath()


		/*  Shape 7  */
		let pathRef7 = CGMutablePath()
		pathRef7.move(to: CGPoint(x: 187.083, y: 171))
		pathRef7.addLine(to: CGPoint(x: 200.083, y: 171))
		pathRef7.addLine(to: CGPoint(x: 200.083, y: 188))
		pathRef7.addLine(to: CGPoint(x: 187.083, y: 188))
		pathRef7.addLine(to: CGPoint(x: 187.083, y: 171))
		pathRef7.closeSubpath()

		ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1)
		ctx.addPath(pathRef7)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef7)
		ctx.strokePath()


		/*  Shape 8  */
		let pathRef8 = CGMutablePath()
		pathRef8.move(to: CGPoint(x: 296.917, y: 171))
		pathRef8.addLine(to: CGPoint(x: 309.917, y: 171))
		pathRef8.addLine(to: CGPoint(x: 309.917, y: 188))
		pathRef8.addLine(to: CGPoint(x: 296.917, y: 188))
		pathRef8.addLine(to: CGPoint(x: 296.917, y: 171))
		pathRef8.closeSubpath()

		ctx.setFillColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1)
		ctx.addPath(pathRef8)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef8)
		ctx.strokePath()


		/*  Shape 9  */
		let pathRef9 = CGMutablePath()
		pathRef9.move(to: CGPoint(x: 250.454, y: 17))
		pathRef9.addCurve(to: CGPoint(x: 385.025, y: 59.763), control1: CGPoint(x: 298.426, y: 17.007), control2: CGPoint(x: 346.53, y: 30.663))
		pathRef9.addCurve(to: CGPoint(x: 370.202, y: 73.023), control1: CGPoint(x: 378.611, y: 66.202), control2: CGPoint(x: 377.835, y: 67.457))
		pathRef9.addCurve(to: CGPoint(x: 247.866, y: 106.454), control1: CGPoint(x: 335.415, y: 98.391), control2: CGPoint(x: 289.909, y: 105.874))
		pathRef9.addCurve(to: CGPoint(x: 112.975, y: 62.04), control1: CGPoint(x: 201.309, y: 105.578), control2: CGPoint(x: 147.276, y: 96.47))
		pathRef9.addCurve(to: CGPoint(x: 250.454, y: 17), control1: CGPoint(x: 151.29, y: 30.726), control2: CGPoint(x: 201.7, y: 17.467))
		pathRef9.closeSubpath()

		ctx.setFillColor(red: 0.984, green: 0.361, blue: 0.4, alpha: 1)
		ctx.addPath(pathRef9)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef9)
		ctx.strokePath()


		/*  Shape 10  */
		let pathRef10 = CGMutablePath()
		pathRef10.move(to: CGPoint(x: 438.336, y: 166))
		pathRef10.addCurve(to: CGPoint(x: 372.054, y: 271.54), control1: CGPoint(x: 436.091, y: 209.911), control2: CGPoint(x: 408.445, y: 248.359))
		pathRef10.addCurve(to: CGPoint(x: 366.077, y: 242.917), control1: CGPoint(x: 367.832, y: 262.592), control2: CGPoint(x: 366.346, y: 252.715))
		pathRef10.addCurve(to: CGPoint(x: 438.336, y: 166), control1: CGPoint(x: 366.42, y: 203.636), control2: CGPoint(x: 399.355, y: 169.648))
		pathRef10.closeSubpath()

		ctx.setFillColor(red: 0.984, green: 0.322, blue: 0.349, alpha: 1)
		ctx.addPath(pathRef10)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef10)
		ctx.strokePath()


		/*  Shape 11  */
		let pathRef11 = CGMutablePath()
		pathRef11.move(to: CGPoint(x: 61.5, y: 164.46))
		pathRef11.addCurve(to: CGPoint(x: 127.782, y: 270), control1: CGPoint(x: 63.745, y: 208.37), control2: CGPoint(x: 91.391, y: 246.819))
		pathRef11.addCurve(to: CGPoint(x: 133.759, y: 241.376), control1: CGPoint(x: 132.005, y: 261.052), control2: CGPoint(x: 133.491, y: 251.175))
		pathRef11.addCurve(to: CGPoint(x: 61.5, y: 164.46), control1: CGPoint(x: 133.416, y: 202.095), control2: CGPoint(x: 100.482, y: 168.107))
		pathRef11.closeSubpath()

		ctx.setFillColor(red: 0.984, green: 0.322, blue: 0.349, alpha: 1)
		ctx.addPath(pathRef11)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef11)
		ctx.strokePath()


		/*  Shape 12  */
		let pathRef12 = CGMutablePath()
		pathRef12.move(to: CGPoint(x: 378.028, y: 188.716))
		pathRef12.addCurve(to: CGPoint(x: 380.281, y: 200.301), control1: CGPoint(x: 379.813, y: 192.303), control2: CGPoint(x: 380.08, y: 196.374))
		pathRef12.addCurve(to: CGPoint(x: 250.281, y: 276.54), control1: CGPoint(x: 380.281, y: 235.647), control2: CGPoint(x: 321.802, y: 276.54))
		pathRef12.addCurve(to: CGPoint(x: 121.281, y: 200.301), control1: CGPoint(x: 178.76, y: 276.54), control2: CGPoint(x: 121.281, y: 235.647))
		pathRef12.addCurve(to: CGPoint(x: 123.534, y: 188.716), control1: CGPoint(x: 121.273, y: 196.297), control2: CGPoint(x: 122.002, y: 192.419))
		pathRef12.addCurve(to: CGPoint(x: 251.281, y: 240.301), control1: CGPoint(x: 141.028, y: 234.043), control2: CGPoint(x: 208.992, y: 239.718))
		pathRef12.addCurve(to: CGPoint(x: 378.028, y: 188.716), control1: CGPoint(x: 292.976, y: 239.953), control2: CGPoint(x: 361.165, y: 233.616))
		pathRef12.closeSubpath()

		ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
		ctx.addPath(pathRef12)
		ctx.fillPath()

		ctx.setLineWidth(6)
		ctx.setStrokeColor(red: 0.318, green: 0.318, blue: 0.318, alpha: 1)
		ctx.addPath(pathRef12)
		ctx.strokePath()
	}
}
