//
//  MD6YoloV9CTriggerDetector.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 7/11/24.
//

import Foundation
import Vision
import CoreImage
import UIKit
import os.log

@Observable   // We'll be reaching into this object from the UI -- make it observable
class MD6YoloV9CDetector: NSObject {
    // Prune this array to filter what MD6 model detects -- default to all classes
    private var detectionMatchList = ["animal", "person", "vehicle"]
    // Mininum confidence threshold required to display bounding box on screen
    private var detectionConfidenceThreshold :Float = 0.95
    
    public var matchingObservations: [VNRecognizedObjectObservation] = []
    
    // Vision parts
    private var requests = [VNRequest]()
    private var startInferenceTime = 0.0
    private var endInferenceTime = 0.0
    public var inferenceTime = 0.0
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "MDV6b-yolov9c", withExtension: "mlmodelc") else {
            return NSError(domain: "MD6YoloV9cTriggerDetector", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)
            getModelTargets(mlModel: mlModel)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.storeVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    // Look through the model for the recognized object types (debug only)
    func getModelTargets(mlModel : MLModel) -> Void {
        logger.info("getModelTargets -- classes recognized by model: ")
        for classLabel in mlModel.modelDescription.classLabels as! [String] {
            logger.info(" \(classLabel)")
        }
        
    }
    
    func storeVisionRequestResults(_ results: [Any]) {
        let results = results as! [VNRecognizedObjectObservation]
        endInferenceTime = CACurrentMediaTime()
        matchingObservations = results.filter {
            !$0.labels.filter {
                self.detectionMatchList.contains($0.identifier) &&
                $0.confidence >= self.detectionConfidenceThreshold
            }.isEmpty
        }
        inferenceTime = (endInferenceTime - startInferenceTime) * 1000
    }
    
    // this function called on every few preview screen images
    //      Queues a request for object detector
    public func captureDetectionOutput(image: CIImage) {
        let imageRequestHandler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])
        
        do {
            startInferenceTime = CACurrentMediaTime()
            try imageRequestHandler.perform(self.requests)
        } catch {
            logger.error("updateTriggerOutput -- imageRequestHandler call returned error")
        }
    }
        
}

fileprivate let logger = Logger(subsystem: "MegaDetector-Demo", category: "MD6YoloV9CDetector")
