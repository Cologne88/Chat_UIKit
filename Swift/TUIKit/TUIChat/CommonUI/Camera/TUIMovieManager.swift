//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

import AVFoundation
import Foundation

class TUIMovieManager {
    private var readyToRecordVideo = false
    private var readyToRecordAudio = false
    private let movieWritingQueue = DispatchQueue(label: "com.tui.Movie.Writing.Queue")
    
    private var movieURL: URL
    private var movieWriter: AVAssetWriter?
    private var movieAudioInput: AVAssetWriterInput?
    private var movieVideoInput: AVAssetWriterInput?
    
    var referenceOrientation: AVCaptureVideoOrientation = .portrait
    var currentOrientation: AVCaptureVideoOrientation = .portrait
    var currentDevice: AVCaptureDevice = AVCaptureDevice.default(for: .video)!
    
    init() {
        movieURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TUICaptureTempMovie.mp4")
    }
    
    func start(handle: @escaping (Error?) -> Void) {
        movieWritingQueue.async { [weak self] in
            guard let self = self else { return }
            self.removeFile(fileURL: self.movieURL)
            var error: Error?
            if self.movieWriter == nil {
                do {
                    self.movieWriter = try AVAssetWriter(url: self.movieURL, fileType: .mp4)
                } catch let writerError {
                    error = writerError
                }
            }
            handle(error)
        }
    }
    
    func stop(handle: @escaping (URL?, Error?) -> Void) {
        movieWritingQueue.async { [weak self] in
            guard let self = self else { return }
            self.readyToRecordVideo = false
            self.readyToRecordAudio = false
            
            if let movieWriter = self.movieWriter, movieWriter.status == .writing {
                movieWriter.finishWriting {
                    DispatchQueue.main.async {
                        if movieWriter.status == .completed {
                            handle(self.movieURL, nil)
                        } else {
                            handle(nil, movieWriter.error)
                        }
                        self.movieWriter = nil
                    }
                }
            } else {
                self.movieWriter?.cancelWriting()
                self.movieWriter = nil
                DispatchQueue.main.async {
                    handle(nil, NSError(domain: "com.tui.Movie.Writing", code: 0, userInfo: [NSLocalizedDescriptionKey: "AVAssetWriter status error"]))
                }
            }
        }
    }
    
    func writeData(connection: AVCaptureConnection, video: AVCaptureConnection, audio: AVCaptureConnection, buffer: CMSampleBuffer) {
        let bufferCopy = buffer
        movieWritingQueue.async { [weak self] in
            guard let self = self else { return }
            if connection == video {
                if !self.readyToRecordVideo {
                    self.readyToRecordVideo = self.setupAssetWriterVideoInput(currentFormatDescription: CMSampleBufferGetFormatDescription(bufferCopy)!) == nil
                }
                if self.inputsReadyToRecord() {
                    self.writeSampleBuffer(sampleBuffer: bufferCopy, ofType: .video)
                }
            } else if connection == audio {
                if !self.readyToRecordAudio {
                    self.readyToRecordAudio = self.setupAssetWriterAudioInput(currentFormatDescription: CMSampleBufferGetFormatDescription(bufferCopy)!) == nil
                }
                if self.inputsReadyToRecord() {
                    self.writeSampleBuffer(sampleBuffer: bufferCopy, ofType: .audio)
                }
            }
        }
    }
    
    private func writeSampleBuffer(sampleBuffer: CMSampleBuffer, ofType mediaType: AVMediaType) {
        guard let movieWriter = movieWriter else { return }
        
        if movieWriter.status == .unknown {
            if movieWriter.startWriting() {
                movieWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            } else {
                print(movieWriter.error ?? "Unknown error")
            }
        }
        
        if movieWriter.status == .writing {
            if mediaType == .video {
                guard let movieVideoInput = movieVideoInput, movieVideoInput.isReadyForMoreMediaData else { return }
                if !movieVideoInput.append(sampleBuffer) {
                    print(movieWriter.error ?? "Unknown error")
                }
            } else if mediaType == .audio {
                guard let movieAudioInput = movieAudioInput, movieAudioInput.isReadyForMoreMediaData else { return }
                if !movieAudioInput.append(sampleBuffer) {
                    print(movieWriter.error ?? "Unknown error")
                }
            }
        }
    }
    
    private func inputsReadyToRecord() -> Bool {
        return readyToRecordVideo && readyToRecordAudio
    }
    
    private func setupAssetWriterAudioInput(currentFormatDescription: CMFormatDescription) -> Error? {
        let currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription)!.pointee
        let channelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, sizeOut: nil)
        let dataLayout = channelLayout != nil ? Data(bytes: channelLayout!, count: MemoryLayout<AudioChannelLayout>.size) : Data()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: currentASBD.mSampleRate,
            AVChannelLayoutKey: dataLayout,
            AVNumberOfChannelsKey: currentASBD.mChannelsPerFrame,
            AVEncoderBitRatePerChannelKey: 64000
        ]
        
        if movieWriter?.canApply(outputSettings: settings, forMediaType: .audio) == true {
            movieAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
            movieAudioInput?.expectsMediaDataInRealTime = true
            if movieWriter?.canAdd(movieAudioInput!) == true {
                movieWriter?.add(movieAudioInput!)
            } else {
                return movieWriter?.error
            }
        } else {
            return movieWriter?.error
        }
        return nil
    }
    
    private func setupAssetWriterVideoInput(currentFormatDescription: CMFormatDescription) -> Error? {
        let dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription)
        let numPixels = dimensions.width * dimensions.height
        let bitsPerPixel: CGFloat = numPixels < (640 * 480) ? 4.05 : 11.0
        let compression: [String: Any] = [
            AVVideoAverageBitRateKey: Int(numPixels) * Int(bitsPerPixel),
            AVVideoMaxKeyFrameIntervalKey: 30
        ]
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
            AVVideoCompressionPropertiesKey: compression
        ]
        
        if movieWriter?.canApply(outputSettings: settings, forMediaType: .video) == true {
            movieVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            movieVideoInput?.expectsMediaDataInRealTime = true
            movieVideoInput?.transform = transformFromCurrentVideoOrientationToOrientation(orientation: referenceOrientation)
            if movieWriter?.canAdd(movieVideoInput!) == true {
                movieWriter?.add(movieVideoInput!)
            } else {
                return movieWriter?.error
            }
        } else {
            return movieWriter?.error
        }
        return nil
    }
    
    private func transformFromCurrentVideoOrientationToOrientation(orientation: AVCaptureVideoOrientation) -> CGAffineTransform {
        let orientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(orientation: orientation)
        let videoOrientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(orientation: currentOrientation)
        let angleOffset: CGFloat
        if currentDevice.position == .back {
            angleOffset = videoOrientationAngleOffset - orientationAngleOffset + .pi / 2
        } else {
            angleOffset = orientationAngleOffset - videoOrientationAngleOffset + .pi / 2
        }
        return CGAffineTransform(rotationAngle: angleOffset)
    }
    
    private func angleOffsetFromPortraitOrientationToOrientation(orientation: AVCaptureVideoOrientation) -> CGFloat {
        switch orientation {
        case .portrait:
            return 0.0
        case .portraitUpsideDown:
            return .pi
        case .landscapeRight:
            return -.pi / 2
        case .landscapeLeft:
            return .pi / 2
        @unknown default:
            return 0.0
        }
    }
    
    private func removeFile(fileURL: URL) {
        let fileManager = FileManager.default
        let filePath = fileURL.path
        if fileManager.fileExists(atPath: filePath) {
            do {
                try fileManager.removeItem(atPath: filePath)
                print("Succeed to delete file")
            } catch {
                assertionFailure(error.localizedDescription)
                print("Failed to delete file: \(error)")
            }
        }
    }
}
