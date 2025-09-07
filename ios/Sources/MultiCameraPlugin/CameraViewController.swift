//
//  CameraViewController.swift
//  CapacitorMultiCamera
//
//  Created by Sebastian Tamayo lasso on 6/09/25.
//
import UIKit
import AVFoundation

protocol CameraDelegate: AnyObject {
    func cameraDidFinish(images: [UIImage], resultType: CameraResultType, saveToGallery: Bool)
    func cameraDidCancel()
}

class CameraViewController: UIViewController {
    weak var delegate: CameraDelegate?
    var resultType: CameraResultType = CameraResultType.uri
    var saveToGallery: Bool = false

    // MARK: - AVFoundation
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    private var capturedImages: [UIImage] = []

    // MARK: - UI Elements
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let torchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let captureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 35
        button.backgroundColor = .white
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let zoomButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1x", for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()


    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupCamera()
        setupUI()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    // MARK: - Setup Camera
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            configureCamera(device: device)
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        // ✅ mover startRunning al background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }


    private func configureCamera(device: AVCaptureDevice) {
        do {
            currentDevice = device
            let input = try AVCaptureDeviceInput(device: device)
            if let currentInput = currentInput {
                captureSession.removeInput(currentInput)
            }
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                currentInput = input
            }
        } catch {
            print("Error configuring camera: \(error)")
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        // UICollectionView para thumbnails
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 12

        // Agregar subviews
        [closeButton, torchButton, captureButton, confirmButton, switchCameraButton, zoomButton]
            .forEach { view.addSubview($0) }

        // AutoLayout
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        torchButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        zoomButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            torchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            torchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            torchButton.widthAnchor.constraint(equalToConstant: 40),
            torchButton.heightAnchor.constraint(equalToConstant: 40),

            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            confirmButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -50),
            confirmButton.widthAnchor.constraint(equalToConstant: 60),
            confirmButton.heightAnchor.constraint(equalToConstant: 60),

            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 40),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 40),

            zoomButton.bottomAnchor.constraint(equalTo: switchCameraButton.topAnchor, constant: -12),
            zoomButton.centerXAnchor.constraint(equalTo: switchCameraButton.centerXAnchor),
            zoomButton.widthAnchor.constraint(equalToConstant: 50),
            zoomButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmPhotos), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        zoomButton.addTarget(self, action: #selector(showZoomOptions), for: .touchUpInside)
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func confirmPhotos() {
        delegate?.cameraDidFinish(images: capturedImages, resultType: resultType, saveToGallery: saveToGallery)
    }

    @objc private func toggleTorch() {
        guard let device = currentDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func switchCamera() {
        guard let currentInput = currentInput else { return }
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back

        if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) {
            configureCamera(device: newDevice)
        }
    }

    @objc private func showZoomOptions() {
        let alert = UIAlertController(title: "Zoom", message: "Select zoom level", preferredStyle: .actionSheet)
        let options: [CGFloat] = [0.5, 1.0, 2.0]

        for option in options {
            alert.addAction(UIAlertAction(title: "\(option)x", style: .default, handler: { _ in
                self.setZoom(level: option)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func setZoom(level: CGFloat) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(level, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
            zoomButton.setTitle("\(level)x", for: .normal)
        } catch {
            print("Zoom error: \(error)")
        }
    }

    @objc private func cancel() {
        delegate?.cameraDidCancel()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    /// Delegate method called when the capture output has finished processing a photo.
    ///
    /// - Parameters:
    ///   - output: The `AVCapturePhotoOutput` instance responsible for capturing the photo.
    ///   - photo: The captured `AVCapturePhoto` object containing the image data.
    ///   - error: An optional error if the capture or processing failed.
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let data = photo.fileDataRepresentation(),
           // Try to convert that data into a UIImage
           let image = UIImage(data: data) {
            capturedImages.append(image)
            
            confirmButton.isHidden = capturedImages.isEmpty
        }
    }
}

