//
//  MegaDetector_DemoApp.swift
//  MegaDetector-Demo
//
//  Created by Bob Zak on 7/13/24.
//

import SwiftUI
import SwiftData

@main
struct MegaDetector_DemoApp: App {
    // @StateObject tells SwiftUI preview handler to ignore this initialization
    @StateObject private var dataModel = DataModel()
 
    var body: some Scene {
        WindowGroup {
            let viewfinderImage = dataModel.viewfinderImage
            let md6Detector = dataModel.camera.md6Detector
            ContentView(viewfinderImage: viewfinderImage,
                        matchingObservations: md6Detector!.matchingObservations, inferenceTime: md6Detector!.inferenceTime,
                        isDetectorEnabled: $dataModel.isDetectorEnabled)
            .task {
                await dataModel.camera.start()
            }
        }
    }
}

