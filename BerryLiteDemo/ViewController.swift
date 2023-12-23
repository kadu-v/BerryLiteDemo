//
//  ViewController.swift
//  BerryLiteDemo
//
//  Created by 池守和槻 on 2023/12/22.
//

import AVFoundation
import Foundation
import SwiftUI
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil // For view dimensions
    // For EdgeOCR
    private lazy var videoOutput = AVCaptureVideoDataOutput()
    var modelHandler: ModelHandler?
    var overlayLayer: CALayer! = nil
    var overlayRect: CGRect! = nil
    var resultLayer: CALayer! = nil
    let inferenceQueue = DispatchQueue(label: "inferenceQueue")
    var isInfenreceQueueBusy = false

    override func viewDidLoad() {
        super.viewDidLoad()

        checkPermission()
        sessionQueue.async { [unowned self] in
            guard self.permissionGranted else { return }

            self.setupCaptureSession()
            self.setupLayers()
            self.setupModel()
            self.captureSession.startRunning()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // Permission has been granted before
        case .authorized:
            permissionGranted = true
        // Permission has not been requested yet
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    //! MARK:
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {
            [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        })
    }

    //! MARK:
    func setupCaptureSession() {
        // Acess camera
        guard let videoDevice
            = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)

        guard captureSession.canAddOutput(videoOutput) else {
            return
        }
        captureSession.addOutput(videoOutput)
        guard captureSession.canSetSessionPreset(.high) else {
            return
        }
        captureSession.sessionPreset = .high

        // Add preview layer
        screenRect = UIScreen.main.bounds
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 90.0

        // EdgeOCR
        let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue) // TODO: ビデオ更新毎に呼ばれるデリゲートがViewControllerになっているので，違うdelegateにすれば良いかも

        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA]
        videoOutput.connection(with: .video)?.videoRotationAngle = 90.0

        // Update to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
