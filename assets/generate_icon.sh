#!/bin/bash
# MoPort App Icon Generator
# 生成 macOS 应用图标

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets"
APPICON_SET="$ASSETS_DIR/AppIcon.appiconset"

echo "🎨 MoPort App Icon Generator"
echo "================================"

# 创建 Assets.xcassets 目录结构
echo "📁 Creating Assets directory structure..."
mkdir -p "$APPICON_SET"

# 创建图标尺寸数组
declare -a SIZES=(
    "16:16"
    "32:32"
    "64:64"
    "128:128"
    "256:256"
    "512:512"
    "1024:1024"
)

# 生成所有尺寸的图标
for size_pair in "${SIZES[@]}"; do
    size="${size_pair%%:*}"
    scale="${size_pair##*:}"

    filename="icon_${size}x${size}.png"
    output_path="$APPICON_SET/$filename"

    echo "  Generating ${size}x${size}..."
done

# 使用 Swift 渲染图标到临时文件
TEMP_SWIFT="$PROJECT_DIR/.render_icon.swift"

cat > "$TEMP_SWIFT" << 'SWIFT_EOF'
import SwiftUI
import AppKit

// 复制 AppIconView 的完整代码
struct AppIconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.18, blue: 0.20),
                            Color(red: 0.22, green: 0.22, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .padding(8)

            MShapeWave()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.0, green: 1.0, blue: 0.5),
                            Color(red: 0.0, green: 0.7, blue: 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(50)

            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(1)
        }
        .frame(width: 1024, height: 1024)
    }
}

struct MShapeWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let padding: CGFloat = 200
        let drawRect = rect.insetBy(dx: padding, dy: padding)
        let w = drawRect.width
        let h = drawRect.height

        let stepWidth: CGFloat = w / 16
        let baseline = drawRect.midY
        let highAmp: CGFloat = h * 0.35
        let lowAmp: CGFloat = h * 0.12

        path.move(to: CGPoint(x: drawRect.minX, y: baseline - highAmp))

        let leftLegSteps = 3
        for i in 0..<leftLegSteps {
            let x = drawRect.minX + CGFloat(i) * stepWidth
            path.addLine(to: CGPoint(x: x + stepWidth * 0.9, y: baseline - highAmp))
            path.addLine(to: CGPoint(x: x + stepWidth * 0.9, y: baseline - highAmp + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: baseline - highAmp + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: baseline - highAmp))
        }

        let leftSlopeSteps = 6
        for i in 0..<leftSlopeSteps {
            let progress = CGFloat(i) / CGFloat(leftSlopeSteps)
            let y = baseline - highAmp + (highAmp + lowAmp) * progress

            let x = drawRect.minX + CGFloat(leftLegSteps) * stepWidth + CGFloat(i) * stepWidth * 0.7
            path.addLine(to: CGPoint(x: x + stepWidth * 0.6, y: y))
            path.addLine(to: CGPoint(x: x + stepWidth * 0.6, y: y + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: y + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: y))
        }

        let centerValleyStart = drawRect.minX + CGFloat(leftLegSteps + leftSlopeSteps) * stepWidth * 0.85
        path.addLine(to: CGPoint(x: centerValleyStart + stepWidth * 2, y: baseline + lowAmp))
        path.addLine(to: CGPoint(x: centerValleyStart + stepWidth * 2, y: baseline + lowAmp + 4))
        path.addLine(to: CGPoint(x: centerValleyStart + stepWidth * 2.5, y: baseline + lowAmp + 4))
        path.addLine(to: CGPoint(x: centerValleyStart + stepWidth * 2.5, y: baseline + lowAmp))

        let rightSlopeSteps = 6
        for i in 0..<rightSlopeSteps {
            let progress = CGFloat(i) / CGFloat(rightSlopeSteps)
            let y = baseline + lowAmp - (highAmp + lowAmp) * progress

            let x = centerValleyStart + stepWidth * 3 + CGFloat(i) * stepWidth * 0.7
            path.addLine(to: CGPoint(x: x + stepWidth * 0.6, y: y))
            path.addLine(to: CGPoint(x: x + stepWidth * 0.6, y: y + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: y + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: y))
        }

        let rightLegSteps = 3
        for i in 0..<rightLegSteps {
            let x = drawRect.minX + CGFloat(leftLegSteps + leftSlopeSteps + rightSlopeSteps) * stepWidth * 0.9 + CGFloat(i) * stepWidth
            path.addLine(to: CGPoint(x: x + stepWidth * 0.9, y: baseline - highAmp))
            path.addLine(to: CGPoint(x: x + stepWidth * 0.9, y: baseline - highAmp + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: baseline - highAmp + 4))
            path.addLine(to: CGPoint(x: x + stepWidth, y: baseline - highAmp))
        }

        path.closeSubpath()
        return path
    }
}

// 渲染并保存图片
func renderIcon(size: CGFloat, outputPath: String) {
    let view = AppIconView()
    let hostingController = NSHostingController(rootView: view)

    let imageSize = CGSize(width: size, height: size)
    let image = NSImage(size: imageSize)

    image.lockFocus()
    let bounds = NSRect(origin: .zero, size: imageSize)
    hostingController.view.frame = bounds
    hostingController.view.layer?.render(in: NSGraphicsContext.current?.cgContext ?? CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB())!, to: .zero)
    image.unlockFocus()

    // 使用 bitmapImageRepForCgImage 获取正确渲染
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false)
    bitmap.size = imageSize

    let img = NSImage(size: imageSize)
    img.addRepresentation(bitmap)

    let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    let newRep = NSBitmapImageRep(cgImage: cgImage)
    newRep.size = imageSize

    let pngData = newRep.representation(using: .png, properties: [:])
    try! pngData?.write(to: URL(fileURLWithPath: outputPath))
}

// 主函数
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    let outputPath = "\(outputDir)/icon_\(Int(size))x\(Int(size)).png"
    renderIcon(size: size, outputPath: outputPath)
    print("✅ Generated: \(outputPath)")
}

print("🎉 All icons generated successfully!")
SWIFT_EOF

# 编译并运行渲染器
echo ""
echo "🔨 Compiling and rendering icons..."
swiftc -o "$PROJECT_DIR/.render_icon" "$TEMP_SWIFT" \
    -framework SwiftUI \
    -framework AppKit \
    -target arm64-apple-macosx13.0

# 生成图标
"$PROJECT_DIR/.render_icon" "$APPICON_SET"

# 清理临时文件
rm -f "$PROJECT_DIR/.render_icon"
rm -f "$TEMP_SWIFT"

# 创建 Contents.json
echo ""
echo "📄 Creating Contents.json..."

cat > "$APPICON_SET/Contents.json" << 'JSON_EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON_EOF

echo ""
echo "✅ App icon assets generated successfully!"
echo "📁 Location: $APPICON_SET"
echo ""
echo "📝 Next steps:"
echo "   1. Copy Assets.xcassets to your Xcode project"
echo "   2. Or manually copy icon_1024x1024.png as the app icon"
