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
            try!     FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
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
        return directory.appendingPathComponent(String.random(length: 10))
    }
    
    func getOutputURL(for output: AVCaptureMovieFileOutput)  -> URL {
        return zip(outputs, outputURLs).filter { $0.0 == output }.first.map { $0.1 }!
    }
    
    func startRecording(delegate: AVCaptureFileOutputRecordingDelegate, in session: AVCaptureSession) {
        let output = createNewOutput()
        session.outputs.forEach { session.removeOutput($0) }
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
    
    
    func reset() {
        
    }
    
    func compose() {
        
    }
}
