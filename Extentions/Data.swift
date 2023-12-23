//
//  Data.swift
//  BerryLiteDemo
//
//  Created by 池守和槻 on 2023/12/23.
//

import Accelerate
import CoreImage
import Foundation

// MARK: - Data

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }

    /// Convert a Data instance to Array representation.
    func toArray<T>(type: T.Type) -> [T] where T: AdditiveArithmetic {
        var array = [T](repeating: T.zero, count: self.count / MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { self.copyBytes(to: $0) }
        return array
    }

    func rgbToGray(width: Int, height: Int) -> Data {
        let sourceChannles = 3
        let sourceBytesPerRow = width * sourceChannles
        let luminance: [Float] = [0.2126, 0.7152, 0.0722]
        var gray = Data(count: height * width)

        for h in 0 ..< height {
            for w in 0 ..< width {
                var pixel: UInt8 = 0
                for c in 0 ..< 3 {
                    let p: UInt8 = self[h * sourceBytesPerRow + sourceChannles * w + c]
                    pixel += UInt8(luminance[c] * Float(p))
                }
                gray[h * width + w] = pixel
            }
        }
        return gray
    }
}
