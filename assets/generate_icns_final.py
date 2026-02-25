#!/usr/bin/env python3
from PIL import Image
import os
import subprocess

# 使用新的透明背景图片
source_path = "assets/icons/App Store.png"
dest_dir = "build/MoPort.app/Contents/Resources/AppIcon.iconset"

# 创建目标目录
os.makedirs(dest_dir, exist_ok=True)

# 打开源图片
source = Image.open(source_path)

# 确保 RGBA 模式
if source.mode != 'RGBA':
    source = source.convert('RGBA')

# 生成所需尺寸
sizes = [
    (16, 'icon_16x16.png'),
    (32, 'icon_16x16@2x.png'),
    (32, 'icon_32x32.png'),
    (64, 'icon_32x32@2x.png'),
    (128, 'icon_128x128.png'),
    (256, 'icon_128x128@2x.png'),
    (256, 'icon_256x256.png'),
    (512, 'icon_256x256@2x.png'),
    (512, 'icon_512x512.png'),
    (1024, 'icon_512x512@2x.png'),
    (1024, 'icon_1024x1024.png'),
]

for size, filename in sizes:
    img = source.resize((size, size), Image.Resampling.LANCZOS)
    img.save(os.path.join(dest_dir, filename), 'PNG')
    print(f"Generated {filename}")

# 转换为 icns
subprocess.run(['iconutil', '-c', 'icns', dest_dir], check=True)
print(f"Created icns file")

# 清理 iconset
subprocess.run(['rm', '-rf', dest_dir], check=False)
print("Done")
