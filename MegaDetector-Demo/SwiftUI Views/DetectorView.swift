//
//  TriggerDetectorView.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 1/25/24.
//

import SwiftUI
import AVFoundation
import Vision

// Draws the bounding boxes from the trigger detector
//     on the display screen

struct DetectorView: View {
    var matchingObservations : [VNRecognizedObjectObservation]
    var inferenceTime : Double
    
    // Draw a bunch of bounding boxes and labels.
    var body: some View {
        GeometryReader { geometry in
            ForEach(matchingObservations, id: \.self) { matchingObservation in
                //For some reason I can't explain, the following libary call reverses up and down
                //let boundingBox = VNImageRectForNormalizedRect(matchingObservation.boundingBox,
                //  Int(geometry.size.width),
                //  Int(geometry.size.height))
                // So I hack in the frame normalization by hand :(
                let width  = matchingObservation.boundingBox.width * geometry.size.width
                let height = matchingObservation.boundingBox.height * geometry.size.height
                let midX   = matchingObservation.boundingBox.midX * geometry.size.width
                let midY   = (1.0 - matchingObservation.boundingBox.midY) * geometry.size.height
                //
                let label = matchingObservation.labels[0]
                
                // Bounding Box of Detected Target
                Rectangle()
                    .fill(.yellow)
                    .opacity(0.40)
                    .frame(width: width, height: height)
                    .position(x: midX, y: midY)
                
                Text(String(format: "\(label.identifier) %0.2f in %0.0f ms",
                            label.confidence, inferenceTime))
                .position(x: midX, y: midY)
                
                // Center of Area of Interest (for focusing)
                Circle()
                    .size(width: width/2, height: height/2)
                    .frame(width: width, height: height)
                    .position(x: midX + width/4 , y: midY + height/4 )
                    .opacity(0.40)
                    .tint(.white)
                
            }
        }
    }
}
    
    #Preview {
        // I'd like to be able to create a fake "matchingObservation" to test display
        //     but I can't figure out how to manually initialize an instance of
        //     VNRecognizedObjectObservation with valid data
        DetectorView(matchingObservations: [], inferenceTime: 22.0)
    }

