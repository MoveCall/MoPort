#!/usr/bin/env python3
"""
MoPort App Icon Generator
生成 macOS 应用图标 - 深灰背景 + 赛博朋克绿 M 形方波
"""

from PIL import Image, ImageDraw
import os

# 配置
OUTPUT_DIR = "Assets.xcassets/AppIcon.appiconset"
SIZES = [16, 32, 64, 128, 256, 512, 1024]

# 颜色定义
BG_TOP = (46, 46, 51)       # #2E2E33
BG_BOTTOM = (56, 56, 60)     # #38383C
GREEN_LIGHT = (0, 255, 128) # #00FF80 - 赛博朋克绿
GREEN_DARK = (0, 179, 77)   # #00B34D
BORDER_COLOR = (255, 255, 255, 25)  # 半透明白色边框

def draw_m_shape_wave(draw, bbox, padding):
    """
    绘制 M 形状的方波

    Args:
        draw: ImageDraw 对象
        bbox: 绘制区域 (left, top, right, bottom)
        padding: 内边距
    """
    left, top, right, bottom = bbox
    width = right - left - 2 * padding
    height = bottom - top - 2 * padding

    # 方波参数
    step_width = width / 16
    baseline = top + padding + height / 2
    high_amp = height * 0.35
    low_amp = height * 0.12

    # 定义方波的绘制函数
    def draw_step(x, y, w, h=4):
        """绘制单个方波台阶"""
        draw.rectangle([x, y, x + w * 0.9, y + h], fill=GREEN_LIGHT)
        draw.rectangle([x + w * 0.9, y, x + w * 0.9, y + h], fill=GREEN_LIGHT)
        draw.rectangle([x + w * 0.9, y, x + w, y + h], fill=GREEN_LIGHT)
        draw.rectangle([x + w * 0.9, y, x + w, y + h], fill=GREEN_DARK)

    # M 形状的关键点 (normalized 0-1, 相对于绘制区域)
    points = [
        # 左竖线 (高电平)
        (0.00, 0.0),  # 左上起点
        (0.15, 0.0),  # 左竖线结束

        # 左斜线下降
        (0.35, 0.65), # 斜线最低点

        # 中间凹陷
        (0.45, 0.65), # 凹陷起点
        (0.50, 0.65), # 凹陷最低点

        # 右斜线上升
        (0.65, 0.65), # 斜线起点
        (0.85, 0.0),  # ���线最高点

        # 右竖线 (高电平)
        (1.00, 0.0),  # 右上终点
    ]

    # 绘制方波形式的 M
    current_x = left + padding

    # 左竖线 (高电平)
    for i in range(5):
        x = current_x + i * step_width * 0.8
        y = baseline - high_amp
        draw_step(x, y, step_width * 0.9, 3)

    current_x += 5 * step_width * 0.8

    # 左斜线下降 (台阶式)
    slope_steps = 8
    for i in range(slope_steps):
        progress = i / slope_steps
        x = current_x + i * step_width * 0.6
        y = baseline - high_amp + (high_amp + low_amp) * progress
        draw.rectangle([x, y, x + step_width * 0.7, y + 3], fill=GREEN_LIGHT)

    current_x += slope_steps * step_width * 0.6

    # 中间凹陷
    draw.rectangle([current_x, baseline + low_amp, current_x + step_width * 2, baseline + low_amp + 3], fill=GREEN_LIGHT)
    current_x += step_width * 2

    # 右斜线上升 (台阶式)
    for i in range(slope_steps):
        progress = i / slope_steps
        x = current_x + i * step_width * 0.6
        y = baseline + low_amp - (high_amp + low_amp) * progress
        draw.rectangle([x, y, x + step_width * 0.7, y + 3], fill=GREEN_LIGHT)

    current_x += slope_steps * step_width * 0.6

    # 右竖线 (高电平)
    for i in range(5):
        x = current_x + i * step_width * 0.8
        y = baseline - high_amp
        draw.rectangle([x, y, x + step_width * 0.9, y + 3], fill=GREEN_LIGHT)


def create_icon(size):
    """创建指定尺寸的图标"""
    # 创建图像
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 绘制圆角矩形背景
    corner_radius = size * 22 / 1024
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=(*BG_TOP, 255)
    )

    # 添加渐变效果
    for i in range(size // 2):
        alpha = int(25 * (1 - i / (size // 2)))  # 从上到下渐变
        color = (
            BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * i // (size // 2),
            BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * i // (size // 2),
            BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * i // (size // 2),
            alpha
        )
        draw.rectangle([(0, i), (size, i + 1)], fill=color)

    # 绘制 M 形状的方波
    padding = size * 200 / 1024
    draw_m_shape_wave(draw, (0, 0, size, size), padding)

    # 添加高光效果 (顶部渐变)
    for i in range(int(size * 0.15)):
        alpha = int(40 * (1 - i / (size * 0.15)))
        draw.rectangle([(0, i), (size, i + 1)], fill=(255, 255, 255, alpha))

    # 添加内边框
    border_width = max(1, size // 128)
    inner_rect = [
        border_width,
        border_width,
        size - border_width - 1,
        size - border_width - 1
    ]
    draw.rounded_rectangle(
        inner_rect,
        radius=max(2, corner_radius * 0.8),
        outline=BORDER_COLOR[:3] + (15,)
    )

    return img


def main():
    print("🎨 MoPort App Icon Generator")
    print("=" * 40)

    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR}")

    # 生成所有尺寸
    for size in SIZES:
        print(f"  Generating {size}x{size}...", end=" ")

        icon = create_icon(size)
        filename = f"icon_{size}x{size}.png"
        output_path = os.path.join(OUTPUT_DIR, filename)
        icon.save(output_path, "PNG")

        print("✅")

    # 创建 Contents.json
    contents_json = """{
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
}"""

    with open(os.path.join(OUTPUT_DIR, "Contents.json"), 'w') as f:
        f.write(contents_json)

    print("📄 Contents.json created")
    print("\n✅ App icon generated successfully!")
    print(f"\n📁 Location: {OUTPUT_DIR}/")
    print("\n💡 To set as app icon:")
    print("   1. Copy Assets.xcassets to your Xcode project")
    print("   2. Or use: sips -s format icns Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png --out build/MoPort.app/Contents/Resources/AppIcon.icns")


if __name__ == "__main__":
    main()
