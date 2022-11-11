//
//  CameraController.swift
//

import AVFoundation
import UIKit
import Vision

class CameraController: UIViewController {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "Session Queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()

    private var screenRect: CGRect! = nil

    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let detectionLayer = CALayer()
    private let resultsLayer = CALayer()
    private var blurView: UIVisualEffectView! = nil

    internal var requests: Array<VNRequest>! = nil

    private var videoOrientation: AVCaptureVideoOrientation = .portrait

    private var permissionGranted = false
    private var sessionSetupSucceed = false
    internal var performRequests = false

    private let interfaceColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    private var capturesInProgress = Set<PhotoCaptureProcessor>()

    private var detectedRect: CGRect! = nil
    
    private var button: Button! = nil
    private var resultsView: ResultsView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            
            setupCaptureSession()
            setupRequests()
            setupInterface()

            session.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async { [unowned self] in
            if sessionSetupSucceed {
                setupRequests()
                setupInterface()
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sessionQueue.async { [unowned self] in
            if sessionSetupSucceed {
                session.stopRunning()
            }
        }
    }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//
//        screenRect = UIScreen.main.bounds
//        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
//    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permissionGranted = true
            case .notDetermined:
                requestPermission()
            default:
                permissionGranted = false
        }
    }

    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }

    private func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        screenRect = UIScreen.main.bounds

        session.sessionPreset = .hd1280x720
        guard session.canAddInput(videoDeviceInput) else { return }
        session.addInput(videoDeviceInput)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = videoOrientation

        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        resultsLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoBufferQueue"))

        guard
            session.canAddOutput(videoOutput),
            session.canAddOutput(photoOutput)
        else { return }

        session.addOutput(videoOutput)
        session.addOutput(photoOutput)

        videoOutput.connection(with: .video)?.videoOrientation = videoOrientation
        photoOutput.connection(with: .video)?.videoOrientation = videoOrientation

        sessionSetupSucceed = true
        performRequests = true

        let blur = UIBlurEffect(style: .regular)
        blurView = UIVisualEffectView(effect: blur)
        blurView.frame = screenRect
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isHidden = true

        DispatchQueue.main.async { [unowned self] in
            view.layer.addSublayer(previewLayer)
            view.addSubview(blurView)
            view.layer.addSublayer(detectionLayer)
        }
    }

    private func setupRequests() {
        let textRectanglesRequest = VNDetectTextRectanglesRequest(completionHandler: detectionHandler)
        textRectanglesRequest.reportCharacterBoxes = true
        
        requests = [textRectanglesRequest]
    }

    private func setupInterface() {
        button = Button(color: interfaceColor)
        button.tapAction = getDetections

        DispatchQueue.main.async { [unowned self] in
            view.addSubview(button)
        }
    }

    private func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = interfaceColor
        boxLayer.cornerRadius = 4
        return boxLayer
    }

    private func detectionHandler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: { [unowned self] in
            if let results = request.results {
                guard let observations = results as? [VNTextObservation] else { return }
                extractDetections(observations)
            }
        })
    }

    private func extractDetections(_ observations: [VNTextObservation]) {
        detectionLayer.sublayers = nil
        let rectsArray = RectsArray()
            
        for observation in observations {
            rectsArray.append(observation.boundingBox)
        }

        guard let biggestRect = rectsArray.getBiggest() else { return }

        let objectBounds = VNImageRectForNormalizedRect(biggestRect, Int(screenRect.size.width), Int(screenRect.size.height))
        let textRect = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY,
                          width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
        let increased = textRect.increase(byPercentage: 1)
            
        let textBounds = drawBoundingBox(increased)
        detectedRect = increased
        detectionLayer.addSublayer(textBounds)
    }

    private func getDetections() {
        guard sessionSetupSucceed else { return }

        DispatchQueue.main.async { [unowned self] in
            button.tapAction = nil
            performRequests = false
            detectionLayer.sublayers = nil
        }

        let settings = AVCapturePhotoSettings()
        let captureProcessor = PhotoCaptureProcessor()
        capturesInProgress.insert(captureProcessor)

        captureProcessor.completionHandler = { uiImage in
            DispatchQueue.main.async { [unowned self] in
                guard
                    let cropped = uiImage.cropping(to: previewLayer, toSizeOf: detectedRect),
                    let corrected = cropped.orientationCorrectedImage,
                    let cgImage = corrected.cgImage
                else { return }
                resultsView = ResultsView(cgImage: cgImage, screenRect: screenRect, interfaceColor: interfaceColor)
                view.addSubview(resultsView)
                button.tapAction = exitView
                blurView.isHidden = false

                capturesInProgress.remove(captureProcessor)
            }
        }

        sessionQueue.async { [unowned self] in
            photoOutput.capturePhoto(with: settings, delegate: captureProcessor)
        }
    }

    private func exitView() {
        DispatchQueue.main.async { [unowned self] in
            resultsView.removeFromSuperview()
            resultsView = nil
            button.tapAction = getDetections

            performRequests = true
            blurView.isHidden = true
        }
    }
}
