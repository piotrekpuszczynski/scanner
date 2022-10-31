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

    internal var requests: Array<VNRequest>! = nil

    private var videoOrientation: AVCaptureVideoOrientation = .portrait

    private var permissionGranted = false
    private var sessionSetupSucceed = false
    internal var performRequests = false

    private let interfaceColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    private var capturesInProgress = Set<PhotoCaptureProcessor>()

    private var textRect: CGRect! = nil

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

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        screenRect = UIScreen.main.bounds
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        switch UIDevice.current.orientation {
            case UIDeviceOrientation.portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
            case UIDeviceOrientation.landscapeLeft:
                videoOrientation = .landscapeRight
            case UIDeviceOrientation.landscapeRight:
                videoOrientation = .landscapeLeft
            case UIDeviceOrientation.portrait:
                videoOrientation = .portrait
            default:
                break
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

        DispatchQueue.main.async { [unowned self] in
            view.layer.addSublayer(previewLayer)
            view.layer.addSublayer(detectionLayer)
        }
    }

    private func setupRequests() {
        let textRectanglesRequest = VNDetectTextRectanglesRequest(completionHandler: detectionHandler)
        textRectanglesRequest.reportCharacterBoxes = true
        
        requests = [textRectanglesRequest]
    }

    private var photoButtonRect: CGRect! = nil
    private var photoButton: UIButton! = nil
    private var resultsView: ResultsView! = nil
    private var returnButtonRect: CGRect! = nil
    private var returnButton: Button! = nil

    private func setupInterface() {
        photoButtonRect = CGRect(x: screenRect.size.width - 100, y: screenRect.size.height - 100, width: 50, height: 50)
        photoButton = Button(cgRect: photoButtonRect, color: interfaceColor, action: #selector(takePhoto))

        DispatchQueue.main.async { [unowned self] in
            view.addSubview(photoButton)
        }

        returnButtonRect = CGRect(x: screenRect.size.width - 100, y: screenRect.size.height - 150, width: 50, height: 50)
        returnButton = Button(cgRect: returnButtonRect, color: interfaceColor, action: #selector(exitView))
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
        textRect = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY,
                          width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            
        let boxLayer = drawBoundingBox(textRect)
        detectionLayer.addSublayer(boxLayer)
    }

    @objc
    private func takePhoto(_ sender: UIButton!) {
        guard sessionSetupSucceed else { return }

        let settings = AVCapturePhotoSettings()

        let captureProcessor = PhotoCaptureProcessor()
        capturesInProgress.insert(captureProcessor)

        DispatchQueue.main.async { [unowned self] in
            photoButton.removeFromSuperview()
            performRequests = false
        }

        captureProcessor.cropBounds = textRect
        captureProcessor.orientation = videoOrientation
        captureProcessor.completionHandler = { cgImage in
            DispatchQueue.main.async { [unowned self] in
                resultsView = ResultsView(cgImage: cgImage, rect: screenRect, interfaceColor: interfaceColor)

                view.addSubview(resultsView)
                view.addSubview(returnButton)

                capturesInProgress.remove(captureProcessor)
            }
        }

        sessionQueue.async { [unowned self] in
            photoOutput.capturePhoto(with: settings, delegate: captureProcessor)
        }
    }

    @objc
    private func exitView(_ sender: UIButton!) {
        DispatchQueue.main.async { [unowned self] in
            resultsView.removeFromSuperview()
            returnButton.removeFromSuperview()
            view.addSubview(photoButton)

            performRequests = true
        }
    }
}
