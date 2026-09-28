import AppKit
import AVFoundation

class PreviewView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }

    override func makeBackingLayer() -> CALayer {
        // Use AVCaptureVideoPreviewLayer directly as the view’s layer
        return AVCaptureVideoPreviewLayer()
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
}

let app = NSApplication.shared
let camera = takephoto()

// Create a simple window for the camera preview
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
    styleMask: [.titled, .closable, .resizable],
    backing: .buffered,
    defer: false
)
window.title = "Camera Preview"
window.center()
window.makeKeyAndOrderFront(nil)
NSApp.activate(ignoringOtherApps: true)

// Create a content view for the preview
let previewView = PreviewView(frame: window.contentView!.bounds)
previewView.autoresizingMask = [.width, .height]
window.contentView?.addSubview(previewView)

// Create a “Take Photo” button
let button = NSButton(title: "📸 Take Photo", target: nil, action: nil)
button.frame = NSRect(x: 20, y: 20, width: 120, height: 40)
window.contentView?.addSubview(button)

if camera.setupSession() {
    print("📷 Starting camera preview...")

    // Run preview on the main thread to ensure it draws correctly
    DispatchQueue.main.async {
        guard let layer = (previewView as? PreviewView)?.previewLayer else { return }
        layer.session = camera.session  // directly assign your camera session
        layer.videoGravity = .resizeAspectFill

        if !camera.session.isRunning {
            camera.session.startRunning()
        }
        print("🎥 Preview layer attached and running.")
    }

    // Connect button to camera’s button handler
    button.target = camera
    button.action = #selector(camera.buttonPressed(_:))
} else {
    print("❌ Camera setup failed")
}

// Keep the app running
app.run()