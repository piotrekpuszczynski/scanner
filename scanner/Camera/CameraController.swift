//
//  CameraController.swift
//

import AVFoundation
import UIKit

class CameraController: UIViewController {
    private lazy var session = AVCaptureSession()
    private lazy var photoOutput = AVCapturePhotoOutput()

    private lazy var previewView = UIView()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)

    private let sessionQueue = DispatchQueue(label: "Session Queue")

    private var camera: AVCaptureDevice?

    private var sessionSetupSucceed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        previewLayer.videoGravity = .resizeAspectFill
        previewView.frame = view.bounds
        previewView.layer.addSublayer(previewLayer)
        view.insertSubview(previewView, at: 0)

        camera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first

        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                sessionQueue.async { [unowned self] in
                    configureSession()
                }
            case .notDetermined, .denied:
                AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                    if granted {
                        sessionQueue.async { [unowned self] in
                            configureSession()
                        }
                    }
                }
            default:
                break
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let _currentInput = session.inputs.first {
            session.removeInput(_currentInput)
        }

        guard
            let input = try? AVCaptureDeviceInput(device: camera!),
            session.canAddInput(input) else { return }

        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            return
        }

        session.addOutput(photoOutput)
        session.commitConfiguration()

        sessionSetupSucceed = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async { [unowned self] in
            if sessionSetupSucceed {
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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        previewLayer.frame = previewView.layer.bounds
    }
}
