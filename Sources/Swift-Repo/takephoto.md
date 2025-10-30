import Foundation
import AVFoundation

class takephoto: NSObject, AVCapturePhotoCaptureDelegate {
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var photoCaptured = false

    func setupSession() -> Bool {
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else {
            print("❌ Unable to configure camera")
            return false
        }

        session.addInput(input)
        session.addOutput(output)
        return true
    }

    func capturePhoto() {
        session.startRunning()
        print("📷 Camera warming up...")
        Thread.sleep(forTimeInterval: 1.0)
        print("📷 Capturing photo...")

        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)

        // Keep the run loop alive until photoCaptured = true
        while !photoCaptured {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }

        session.stopRunning()
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("❌ Capture error: \(error)")
            photoCaptured = true
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            print("❌ No image data")
            photoCaptured = true
            return
        }

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("cli_captured_photo.jpg")

        do {
            try data.write(to: fileURL)
            print("✅ Photo saved to \(fileURL.path)")
        } catch {
            print("❌ Failed to save photo: \(error)")
        }

        photoCaptured = true
    }
}
