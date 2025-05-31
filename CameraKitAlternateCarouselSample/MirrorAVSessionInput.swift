import AVFoundation
import Foundation
import SCSDKCameraKit

class MirrorAVSessionInput: NSObject, Input {
    var destination: InputDestination?
    private(set) var frameSize: CGSize
    var frameOrientation: AVCaptureVideoOrientation {
        didSet {
            destination?.inputChangedAttributes(self)
        }
    }
    var position: AVCaptureDevice.Position {
        didSet {
            guard position != oldValue else { return }
            videoSession.beginConfiguration()
            if let videoDeviceInput { videoSession.removeInput(videoDeviceInput) }
            if let device = captureDevice {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if videoSession.canAddInput(input) { videoSession.addInput(input) }
                    update(input: input, isAsync: false)
                    videoSession.commitConfiguration()
                    destination?.inputChangedAttributes(self)
                } catch {
                    debugPrint("[\(String(describing: self))]: Failed to add \(position) input")
                }
            }
        }
    }

    private var captureDevice: AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
    }
    
    private var audioDevice: AVCaptureDevice? {
        AVCaptureDevice.default(for: .audio)
    }

    var isRunning: Bool { videoSession.isRunning }
    var horizontalFieldOfView: CGFloat { fieldOfView }

    private var fieldOfView: CGFloat
    var isVideoMirrored: Bool {
        didSet {
            updateConnection()
            destination?.inputChangedAttributes(self)
        }
    }
    private var format: AVCaptureDevice.Format?
    private var prevCaptureInput: AVCaptureInput?
    private var videoOrientation: AVCaptureVideoOrientation

    private let context = CIContext()
    private let videoSession: AVCaptureSession
    private let videoOutput: AVCaptureVideoDataOutput
    private let audioOutput: AVCaptureAudioDataOutput

    private var videoDeviceInput: AVCaptureDeviceInput? {
        deviceInput(for: .video, session: videoSession)
    }
    
    private var audioDeviceInput: AVCaptureDeviceInput? {
        deviceInput(for: .audio, session: videoSession)
    }

    private var videoConnection: AVCaptureConnection? {
        videoOutput.connection(with: .video)
    }

    private let videoQueue: DispatchQueue
    private let configurationQueue: DispatchQueue

    init(session: AVCaptureSession, fieldOfView: CGFloat = Constants.defaultFieldOfView) {
        self.fieldOfView = fieldOfView
        self.videoSession = session
        self.frameOrientation = .portraitUpsideDown // landscapeLeft, landscapeRight, potrait, potraitUpsideDown
        self.configurationQueue = DispatchQueue(label: "com.snap.mirror.avsessioninput.configuration")
        self.videoOutput = AVCaptureVideoDataOutput()
        self.audioOutput = AVCaptureAudioDataOutput()
        self.videoQueue = DispatchQueue(label: "com.snap.mirror.videoOutput")
        self.frameSize = UIScreen.main.bounds.size
        self.position = .front // front, back
        self.isVideoMirrored = false // true, false
        self.videoOrientation = .landscapeLeft // landscapeLeft, landscapeRight, potrait, potraitUpsideDown
        super.init()

        videoSession.beginConfiguration()
        
        // Configure video
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if videoSession.canAddOutput(videoOutput) { videoSession.addOutput(videoOutput) }
        videoConnection?.videoOrientation = videoOrientation
        
        // Configure audio
        audioOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if videoSession.canAddOutput(audioOutput) { videoSession.addOutput(audioOutput) }
        
        // Add audio input
        setupAudioInput()
        
        videoSession.commitConfiguration()
    }
    
    private func setupAudioInput() {
        if let audioDevice = audioDevice {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if videoSession.canAddInput(audioInput) {
                    videoSession.addInput(audioInput)
                    debugPrint("[\(String(describing: self))]: Successfully added audio input")
                } else {
                    debugPrint("[\(String(describing: self))]: Cannot add audio input to session")
                }
            } catch {
                debugPrint("[\(String(describing: self))]: Failed to create audio input: \(error)")
            }
        } else {
            debugPrint("[\(String(describing: self))]: No audio device available")
        }
    }

    func startRunning() {
        restoreFormat()
        videoSession.startRunning()
    }

    func stopRunning() {
        storeFormat()
        videoSession.stopRunning()
    }

    func setVideoOrientation(_ videoOrientation: AVCaptureVideoOrientation) {
        self.videoOrientation = videoOrientation
        destination?.inputChangedAttributes(self)
        configurationQueue.async { [weak self] in
            self?.videoConnection?.videoOrientation = videoOrientation
        }
    }
}

extension MirrorAVSessionInput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output == videoOutput {
            if let input = connection.inputPorts.first?.input, input != prevCaptureInput {
                update(input: input)
                destination?.inputChangedAttributes(self)
            }
            destination?.input(self, receivedVideoSampleBuffer: sampleBuffer)
        } else if output == audioOutput {
            destination?.input(self, receivedAudioSampleBuffer: sampleBuffer)
        }
    }
}

private extension MirrorAVSessionInput {
    func restoreFormat() {
        if let format, let device = videoDeviceInput?.device {
            do {
                try device.lockForConfiguration()
                device.activeFormat = format
                device.unlockForConfiguration()
                self.format = nil
            } catch {
                debugPrint("[\(String(describing: self))]: Failed to restore format")
            }
        }
    }

    func storeFormat() {
        format = videoDeviceInput?.device.activeFormat
    }

    func deviceInput(for mediaType: AVMediaType, session: AVCaptureSession) -> AVCaptureDeviceInput? {
        for input in session.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(mediaType) {
                return deviceInput
            }
        }
        return nil
    }

    func update(input: AVCaptureInput, isAsync: Bool = true) {
        if let input = input as? AVCaptureDeviceInput {
            fieldOfView = CGFloat(input.device.activeFormat.videoFieldOfView)
            position = input.device.position
            format = input.device.activeFormat
        }

        isVideoMirrored = position == .front

        if isAsync {
            configurationQueue.async { [weak self] in
                self?.updateConnection()
            }
        } else {
            updateConnection()
        }

        prevCaptureInput = input
    }

    func updateConnection() {
        if let isMirrored = videoConnection?.isVideoMirrored, isMirrored != isVideoMirrored {
            videoConnection?.isVideoMirrored = isVideoMirrored
        }

        if let orientation = videoConnection?.videoOrientation, orientation != videoOrientation {
            videoConnection?.videoOrientation = videoOrientation
        }
    }
}

extension MirrorAVSessionInput {
    enum Constants {
        static let defaultFieldOfView: CGFloat = 78.0
    }
}
