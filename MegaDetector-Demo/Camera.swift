//
//  Camera.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 12/11/23.
//

import AVFoundation
import UIKit
import os.log


protocol OutputHandlerDelegate: AnyObject {
    func captureRotationAngle() -> CGFloat
}



@Observable
class Camera: NSObject, OutputHandlerDelegate {
    private let captureSession = AVCaptureSession()
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    public var screenPreviewOutputHandler = ScreenPreviewOutputHandler()
    
    var md6Detector: MD6YoloV9CDetector?

    
    private var sessionQueue: DispatchQueue!
   
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            logger.debug("Using capture device: \(captureDevice.localizedName)")
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator? {
        if let captureDevice = captureDevice {
            return AVCaptureDevice.RotationCoordinator(device: captureDevice, previewLayer: nil)
        }
        return nil
    }
    
    
    override init() {
        super.init()
        initialize()
        
    }
    
    
    
    func captureRotationAngle() -> CGFloat {
        if let rotationCoordinator = rotationCoordinator {
            return rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        }
        return 0.0
    }
    
    private func getBestVideoDevice() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            logger.info("getBestVideoDevice -- returning .builtInTripleCamera")
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            logger.info("getBestVideoDevice -- returning .builtInDualCamera")
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            logger.info("getBestVideoDevice -- returning .builtInWideAngleCamera")
            return device
        }
        logger.error("getBestVideoDevice: could not find video device")
        return nil
    }
    
    
    private func initialize() {
        sessionQueue = DispatchQueue(label: "session queue")
        
        if let captureDevice = getBestVideoDevice() {
            self.captureDevice = captureDevice
            configureCaptureDevice(device: captureDevice)
        } else {
            fatalError("initialize: could not find a valid capture device")
        }
        
        // Subscribe to notifications for changes in device orientation; invoke updateOrientation()
        //    function on such changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        md6Detector = MD6YoloV9CDetector()
        md6Detector!.setupVision()
    }
    
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        var success = false
        
        logger.info("configureCaptureSession: entered")
        //* logDepthDataFormat(format: captureDevice!.activeDepthDataFormat!, info: "configureCaptureSession: near entrance ")
        
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        if let captureDevice = captureDevice {
            do {
                let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                } else {
                    fatalError("configureCaptureSession: Unable to add device input to capture session.")
                }
            } catch {
                fatalError("configureCaptureSession: Failed to obtain video input.")
            }
        } else {
           fatalError("configureCaptureSession: capture device is nil")
        }
        
        screenPreviewOutputHandler.delegate = self
        screenPreviewOutputHandler.configureCaptureSession()
        
        // Set output for Idle
        screenPreviewOutputHandler.addOutput(session: captureSession)
        
        let hardwareCost = captureSession.hardwareCost
        if hardwareCost > 1.0 {
            fatalError("captureSession.hardware cost = \(hardwareCost) exceeds 1.0")
        } else {
            logger.info("captureSession.hardware cost in Idle = \(hardwareCost)")
        }
        
        self.deviceInput = deviceInput
        
        logger.info("configureCaptureSession:Added Session Inputs and Outputs")
        
        updateConnections()
        
        isCaptureSessionConfigured = true
        
        success = true
    }
    
    private func configureCaptureDevice(device: AVCaptureDevice){
        let preferredWidthResolution = 1920
        var format : AVCaptureDevice.Format?
        
        guard let tempFormat = (device.formats.last { format in
            format.formatDescription.dimensions.width == preferredWidthResolution &&
            format.formatDescription.mediaSubType.rawValue ==
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange &&
            !format.isVideoBinned &&
            format.supportedDepthDataFormats.isEmpty
        }) else {
            fatalError("configureCaptureDevice:Could not find compatible video format ")
        }
        format = tempFormat
        
        // Begin the device configuration.
        do {
            try device.lockForConfiguration()
        } catch {
            fatalError("configureCaptureDevice:Could not lock video device")
        }
        // Configure the video device format.
        device.activeFormat = format!
        
        // Finish the device configuration.
        device.unlockForConfiguration()
    }
    
    private func updateConnections() -> Void {
        if captureDevice != nil {
            let outputs = captureSession.outputs
            
            if outputs.contains(screenPreviewOutputHandler.screenPreviewOutput) {
                screenPreviewOutputHandler.updateConnection()
            }
        }
        updateOrientation()
    }
    
    @objc private func updateOrientation() -> Void {
        if captureDevice != nil {
            let outputs = captureSession.outputs
            
            if outputs.contains(screenPreviewOutputHandler.screenPreviewOutput) {
                screenPreviewOutputHandler.updateOrientation()
            }
        }
    }
    
    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("Camera access authorized.")
            return true
        case .notDetermined:
            logger.debug("Camera access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            logger.debug("Camera access denied.")
            return false
        case .restricted:
            logger.debug("Camera library access restricted.")
            return false
        @unknown default:
            return false
        }
    }
    
    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            logger.error("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        
        configureCaptureDevice(device: captureDevice)
        
        updateConnections()
        
    }
    

    // Start Camera
    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            logger.error("Camera access was not authorized.")
            return
        }
        
        sessionQueue.async { [self] in
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        guard isCaptureSessionConfigured else { return }
        
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
   
}


fileprivate let logger = Logger(subsystem: "MegaDetector-Demo", category: "Camera")


