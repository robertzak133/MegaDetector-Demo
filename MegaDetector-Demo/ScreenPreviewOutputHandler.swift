//
//  ScreenPreviewOutputHandler.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 12/5/23.
//

import Foundation
import AVFoundation
import CoreImage
import SwiftUI
import os.log


class ScreenPreviewOutputHandler : NSObject {

    public var screenPreviewOutput = AVCaptureVideoDataOutput()
    
    weak var delegate : OutputHandlerDelegate?
    
    private var addToPreviewStream: ((CIImage) -> Void)?
    
    lazy var previewStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                continuation.yield(ciImage)
            }
        }
    }()
    
    func configureCaptureSession() -> Void {
        screenPreviewOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
    }
    
    func updateConnection() -> Void {
        updateOrientation()
    }

    
    func updateOrientation() -> Void {
        if let outputConnection = screenPreviewOutput.connection(with: .video) {
            if let delegate = delegate {
                let rotationAngle = delegate.captureRotationAngle()
                logger.info("updateOrientation: Rotation angle is \(rotationAngle)")
                if outputConnection.isVideoRotationAngleSupported(rotationAngle) {
                    outputConnection.videoRotationAngle = rotationAngle
                }
            } else {
                logger.error("updateOrientation: delegate is nil")
            }
        } else {
            logger.error("updateOrientation: outputConnection is nil")
        }
    }
    
    func addOutput(session: AVCaptureSession) {
        guard session.canAddOutput(screenPreviewOutput) else {
            logger.error("Unable to add screenPreviewOutput to capture session.")
            return
        }
        session.addOutput(screenPreviewOutput)
        
        let hardwareCost = session.hardwareCost
        if hardwareCost > 1.0 {
            logger.error("After screenPreviewOutput -- captureSession.hardware cost = \(hardwareCost) exceeds 1.0")
        }
    }
    
    func removeOutput(session: AVCaptureSession) {
        let outputs = session.outputs
        if outputs.contains(screenPreviewOutput) {
            session.removeOutput(screenPreviewOutput)
        } else {
            logger.warning("removeOutput: session does not contain screenPreviewOutput")
        }
    }
    
}



extension ScreenPreviewOutputHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        addToPreviewStream?(image)
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        logger.info("captureOutput -- dropped buffer")
    }
    
    
    
}
    
    
fileprivate let logger = Logger(subsystem: "MegaDetector-Demo", category: "ScreenPreviewOutputHandler")

