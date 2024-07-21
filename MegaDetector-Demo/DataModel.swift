//
//  DataModelLocal.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 12/11/23.
//

/*
See the License.txt file for this sample’s licensing information.
*/

import AVFoundation
import SwiftUI
import os.log


final class DataModel: ObservableObject {
    let camera = Camera()
    @Published var viewfinderImage: Image?
    
    var isDetectorEnabled = true
    
    // Spawn a task to repeatedly handle preview screen images
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    // Every time there's a new image in the previewStream, make it visible to the viewfinder,
    //       and pass it along to the md6Detector for inference
    func handleCameraPreviews() async {
        
        for await ciImage in camera.screenPreviewOutputHandler.previewStream {
            Task { @MainActor in
                viewfinderImage = ciImage.image
            }
            Task {
                if isDetectorEnabled {
                    if let md6Detector = self.camera.md6Detector {
                        md6Detector.captureDetectionOutput(image: ciImage)
                    } else {
                        logger.error("handleCameraPreviews: md6Detector is nil")
                    }
                }
            }
        }
    }
}
 




fileprivate let logger = Logger(subsystem: "MegaDetector-Demo", category: "DataModel")


