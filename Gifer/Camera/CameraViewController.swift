//
//  CameraViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    var modes: [CameraMode] = CameraMode.allCases
    var photos: [URL] = [URL]() {
        didSet {
            updateButtonsStatus()
        }
    }

    @IBOutlet weak var labelCollectionView: UICollectionView!
    @IBOutlet weak var shotView: ShotView!
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var cameraHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomPanel: UIStackView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet var labelsPanGesture: UIPanGestureRecognizer!
    
    var recordedVideoDuration: CMTime? {
        didSet {
            updateButtonsStatus()
        }
    }
    
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
    
    var currentLabelIndex: IndexPath? {
        return labelCollectionView.indexPathForItem(at: CGPoint(x: labelCollectionView.contentOffset.x + labelCollectionView.frame.width/2, y: labelCollectionView.frame.height/2))
    }

    
    var mode: CameraMode! {
        didSet {
            UIView.transition(with: shotView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.shotView.mode = self.mode
            }, completion: nil)
            updateButtonsStatus()
            updateProgress()
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
        
        mode = .video
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
        
        updateButtonsStatus()
    }
    
    func updateButtonsStatus() {
        switch mode! {
        case .video:
            resetButton.isEnabled = (recordedVideoDuration?.seconds ?? 0) > 0
            doneButton.isEnabled = (recordedVideoDuration?.seconds ?? 0) > 0
        case .photos:
            resetButton.isEnabled = photos.count > 0
            doneButton.isEnabled = photos.count > 0
        }
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
        switch mode! {
        case .video:
            shotView.resetRecording()
        case .photos:
            photos.removeAll()
            shotPhotoCountView.alpha = 0
        }
        shotView.progress = 0
    }
    
    @IBAction func onCancel(_ sender: Any) {
        if nothingChanges() {
            dismiss(animated: true, completion: nil)
        } else {
            // TODO: Prompt for dimissing changes.
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEdit", let editVC = segue.destination as? EditViewController {
            switch mode! {
            case .video:
                fatalError()
            case .photos:
                editVC.generator = ItemGeneratorWithPhotoFiles(photos: photos)
            }
        }
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
    
    @IBAction func onPanLabelCollection(_ sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            let translate = sender.translation(in: labelCollectionView)
            if abs(translate.x) > 20 {
                if translate.x > 0 {
                    moveLabel(by: -1)
                } else {
                    moveLabel(by: 1)
                }
            }
        }
    }
    
    func moveLabel(by deltaIndex: Int) {
        let currentIndex = modes.enumerated().first { $0.element == mode }!.offset
        if (currentIndex == 0 && deltaIndex < 0) || (currentIndex == modes.count - 1 && deltaIndex > 0) {
            return
        }
        
        labelsPanGesture.isEnabled = false
        mode = modes.enumerated().first { $0.offset == currentIndex + deltaIndex }!.element
        labelCollectionView.selectItem(at: IndexPath(row: currentIndex + deltaIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.labelsPanGesture.isEnabled = true
        }
    }
}

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return modes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CameraTypeCell
        let type = modes[indexPath.row]
        cell.labelView.text = type.title
        return cell
    }
}

// MARK: Label collection delegate
extension CameraViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        labelCollectionView.visibleCells.forEach { (cell) in
            let cell = cell as! CameraTypeCell
            cell.isHighlighted = labelCollectionView.indexPath(for: cell) == currentLabelIndex
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.mode = modes[currentLabelIndex!.row]
    }
}

// MARK: Shot view delegation
extension CameraViewController: ShotViewDelegate {
    func onStartRecordingByUser() {
        guard let outputURL  = outputURL, !UIDevice.isSimulator else { return }
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
        }
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)        
    }
    
    func onStopRecordingByUser() {
        videoOutput.stopRecording()
    }
    
    func onRecording(_ shotView: ShotView) {
        print(videoOutput.recordedDuration.seconds)
        shotView.updateProgress(byVideoDuration: videoOutput.recordedDuration)
    }
    
    func onTakePhoto(_ shotView: ShotView) {
        if !UIDevice.isSimulator {
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(format: nil), delegate: self)
        }
    }
    
    func updateProgress() {
        switch mode! {
        case .video:
            if let recordedVideoDuration = recordedVideoDuration {
                shotView.updateProgress(byVideoDuration: recordedVideoDuration)
            }
        case .photos:
            shotView.updateProgress(byPhotoCount: photos.count)
        }
    }
}

// MARK: Video output delegation
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        recordedVideoDuration = output.recordedDuration
        updateProgress()
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
        
        shotView.updateProgress(byPhotoCount: photos.count)
        shotPhotoCountView.updateCount(photos.count)
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

enum CameraMode: CaseIterable {
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

    static let maxPhotoCount = 200
    static let maxVideoDuration = Double(20).toTime()
}
