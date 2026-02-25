//
//  ToastWindow.swift
//  MoPort
//
//  自定义悬浮气泡窗口
//

import Cocoa

enum ToastType {
    case attached   // 设备插入 - 绿色
    case detached   // 设备拔出 - 灰色
}

class ToastWindow: NSWindow {
    // MARK: - 配置

    private let displayDuration: TimeInterval = 2.2
    private let fadeDuration: TimeInterval = 0.3
    private let cornerRadius: CGFloat = 12
    private let windowWidth: CGFloat = 220
    private let windowHeight: CGFloat = 60
    private let marginFromBottom: CGFloat = 80
    private let marginFromRight: CGFloat = 20

    // MARK: - UI 引用

    private var iconView: NSTextField!
    private var messageLabel: NSTextField!
    private var pathLabel: NSTextField!
    private var visualEffect: NSVisualEffectView!

    // MARK: - 私有属性

    private var hideWorkItem: DispatchWorkItem?

    // MARK: - 初始化

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContentView()
        setupLanguageObserver()
    }

    // MARK: - 公开方法

    func show(device: SerialDevice, type: ToastType) {
        let message = type == .attached ? L("deviceFound") : L("deviceRemoved")
        show(path: device.path, message: message, type: type)
    }

    func show(path: String, type: ToastType) {
        let message = type == .attached ? L("deviceFound") : L("deviceRemoved")
        show(path: path, message: message, type: type)
    }

    private func show(path: String, message: String, type: ToastType) {
        // 取消之前的隐藏任务
        hideWorkItem?.cancel()

        // 更新内容
        updateContent(message: message, path: path, type: type)

        // 定位窗口到屏幕右下角
        positionWindow()

        // 淡入显示
        alphaValue = 0
        orderFrontRegardless()
        fadeIn()
    }

    // MARK: - 私有方法

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }

    @objc private func languageChanged() {
        // 语言变化时如果有显示的窗口，更新当前显示的文本
        // 由于 Toast 会自动消失，这里不需要特别处理
    }

    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        ignoresMouseEvents = true
        isMovable = false
        isReleasedWhenClosed = false
        hasShadow = true
    }

    private func setupContentView() {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = cornerRadius
        containerView.layer?.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // 磨砂玻璃效果背景
        let blurView = NSVisualEffectView()
        blurView.material = .underPageBackground
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.wantsLayer = true
        visualEffect = blurView

        containerView.addSubview(blurView)

        // 状态指示图标
        let icon = NSTextField(labelWithString: "●")
        icon.font = NSFont.systemFont(ofSize: 16)
        icon.isEditable = false
        icon.isSelectable = false
        icon.backgroundColor = .clear
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconView = icon

        // 消息文本
        let msgLabel = NSTextField(labelWithString: "")
        msgLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        msgLabel.isEditable = false
        msgLabel.isSelectable = false
        msgLabel.backgroundColor = .clear
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel = msgLabel

        // 路径文本
        let pLabel = NSTextField(labelWithString: "")
        pLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        pLabel.textColor = .secondaryLabelColor
        pLabel.isEditable = false
        pLabel.isSelectable = false
        pLabel.backgroundColor = .clear
        pLabel.lineBreakMode = .byTruncatingMiddle
        pLabel.translatesAutoresizingMaskIntoConstraints = false
        pathLabel = pLabel

        // 添加到容器
        containerView.addSubview(icon)
        containerView.addSubview(msgLabel)
        containerView.addSubview(pLabel)

        contentView = containerView

        // 布局约束
        NSLayoutConstraint.activate([
            // 容器大小
            containerView.widthAnchor.constraint(equalToConstant: windowWidth),
            containerView.heightAnchor.constraint(equalToConstant: windowHeight),

            // 视觉效果背景
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // 图标
            icon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // 消息标签
            msgLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            msgLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),

            // 路径标签
            pLabel.leadingAnchor.constraint(equalTo: msgLabel.leadingAnchor),
            pLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            pLabel.topAnchor.constraint(equalTo: msgLabel.bottomAnchor, constant: 2),
        ])
    }

    private func updateContent(message: String, path: String, type: ToastType) {
        // 根据类型设置颜色
        switch type {
        case .attached:
            iconView.stringValue = "●"
            iconView.textColor = NSColor(calibratedRed: 0.16, green: 0.8, blue: 0.25, alpha: 1)
            visualEffect.material = .underPageBackground
            visualEffect.layer?.backgroundColor = makeCGColor(r: 0.16, g: 0.8, b: 0.25, a: 0.15)

        case .detached:
            iconView.stringValue = "○"
            iconView.textColor = .secondaryLabelColor
            visualEffect.material = .contentBackground
            visualEffect.layer?.backgroundColor = makeCGColor(r: 0.5, g: 0.5, b: 0.5, a: 0.1)
        }

        messageLabel.stringValue = message
        pathLabel.stringValue = path
    }

    private func positionWindow() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - windowWidth - marginFromRight
        let y = screenFrame.minY + marginFromBottom

        setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func fadeIn() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            animator().alphaValue = 1.0
        }

        // 设置自动隐藏任务
        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOut()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: workItem)
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            context.completionHandler = { [weak self] in
                self?.orderOut(nil)
            }
            animator().alphaValue = 0.0
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NSColor Helper

private func makeCGColor(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> CGColor {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let components = [r, g, b, a]
    return CGColor(colorSpace: colorSpace, components: components)!
}
