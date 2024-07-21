//
//  ContentView.swift
//  MegaDetector-Demo
//
//  Created by Bob Zak on 7/13/24.
//

import SwiftUI
import Vision

struct ContentView: View {
    let viewfinderImage : Image?
    let matchingObservations : [VNRecognizedObjectObservation]
    let inferenceTime : Double
    @Binding var isDetectorEnabled : Bool
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        ZStack {
            if let viewfinderImage = viewfinderImage {
                ViewfinderView(image: viewfinderImage)
            }
            if isDetectorEnabled {
                DetectorView(matchingObservations: matchingObservations, inferenceTime: inferenceTime)
            }
            VStack {
                Toggle("Detector Enabled", isOn: $isDetectorEnabled)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
            }
        }
        .detectOrientation($orientation)
    }
}

struct DetectOrientation: ViewModifier {
    @Binding var orientation: UIDeviceOrientation
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) {
                _ in
                orientation = UIDevice.current.orientation
            }
    }
}

extension View {
    func detectOrientation(_ orientation: Binding <UIDeviceOrientation>) -> some View {
        modifier(DetectOrientation(orientation: orientation))
    }
}

#Preview {
    // I'd like to be able to create a fake "matchingObservation" to test display
    //     but I can't figure out how to manually initialize an instance of
    //     VNRecognizedObjectObservation with valid data
    ContentView(viewfinderImage: Image("ViewfindViewPreview"),
                matchingObservations: [],
                inferenceTime: 22.0,
                isDetectorEnabled: .constant(true) )
}

