//
//  BerryLite.swift
//  BerryLiteDemo
//
//  Created by 池守和槻 on 2023/12/23.
//

import AVFoundation
import Foundation
import UIKit
import Vision

extension ViewController {
    func setupModel() {
        self.modelHandler = ModelHandler()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !self.isInfenreceQueueBusy else { return }

        inferenceQueue.async { [unowned self] in
            self.isInfenreceQueueBusy = true
            self.performModel(sampleBuffer: sampleBuffer)
            self.isInfenreceQueueBusy = false
        }
    }

    func setupLayers() {
        self.setupOverlayLayer()
        self.setupResultLayer()
    }

    func setupOverlayLayer() {
        overlayLayer = CALayer()
        let windowLength = screenRect.size.width > screenRect.size.height ? screenRect.size.height : screenRect.size.width
        overlayRect = CGRect(x: 0, y: 0.25 * screenRect.size.height, width: windowLength, height: windowLength)
        overlayLayer.frame = overlayRect

        // draw the border of overlay layer
        let borderWidth = 3.0
        let boxColor = CGColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 1.0)
        overlayLayer.borderWidth = borderWidth
        overlayLayer.borderColor = boxColor

        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.overlayLayer)
        }
    }

    func setupResultLayer() {
        resultLayer = CALayer()
        resultLayer.frame = CGRect(x: 0, y: 100, width: 300, height: 50)

        // draw the border of overlay layer
        let borderWidth = 3.0
        let boxColor = CGColor(red: 0.0, green: 255.0, blue: 0.0, alpha: 1.0)
        resultLayer.borderWidth = borderWidth
        resultLayer.borderColor = boxColor
        resultLayer.backgroundColor = boxColor

        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.resultLayer)
        }
    }

    func performModel(sampleBuffer: CMSampleBuffer) {
        guard let handler = self.modelHandler else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let date = Date()
        let modelInputRange = overlayLayer.frame.applying(
            screenRect.size.transformKeepAspect(toFitIn: CGSize(width: 1080, height: 1980)))
        let prob = handler.runModel(pixelBuffer: pixelBuffer, modelInputRange: modelInputRange)
        let intervalTime = date.timeIntervalSince(date)

        DispatchQueue.main.async { [weak self] in
            self!.modelDidComplete(prob: prob)
        }
    }

    func modelDidComplete(prob: Float) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        resultLayer.sublayers = nil // Remove results

        let textLayer = CATextLayer()
        var label = prob > 0.5 ? "Human" : "Not Human"
        let displayLabel = String(format: "Prob: %.2f, \(label)", prob)
        let formattedString = NSMutableAttributedString(string: displayLabel)
        let largeFont = UIFont(name: "Helvetica", size: 20)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: displayLabel.count))
        textLayer.foregroundColor = CGColor(red: 0, green: 0, blue: 1.0, alpha: 1.0)
        textLayer.string = formattedString
        textLayer.frame = CGRect(x: 10, y: 0, width: 300, height: 50)

        self.resultLayer.addSublayer(textLayer)
        CATransaction.commit()
    }
}
