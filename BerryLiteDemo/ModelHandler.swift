//
//  ModelHandler.swift
//  BerryLiteDemo
//
//  Created by 池守和槻 on 2023/12/23.
//

import AVFoundation
import BerryLiteCxx.interface

class ModelHandler {
    var inputSize = CGSize(width: 96, height: 96)

    init() {}

    func runModel(pixelBuffer: CVPixelBuffer, modelInputRange: CGRect) -> Float {
        guard let data = self.preprocess(pixelBuffer: pixelBuffer, modelInputRange: modelInputRange) else {
            return -1.0
        }
        let prob = try! self.infer(input: data)
        return prob
    }

    func preprocess(pixelBuffer: CVPixelBuffer, modelInputRange: CGRect) -> Data? {
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA)

        // Resize `targetSquare` of input image to `modelSize`.
        let modelSize = CGSize(width: self.inputSize.width, height: self.inputSize.height)
        guard let thumbnail = pixelBuffer.resize(from: modelInputRange, to: modelSize)
        else {
            return nil
        }

        // Remove the alpha component from the image buffer to get the initialized `Data`.
        guard let rgbData = thumbnail.rgbData(isModelQuantized: true)
        else {
            print("Failed to convert the image buffer to RGB data.")
            return nil
        }

        // convert rgb to gray image
        let inputData = rgbData.rgbToGray(width: Int(self.inputSize.width), height: Int(self.inputSize.height))

        return inputData
    }

    func infer(input: Data) throws -> Float {
        let prob = input.withUnsafeBytes { buf in
            BerryLiteCxx.BLite.run(buf)
        }
        return prob
    }
}
