//
//  CIImageExtensions.swift
//  MegaDetector-Demo
//
//  Created by Bob Zak on 7/20/24.
//

import SwiftUI

// Extending the CIImage class to produce an image in the right format for preview screen and
//      detection model to consume.
extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
