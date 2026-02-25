//
//  MoPortAppIconView.swift
//  MoPort
//
//  Apple App Icon Design - "Mo-Connector" 概念
//  深蓝色背景 + 白色 M 形状 + 微妙的青色光晕
//

import SwiftUI

struct MoPortAppIconView: View {
    var body: some View {
        ZStack {
            // 背景：深蓝色 squircle
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    RadialGradient(
                        colors: [
                            // 中心稍亮
                            Color(red: 0.12, green: 0.3, blue: 0.55),
                            // 边缘稍暗
                            Color(red: 0.0, green: 0.25, blue: 0.5)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.5),
                        startRadius: 50,
                        endRadius: 512
                    )
                )
                .frame(width: 1024, height: 1024)

            // M 形状的青色光晕背景层
            MGlowShape()
                .blur(radius: 25)
                .opacity(0.6)

            // 主 M 形状
            MShape()
                .fill(.white)

            // 顶部高光效果（模拟玻璃质感）
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.0),
                        endPoint: UnitPoint(x: 0.5, y: 0.15)
                    )
                )
                .frame(width: 1024, height: 1024)

            // 边框微光
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 1024, height: 1024)
        }
        .frame(width: 1024, height: 1024)
    }
}

// MARK: - M 形状

struct MShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 绘图区域（留出边距）
        let padding: CGFloat = 200
        let drawRect = rect.insetBy(dx: padding, dy: padding)
        let width = drawRect.width
        let height = drawRect.height

        // M 形状的关键点（normalized，相对于 drawRect）
        // 左竖线起点
        let p1 = CGPoint(x: 0.0, y: 0.15)
        // 左竖线终点（底部微内收）
        let p2 = CGPoint(x: 0.18, y: 0.85)
        // 中间凹陷点
        let p3 = CGPoint(x: 0.5, y: 0.65)
        // 右竖线起点（底部微内收）
        let p4 = CGPoint(x: 0.82, y: 0.85)
        // 右竖线终点
        let p5 = CGPoint(x: 1.0, y: 0.15)

        // 转换为实际坐标
        func pt(_ normalized: CGPoint) -> CGPoint {
            return CGPoint(
                x: drawRect.minX + normalized.x * width,
                y: drawRect.minY + normalized.y * height
            )
        }

        // M 形状的线条粗细
        let strokeWidth: CGFloat = min(width * 0.12, 120)

        // 绘制左竖线（底部微收）
        let leftLegPath = Path { path in
            let start = pt(p1)
            let end = pt(p2)
            let controlOffset = (end.y - start.y) * 0.1

            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: start.x, y: start.y + controlOffset),
                control2: CGPoint(x: end.x, y: end.y - controlOffset)
            )
        }

        // 绘制左斜线到中间
        let leftSlopePath = Path { path in
            let start = pt(p2)
            let end = pt(p3)
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

            path.move(to: start)
            path.addQuadCurve(
                to: mid,
                control: CGPoint(x: start.x + (end.x - start.x) * 0.3, y: start.y + (end.y - start.y) * 0.5)
            )
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: mid.x + (end.x - mid.x) * 0.5, y: mid.y + (end.y - mid.y) * 0.5)
            )
        }

        // 绘制右斜线到右侧竖线
        let rightSlopePath = Path { path in
            let start = pt(p3)
            let end = pt(p4)
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

            path.move(to: start)
            path.addQuadCurve(
                to: mid,
                control: CGPoint(x: start.x + (end.x - start.x) * 0.5, y: mid.y + (end.y - mid.y) * 0.5)
            )
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: mid.x + (end.x - mid.x) * 0.7, y: mid.y + (end.y - mid.y) * 0.5)
            )
        }

        // 绘制右竖线（底部微收）
        let rightLegPath = Path { path in
            let start = pt(p4)
            let end = pt(p5)
            let controlOffset = (end.y - start.y) * 0.1

            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: end.x, y: end.y - controlOffset),
                control2: CGPoint(x: start.x, y: start.y + controlOffset)
            )
        }

        // 组合所有路径，添加粗细
        let combined = Path { path in
            path.addPath(leftLegPath)
            path.addPath(leftSlopePath)
            path.addPath(rightSlopePath)
            path.addPath(rightLegPath)
        }

        // 将线条转换为填充形状（描边效果）
        for element in combined.strokedPath(
            path: combined,
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        ) {
            path.addPath(element)
        }

        return path
    }
}

// MARK: - M 形状光晕层

struct MGlowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 绘图区域（留出边距）
        let padding: CGFloat = 200
        let drawRect = rect.insetBy(dx: padding, dy: padding)
        let width = drawRect.width
        let height = drawRect.height

        // M 形状的关键点（与主形状相同）
        let p1 = CGPoint(x: 0.0, y: 0.15)
        let p2 = CGPoint(x: 0.18, y: 0.85)
        let p3 = CGPoint(x: 0.5, y: 0.65)
        let p4 = CGPoint(x: 0.82, y: 0.85)
        let p5 = CGPoint(x: 1.0, y: 0.15)

        func pt(_ normalized: CGPoint) -> CGPoint {
            return CGPoint(
                x: drawRect.minX + normalized.x * width,
                y: drawRect.minY + normalized.y * height
            )
        }

        let strokeWidth: CGFloat = min(width * 0.12, 120)
        let glowExpand: CGFloat = strokeWidth * 2.5

        // 绘制光晕形状（比 M 稍大）
        let leftLegPath = Path { path in
            let start = pt(p1)
            let end = pt(p2)
            let controlOffset = (end.y - start.y) * 0.1

            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: start.x, y: start.y + controlOffset),
                control2: CGPoint(x: end.x, y: end.y - controlOffset)
            )
        }

        let leftSlopePath = Path { path in
            let start = pt(p2)
            let end = pt(p3)
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

            path.move(to: start)
            path.addQuadCurve(
                to: mid,
                control: CGPoint(x: start.x + (end.x - start.x) * 0.3, y: start.y + (end.y - start.y) * 0.5)
            )
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: mid.x + (end.x - mid.x) * 0.5, y: mid.y + (end.y - mid.y) * 0.5)
            )
        }

        let rightSlopePath = Path { path in
            let start = pt(p3)
            let end = pt(p4)
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

            path.move(to: start)
            path.addQuadCurve(
                to: mid,
                control: CGPoint(x: start.x + (end.x - start.x) * 0.5, y: mid.y + (end.y - mid.y) * 0.5)
            )
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: mid.x + (end.x - mid.x) * 0.7, y: mid.y + (end.y - mid.y) * 0.5)
            )
        }

        let rightLegPath = Path { path in
            let start = pt(p4)
            let end = pt(p5)
            let controlOffset = (end.y - start.y) * 0.1

            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: end.x, y: end.y - controlOffset),
                control2: CGPoint(x: start.x, y: start.y + controlOffset)
            )
        }

        // 组合路径
        let combined = Path { path in
            path.addPath(leftLegPath)
            path.addPath(leftSlopePath)
            path.addPath(rightSlopePath)
            path.addPath(rightLegPath)
        }

        // 使用更粗的描边作为光晕
        for element in combined.strokedPath(
            path: combined,
            style: StrokeStyle(lineWidth: glowExpand, lineCap: .round, lineJoin: .round)
        ) {
            path.addPath(element)
        }

        return path
    }
}

// MARK: - 预览

struct MoPortAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        MoPortAppIconView()
            .previewDisplayName("App Icon - 1024x1024")
            .previewLayout(.fixedSize(width: 1024, height: 1024))
            .preferredColorScheme(.dark)

        MoPortAppIconView()
            .previewDisplayName("App Icon - Scaled Down")
            .frame(width: 256, height: 256)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)

        MoPortAppIconView()
            .previewDisplayName("App Icon - Dock Size")
            .frame(width: 128, height: 128)
            .previewLayout(.fixedSize(width: 128, height: 128))
            .preferredColorScheme(.dark)
    }
}

// MARK: - Shape Extension for Stroke

extension Shape {
    func strokedPath(path: Path, style: StrokeStyle) -> Path {
        path.strokedPath(style: style)
    }
}
