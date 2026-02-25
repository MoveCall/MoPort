# Makefile for MoPort

BUNDLE_NAME = MoPort
APP_NAME = MoPort.app
BUILD_DIR = build
CONTENTS_DIR = $(BUILD_DIR)/$(APP_NAME)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SWIFT_FLAGS = -O -target arm64-apple-macosx13.0
FRAMEWORKS = -framework Cocoa -framework IOKit

# 源文件（排除 MoPortAppIconView.swift 和 *Tests.swift）
SWIFT_SOURCES = $(filter-out MoPort/MoPortAppIconView.swift MoPort/*Tests.swift, $(wildcard MoPort/*.swift))

.PHONY: all clean run

all: $(BUILD_DIR)/$(APP_NAME)

$(BUILD_DIR)/$(APP_NAME): $(SWIFT_SOURCES)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@echo "Building MoPort..."
	swiftc $(SWIFT_FLAGS) $(SWIFT_SOURCES) $(FRAMEWORKS) -o $(MACOS_DIR)/MoPort
	@cp MoPort/Info.plist $(CONTENTS_DIR)/Info.plist
	@# 生成图标
	@mkdir -p $(RESOURCES_DIR)/AppIcon.iconset
	@sips -s format png -z 16 16 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_16x16.png >/dev/null 2>&1 || true
	@sips -s format png -z 32 32 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_16x16@2x.png >/dev/null 2>&1 || true
	@sips -s format png -z 32 32 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_32x32.png >/dev/null 2>&1 || true
	@sips -s format png -z 64 64 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_32x32@2x.png >/dev/null 2>&1 || true
	@sips -s format png -z 128 128 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_128x128.png >/dev/null 2>&1 || true
	@sips -s format png -z 256 256 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_128x128@2x.png >/dev/null 2>&1 || true
	@sips -s format png -z 256 256 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_256x256.png >/dev/null 2>&1 || true
	@sips -s format png -z 512 512 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_256x256@2x.png >/dev/null 2>&1 || true
	@sips -s format png -z 512 512 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_512x512.png >/dev/null 2>&1 || true
	@sips -s format png -z 1024 1024 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_512x512@2x.png >/dev/null 2>&1 || true
	@sips -s format png -z 1024 1024 "assets/icons/iOS 图标 (app-ico)/App Store.png" --out $(RESOURCES_DIR)/AppIcon.iconset/icon_1024x1024.png >/dev/null 2>&1 || true
	@iconutil -c icns $(RESOURCES_DIR)/AppIcon.iconset >/dev/null 2>&1 || true
	@chmod +x $(MACOS_DIR)/MoPort
	@xattr -cr $(BUILD_DIR)/$(APP_NAME)
	@codesign --force --deep --sign - $(BUILD_DIR)/$(APP_NAME)
	@echo "Build complete: $(BUILD_DIR)/$(APP_NAME)"

clean:
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete"

run: all
	@open $(BUILD_DIR)/$(APP_NAME)
