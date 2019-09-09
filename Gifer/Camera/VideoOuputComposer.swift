//
//  VideoOuputComposer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit

class VideoOuputComposer {
    
    var outputs = [AVCaptureMovieFileOutput]()
    var outputURLs = [URL]()
    var outputAssets: [AVAsset] {
        return outputURLs.map { AVAsset(url: $0) }
    }
    var recordedDurations = [CMTime]()
    
    var activeOutput: AVCaptureMovieFileOutput? {
        return outputs.last
    }
    
    var duration: CMTime {
        let outputDuration = outputs.reduce(CMTime.zero, { (t, output) -> CMTime in
            t + output.recordedDuration
        })
        return recordedDurations.reduce(outputDuration) { $0 + $1 }
    }
    
    var composedURL: URL {
        fatalError()
    }
    
    lazy var directory: URL = {
        let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("capturedVideo")
        
        var t = ObjCBool(true)
        if !FileManager.default.fileExists(atPath: url.absoluteString, isDirectory: &t) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        return url
    }()
    
    func createNewOutput() -> AVCaptureMovieFileOutput {
        let output = AVCaptureMovieFileOutput()
        output.maxRecordedDuration = CameraMode.maxVideoDuration - duration
        outputs.append(output)
        outputURLs.append(createOutputURL())
        return output
    }
    
    func createOutputURL() -> URL {
        return directory.appendingPathComponent(String.random(length: 10) + ".mov")
    }
    
    func getOutputURL(for output: AVCaptureMovieFileOutput)  -> URL {
        return zip(outputs, outputURLs).filter { $0.0 == output }.first.map { $0.1 }!
    }
    
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate, in session: AVCaptureSession) {
        let output = createNewOutput()
        session.outputs.forEach { output in
            if output is AVCaptureMovieFileOutput {
                session.removeOutput(output)
            }
        }
        session.addOutput(output)
        output.startRecording(to: getOutputURL(for: output), recordingDelegate: delegate)
    }
    
    func pauseRecording(session: AVCaptureSession) {
        if let last = outputs.last {
            recordedDurations.append(last.recordedDuration)
        }
        
        outputs.forEach { $0.stopRecording() }
        session.removeOutput(outputs.last!)
    }
    
    func clearFiles() {
        if let urls = FileManager.default.enumerator(atPath: directory.path) {
            for filename in urls {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename as! String))
            }
        }
    }
    
    func resetRecording(on session: AVCaptureSession) {
        clearFiles()
        session.outputs.forEach { session.removeOutput($0) }
        recordedDurations.removeAll()
    }
    
    func compose() -> AVAsset {
        let composition = AVMutableComposition()
        let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var t = CMTime.zero
        guard outputAssets.count > 0 else { fatalError() }
        
        for asset in outputAssets.reversed() {
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                try? compositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
                compositionTrack?.preferredTransform = videoTrack.preferredTransform
                t = t + asset.duration
            }
        }
        return composition
    }
}
