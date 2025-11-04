import Foundation
import AVFoundation //Library for camera access
import AppKit //Library for macOS GUI elements

let username = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent

//NSObject: Root class of most Objective-C class hierarchies
//AVCapturePhotoCaptureDelegate: Protocol to handle photo capture output, must be implemented to receive captured photo data
class takephoto: NSObject, AVCapturePhotoCaptureDelegate {
    //Define a session and output for capturing photos
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var photoCaptured = false //Determine if the photo has been captured

    func setupSession() -> Bool { //Returns true if session is set up correctly
        session.sessionPreset = .photo //Set session preset to photo quality
        //Guard: ensures that the input device and output can be added to the session
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else { //Else block if any of the above fail
            print("❌ Unable to configure camera")
            return false
        }

        session.addInput(input)
        session.addOutput(output)
        return true
    }

    func capturePhoto() {
        session.startRunning() //Start the session
        print("📷 Camera warming up...")
        Thread.sleep(forTimeInterval: 1.0) //Wait for a second to let the camera warm up, else photo will be black
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
                     error: Error?) { //Error if photo capture fails
        if let error = error {
            print("❌ Capture error: \(error)")
            photoCaptured = true
            return
        }

        //Error if no image data is available
        guard let data = photo.fileDataRepresentation() else {
            print("❌ No image data")
            photoCaptured = true
            return
        }

        //Capture the filepath to the desktop and save the photo there
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

    func openPhoto() {
        let imagePath = "/Users/\(username)/Desktop/cli_captured_photo.jpg"
        print(username)
        if let image = NSImage(contentsOfFile: imagePath) {
            print("Loaded image size: \(image.size)")
    
            // Show it in Preview (external app)
            NSWorkspace.shared.open(URL(fileURLWithPath: imagePath))
        } else {
            print("Failed to load image")
        }
    }
}


