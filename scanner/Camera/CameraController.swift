//
//  CameraController.swift
//

import AVFoundation
import UIKit

class CameraController: UIViewController {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "Session Queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var detector: FastDetector! = nil

    private var screenRect: CGRect! = nil

    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private var cameraDarken = CALayer()
    private let detectionLayer = CALayer()
    private let resultsLayer = CALayer()

    private var videoOrientation: AVCaptureVideoOrientation = .portrait

    private var permissionGranted = false
    private var sessionSetupSucceed = false

    private let interfaceColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    private var capturesInProgress = Set<PhotoCaptureProcessor>()

    private var detectedRect: CGRect! = nil
    
    private var button = Button(xByPercentage: 0.8, yByPercentage: 0.9)
    private var resultsView: ResultsView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            
            setupCaptureSession()
            setupDetector()
            setupInterface()

            session.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async { [unowned self] in
            if sessionSetupSucceed {
                setupDetector()
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
//        videoOutput.setSampleBufferDelegate(detector, queue: DispatchQueue(label: "videoBufferQueue"))

        guard
            session.canAddOutput(videoOutput),
            session.canAddOutput(photoOutput)
        else { return }

        session.addOutput(videoOutput)
        session.addOutput(photoOutput)

        videoOutput.connection(with: .video)?.videoOrientation = videoOrientation
        photoOutput.connection(with: .video)?.videoOrientation = videoOrientation

        sessionSetupSucceed = true

        cameraDarken.frame = screenRect
        cameraDarken.backgroundColor = UIColor.black.withAlphaComponent(0.8).cgColor
        cameraDarken.isHidden = true

        DispatchQueue.main.async { [unowned self] in
            view.layer.addSublayer(previewLayer)
            view.layer.addSublayer(cameraDarken)
            view.layer.addSublayer(detectionLayer)
        }
    }

    private func setupDetector() {
        detector = FastVision(layer: detectionLayer, screenRect: screenRect, color: interfaceColor)
        videoOutput.setSampleBufferDelegate(detector, queue: DispatchQueue(label: "videoBufferQueue"))
    }

    private func setupInterface() {
        button.tapAction = getDetections

        DispatchQueue.main.async { [unowned self] in
            view.addSubview(button)
        }
    }

    private func callFromDetector() {
        detectedRect = detector?.rectChanged()
    }

    private func getDetections() {
        guard sessionSetupSucceed else { return }

        DispatchQueue.main.async { [unowned self] in
            button.tapAction = nil
            detector.performRequests = false
            detectionLayer.isHidden = true
        }

        let settings = AVCapturePhotoSettings()
        let captureProcessor = PhotoCaptureProcessor()
        capturesInProgress.insert(captureProcessor)

        captureProcessor.completionHandler = { uiImage in
            DispatchQueue.main.async { [unowned self] in
                callFromDetector()
                guard
                    let cropped = uiImage.cropping(to: previewLayer, toSizeOf: detectedRect),
                    let corrected = cropped.orientationCorrectedImage,
                    let cgImage = corrected.cgImage
                else { return }
                resultsView = ResultsView(cgImage: cgImage, screenRect: screenRect)
                view.insertSubview(resultsView, belowSubview: button)
                button.tapAction = exitView
                cameraDarken.isHidden = false

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
            button.tapAction = getDetections

            detector.performRequests = true
            cameraDarken.isHidden = true
            detectionLayer.isHidden = false
        }
    }
}
