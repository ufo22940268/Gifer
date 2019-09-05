//
//  CameraViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVFoundation

let maxCaptureVideoLength = Double(20).toTime()

class CameraViewController: UIViewController {
    
    var types: [CameraType] = CameraType.allCases
    var photos: [URL] = [URL]()

    @IBOutlet weak var labelCollectionView: UICollectionView!
    @IBOutlet weak var shotView: ShotView!
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var cameraHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomPanel: UIStackView!
    @IBOutlet weak var contentStackView: UIStackView!
    
    lazy var captureSession: AVCaptureSession = {
        return AVCaptureSession()
    }()
    
    lazy var videoOutput: AVCaptureMovieFileOutput = {
        let output = AVCaptureMovieFileOutput()
        output.maxRecordedDuration = Double(20).toTime()
        return output
    }()
    
    lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        return output
    }()
    
    lazy var outputURL: URL? = {
       let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("capture.mov")
        return url
    }()
    
    var mode: CameraMode! {
        didSet {
            shotView.mode = self.mode            
        }
    }
    
    lazy var shotPhotoCountView: ShotPhotoCountView = {
        let view = ShotPhotoCountView().useAutoLayout()
        view.alpha = 0
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DarkMode.enable(in: self)
        
        mode = .photos
        shotView.customDelegate = self
        
        if !UIDevice.isSimulator {
            captureSession.beginConfiguration()
            guard let deviceInput = buildDeviceInput(on: .back) else  { return }
            captureSession.addInput(deviceInput)
            captureSession.sessionPreset = .medium
            captureSession.addOutput(videoOutput)
            captureSession.addOutput(photoOutput)
            captureSession.commitConfiguration()
            
            previewView.videoPreviewLayer.session = self.captureSession
            captureSession.startRunning()
            let captureSize = getCaptureResolution()
            let previewContainerSize = previewView.superview!.bounds.size
            if captureSize.width/previewContainerSize.width > captureSize.height/previewContainerSize.height {
                cameraHeightConstraint.constant = previewContainerSize.height
                cameraWidthConstraint.constant = captureSize.width/captureSize.height*previewContainerSize.height
            } else {
                cameraWidthConstraint.constant = previewContainerSize.width
                cameraHeightConstraint.constant = captureSize.height/captureSize.width*previewContainerSize.width
            }
        }
        
        contentStackView.addSubview(shotPhotoCountView)
        NSLayoutConstraint.activate([
            shotPhotoCountView.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: -40),
            shotPhotoCountView.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            ])
    }
    
    func buildDeviceInput(on position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: position)
        return try? AVCaptureDeviceInput(device: videoDevice!)
    }
    
    private func getCaptureResolution() -> CGSize {
        // Define default resolution
        var resolution = CGSize(width: 0, height: 0)
        
        // Get cur video device
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .unspecified)
        // Set if video portrait orientation
//        let portraitOrientation = orientation == .Portrait || orientation == .PortraitUpsideDown
        let portraitOrientation = true

        // Get video dimensions
        if let formatDescription = videoDevice?.activeFormat.formatDescription {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            resolution = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            if (portraitOrientation) {
                resolution = CGSize(width: resolution.height, height: resolution.width)
            }
        }
        
        // Return resolution
        return resolution
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (labelCollectionView.visibleCells.first { (cell) -> Bool in
            labelCollectionView.indexPath(for: cell)?.row == 0
        } as? CameraTypeCell)?.isHighlighted = true
    }
    
    override func viewDidLayoutSubviews() {
        let itemWidth = (labelCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width
        labelCollectionView.contentInset = .init(top: 0, left: (view.bounds.width - itemWidth)/2, bottom: 0, right: (view.bounds.width - itemWidth)/2)
    }
    
    func nothingChanges() -> Bool {
        return true
    }
    
    @IBAction func onResetCamera(_ sender: Any) {
        print("onResetCamera")
        shotView.resetRecording()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        if nothingChanges() {
            dismiss(animated: true, completion: nil)
        } else {
            // TODO: Prompt for dimissing changes.
        }
    }
    
    @IBAction func onDone(_ sender: Any) {
    }
    
    @IBAction func onToggleCamera(_ sender: Any) {
        guard let input = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        captureSession.removeInput(input)
        let newPosition: AVCaptureDevice.Position
        if input.device.position == .back {
            newPosition = .front
        } else {
            newPosition = .back
        }
        if let newInput = buildDeviceInput(on: newPosition) {
            captureSession.addInput(newInput)
        }
    }
}

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return types.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CameraTypeCell
        let type = types[indexPath.row]
        cell.labelView.text = type.title
        return cell
    }
}

extension CameraViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndex = labelCollectionView.indexPathForItem(at: CGPoint(x: labelCollectionView.contentOffset.x + labelCollectionView.frame.width/2, y: labelCollectionView.frame.height/2))
        labelCollectionView.visibleCells.forEach { (cell) in
            let cell = cell as! CameraTypeCell
            cell.isHighlighted = labelCollectionView.indexPath(for: cell) == currentIndex
        }
    }
}

// MARK: Shot view delegation
extension CameraViewController: ShotViewDelegate {
    func onStartRecordingByUser() {
        guard let outputURL  = outputURL else { return }
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
        }
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    func onStopRecordingByUser() {
        videoOutput.stopRecording()
    }
    
    func onTakePhoto(_ shotView: ShotView) {
        if !UIDevice.isSimulator {
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(format: nil), delegate: self)
        }
        shotPhotoCountView.updateCount(photos.count)
    }
}

// MARK: Video output delegation
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("writing to file ...")
    }
}

// MARK: Photo output delegation
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if photos.count == 0 {
            CameraPhotoStorage.instance.clear()
        }
        let data = photo.fileDataRepresentation()
        if let url = CameraPhotoStorage.instance.save(data) {
            photos.append(url)
        }

    }
}

enum CameraType: CaseIterable {
    case video
    case photos
    
    var title: String {
        switch self {
        case .video:
            return NSLocalizedString("camera_video", comment: "")
        case .photos:
            return NSLocalizedString("camera_photos", comment: "")
        }
    }
}

class CameraTypeCell: UICollectionViewCell {
    
    @IBOutlet weak var labelView: UILabel!
    
    override var isHighlighted: Bool {
        didSet {
            labelView.textColor = isHighlighted ? .white : .lightText
        }
    }
}

enum CameraMode {
    case video
    case photos
}
