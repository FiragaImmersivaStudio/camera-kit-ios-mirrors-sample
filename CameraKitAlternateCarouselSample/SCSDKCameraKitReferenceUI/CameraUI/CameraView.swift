//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import AVFoundation
import AVKit
import SCSDKCameraKit
import UIKit

/// This is the default view that backs the CameraViewController.
open class CameraView: UIView {
    private enum Constants {
        static let cameraFlip = "ck_camera_flip"
        static let lensExplore = "ck_lens_explore"
    }

    /// default camerakit view to draw outputted textures
    public let previewView: PreviewView = {
        let view = PreviewView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// button to flip camera input position in full frame
    public lazy var fullFrameFlipCameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.flipCameraButton.id
        button.accessibilityValue = CameraElements.CameraFlip.front
        button.accessibilityLabel = NSLocalizedString("Camera Flip Button", comment: "")
        button.setImage(
            UIImage(named: Constants.cameraFlip, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        // default hidden is false
        button.isHidden = true

        return button
    }()

    /// button to flip camera input position in small frame
    public lazy var smallFrameFlipCameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.flipCameraButton.id
        button.accessibilityValue = CameraElements.CameraFlip.front
        button.accessibilityLabel = NSLocalizedString("Camera Flip Button", comment: "")
        button.setImage(
            UIImage(named: Constants.cameraFlip, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true

        return button
    }()

    /// current lens information bar plus clear current lens button
    public let clearLensView: ClearLensView = {
        let view = ClearLensView()
        view.backgroundColor = UIColor(hex: 0x16191C, alpha: 0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    public let hintLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0.0
        label.font = .boldSystemFont(ofSize: 20.0)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    /// camera button to capture/record
    public let cameraButton: CameraButton = {
        let view = CameraButton()
        view.accessibilityIdentifier = CameraElements.cameraButton.id
        view.isAccessibilityElement = true
        view.translatesAutoresizingMaskIntoConstraints = false
        // default hidden is false
        view.isHidden = true
        return view
    }()

    /// lens button to open lens picker
    public let lensPickerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = CameraElements.lensPickerButton.id
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            UIImage(named: Constants.lensExplore, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        // button.isHidden = true
        return button
    }()

    public let snapWatermark: SnapWatermarkView = {
        let view = SnapWatermarkView()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    public let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        if #available(iOS 13, *) {
            view.style = .large
            view.color = .white
        } else {
            view.style = .whiteLarge
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Camera settings view
    public let cameraSettingsView: CameraSettingsView = {
        let view = CameraSettingsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private var settingsButtonTimer: Timer?
    private let settingsButtonTimeout: TimeInterval = 10.0
    
    /// Settings button to toggle camera settings
    public lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⚙️", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("Unimplemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
    }

}

// MARK: General View Setup

extension CameraView {

    private func setup() {
        setupPreview()
        setupHintLabel()
        setupCameraRing()
        setupLensPickerButton()
        setupFlipButtons()
        setupCameraBar()
        setupWatermark()
        setupActivityIndicator()
        setupCameraSettings()
        setupSettingsButton()
    }

    private func setupPreview() {
        addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupCameraSettings() {
        addSubview(cameraSettingsView)
        cameraSettingsView.parentView = self
        NSLayoutConstraint.activate([
            cameraSettingsView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
            cameraSettingsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cameraSettingsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cameraSettingsView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func setupSettingsButton() {
        addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Start the timer when the button is first shown
        startSettingsButtonTimer()
    }

    private func startSettingsButtonTimer() {
        // Cancel any existing timer
        settingsButtonTimer?.invalidate()
        
        // Show the button
        settingsButton.isHidden = false
        
        // Create a new timer
        settingsButtonTimer = Timer.scheduledTimer(withTimeInterval: settingsButtonTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Hide both the settings button and settings view
            self.settingsButton.isHidden = true
            self.cameraSettingsView.isHidden = true
        }
    }

    @objc private func settingsButtonTapped() {
        // Reset the timer when the button is tapped
        startSettingsButtonTimer()
        cameraSettingsView.isHidden.toggle()
    }

    // Add method to handle any interaction with the settings view
    public func handleSettingsInteraction() {
        startSettingsButtonTimer()
    }

}

// MARK: Camera Bottom Bar

extension CameraView {

    private func setupCameraBar() {
        addSubview(clearLensView)
        NSLayoutConstraint.activate([
            clearLensView.centerXAnchor.constraint(equalTo: centerXAnchor),
            clearLensView.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -24),
            clearLensView.heightAnchor.constraint(equalToConstant: 40.0),
            clearLensView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width - 40*2),
        ])
    }

}

// MARK: Camera Ring

extension CameraView {

    private func setupCameraRing() {
        addSubview(cameraButton)
        NSLayoutConstraint.activate([
            cameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -68.0),
            cameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    private func setupLensPickerButton() {
        addSubview(lensPickerButton)
        NSLayoutConstraint.activate([
            lensPickerButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            lensPickerButton.trailingAnchor.constraint(equalTo: cameraButton.leadingAnchor, constant: -24)
        ])
    }

    private func setupFlipButtons() {
        addSubview(fullFrameFlipCameraButton)
        NSLayoutConstraint.activate([
            fullFrameFlipCameraButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            fullFrameFlipCameraButton.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 24)
        ])

        addSubview(smallFrameFlipCameraButton)
        NSLayoutConstraint.activate([
            smallFrameFlipCameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            smallFrameFlipCameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }

    func updateFlipButton(isInFullScreen: Bool) {
        let isDebugMode = UserDefaults.standard.bool(forKey: "isDebugMode")
        if isDebugMode {
            fullFrameFlipCameraButton.isHidden = false
            // smallFrameFlipCameraButton.isHidden = false
            cameraButton.isHidden = false
        } else {
            fullFrameFlipCameraButton.isHidden = true
            // smallFrameFlipCameraButton.isHidden = true
            cameraButton.isHidden = true
        }
    }

}

// MARK: Watermark

extension CameraView {

    private func setupWatermark() {
        addSubview(snapWatermark)
        NSLayoutConstraint.activate([
            snapWatermark.topAnchor.constraint(equalTo: topAnchor, constant: 73),
            snapWatermark.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}

// MARK: Hint

extension CameraView {

    private func setupHintLabel() {
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Activity Indicator

extension CameraView {

    public func setupActivityIndicator() {
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Tap to Focus

extension CameraView {

    public func drawTapAnimationView(at point: CGPoint) {
        let view = TapAnimationView(center: point)
        addSubview(view)

        view.show()
    }

}

/// View containing camera settings controls
public class CameraSettingsView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Frame Orientation Controls
    private let frameOrientationLabel: UILabel = {
        let label = UILabel()
        label.text = "Frame Orientation"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let frameOrientationStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    // Position Controls
    private let positionLabel: UILabel = {
        let label = UILabel()
        label.text = "Camera Position"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let positionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    // Video Mirror Controls
    private let mirrorLabel: UILabel = {
        let label = UILabel()
        label.text = "Video Mirror"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let mirrorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    // Video Orientation Controls
    private let videoOrientationLabel: UILabel = {
        let label = UILabel()
        label.text = "Video Orientation"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let videoOrientationStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    var onFrameOrientationChanged: ((AVCaptureVideoOrientation) -> Void)?
    var onPositionChanged: ((AVCaptureDevice.Position) -> Void)?
    var onMirrorChanged: ((Bool) -> Void)?
    var onVideoOrientationChanged: ((AVCaptureVideoOrientation) -> Void)?
    
    weak var parentView: CameraView?
    
    private enum UserDefaultsKeys {
        static let frameOrientation = "camera_frame_orientation"
        static let position = "camera_position"
        static let isVideoMirrored = "camera_is_video_mirrored"
        static let videoOrientation = "camera_video_orientation"
    }
    
    // State tracking
    private var selectedFrameOrientation: AVCaptureVideoOrientation
    private var selectedPosition: AVCaptureDevice.Position
    private var selectedIsMirrored: Bool
    private var selectedVideoOrientation: AVCaptureVideoOrientation
    
    // Button references
    private var frameOrientationButtons: [UIButton] = []
    private var positionButtons: [UIButton] = []
    private var mirrorButtons: [UIButton] = []
    private var videoOrientationButtons: [UIButton] = []
    
    public override init(frame: CGRect) {
        // Initialize with values from UserDefaults
        if let frameOrientationRaw = UserDefaults.standard.object(forKey: UserDefaultsKeys.frameOrientation) as? Int,
           let frameOrientation = AVCaptureVideoOrientation(rawValue: frameOrientationRaw) {
            selectedFrameOrientation = frameOrientation
        } else {
            selectedFrameOrientation = .landscapeLeft
        }
        
        if let positionRaw = UserDefaults.standard.object(forKey: UserDefaultsKeys.position) as? Int,
           let position = AVCaptureDevice.Position(rawValue: positionRaw) {
            selectedPosition = position
        } else {
            selectedPosition = .front
        }
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.isVideoMirrored) != nil {
            selectedIsMirrored = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isVideoMirrored)
        } else {
            selectedIsMirrored = false
        }
        
        if let videoOrientationRaw = UserDefaults.standard.object(forKey: UserDefaultsKeys.videoOrientation) as? Int,
           let videoOrientation = AVCaptureVideoOrientation(rawValue: videoOrientationRaw) {
            selectedVideoOrientation = videoOrientation
        } else {
            selectedVideoOrientation = .landscapeLeft
        }
        
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(white: 0, alpha: 0.7)
        layer.cornerRadius = 12
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        
        // Add mouse movement detection
        // setupMouseMovementDetection()
        
        // Setup Frame Orientation Controls
        frameOrientationButtons = [
            createButton(title: "Landscape Left", action: #selector(frameOrientationTapped(_:))),
            createButton(title: "Landscape Right", action: #selector(frameOrientationTapped(_:))),
            createButton(title: "Portrait", action: #selector(frameOrientationTapped(_:))),
            createButton(title: "Portrait Upside Down", action: #selector(frameOrientationTapped(_:)))
        ]
        frameOrientationButtons.forEach { frameOrientationStack.addArrangedSubview($0) }
        
        // Setup Position Controls
        positionButtons = [
            createButton(title: "Front", action: #selector(positionTapped(_:))),
            createButton(title: "Back", action: #selector(positionTapped(_:)))
        ]
        
        // Check available cameras and update position buttons
        checkAvailableCameras()
        
        positionButtons.forEach { positionStack.addArrangedSubview($0) }
        
        // Setup Mirror Controls
        mirrorButtons = [
            createButton(title: "Mirror On", action: #selector(mirrorTapped(_:))),
            createButton(title: "Mirror Off", action: #selector(mirrorTapped(_:)))
        ]
        mirrorButtons.forEach { mirrorStack.addArrangedSubview($0) }
        
        // Setup Video Orientation Controls
        videoOrientationButtons = [
            createButton(title: "Landscape Left", action: #selector(videoOrientationTapped(_:))),
            createButton(title: "Landscape Right", action: #selector(videoOrientationTapped(_:))),
            createButton(title: "Portrait", action: #selector(videoOrientationTapped(_:))),
            createButton(title: "Portrait Upside Down", action: #selector(videoOrientationTapped(_:)))
        ]
        videoOrientationButtons.forEach { videoOrientationStack.addArrangedSubview($0) }
        
        // Add all controls to main stack
        stackView.addArrangedSubview(frameOrientationLabel)
        stackView.addArrangedSubview(frameOrientationStack)
        stackView.addArrangedSubview(positionLabel)
        stackView.addArrangedSubview(positionStack)
        stackView.addArrangedSubview(mirrorLabel)
        stackView.addArrangedSubview(mirrorStack)
        stackView.addArrangedSubview(videoOrientationLabel)
        stackView.addArrangedSubview(videoOrientationStack)
        
        // Update initial button colors
        updateButtonColors()
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.2)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func updateButtonColors() {
        // Update frame orientation buttons
        for button in frameOrientationButtons {
            let orientation = getOrientationFromButton(button)
            button.backgroundColor = orientation == selectedFrameOrientation ? 
                UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5) : // Blue for selected
                UIColor(white: 1, alpha: 0.2) // Default gray
        }
        
        // Update position buttons
        for button in positionButtons {
            let position = button.title(for: .normal) == "Front" ? AVCaptureDevice.Position.front : .back
            button.backgroundColor = position == selectedPosition ?
                UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.5) : // Green for selected
                UIColor(white: 1, alpha: 0.2)
        }
        
        // Update mirror buttons
        for button in mirrorButtons {
            let isMirrored = button.title(for: .normal) == "Mirror On"
            button.backgroundColor = isMirrored == selectedIsMirrored ?
                UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.5) : // Orange for selected
                UIColor(white: 1, alpha: 0.2)
        }
        
        // Update video orientation buttons
        for button in videoOrientationButtons {
            let orientation = getOrientationFromButton(button)
            button.backgroundColor = orientation == selectedVideoOrientation ?
                UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 0.5) : // Purple for selected
                UIColor(white: 1, alpha: 0.2)
        }
    }
    
    private func getOrientationFromButton(_ button: UIButton) -> AVCaptureVideoOrientation {
        guard let title = button.title(for: .normal) else { return .landscapeLeft }
        switch title {
        case "Landscape Left": return .landscapeLeft
        case "Landscape Right": return .landscapeRight
        case "Portrait": return .portrait
        case "Portrait Upside Down": return .portraitUpsideDown
        default: return .landscapeLeft
        }
    }
    
    @objc private func frameOrientationTapped(_ sender: UIButton) {
        parentView?.handleSettingsInteraction()
        guard let title = sender.title(for: .normal) else { return }
        let orientation: AVCaptureVideoOrientation
        switch title {
        case "Landscape Left": orientation = .landscapeLeft
        case "Landscape Right": orientation = .landscapeRight
        case "Portrait": orientation = .portrait
        case "Portrait Upside Down": orientation = .portraitUpsideDown
        default: return
        }
        selectedFrameOrientation = orientation
        updateButtonColors()
        onFrameOrientationChanged?(orientation)
    }
    
    @objc private func positionTapped(_ sender: UIButton) {
        parentView?.handleSettingsInteraction()
        guard let title = sender.title(for: .normal) else { return }
        let position: AVCaptureDevice.Position = title == "Front" ? .front : .back
        selectedPosition = position
        updateButtonColors()
        onPositionChanged?(position)
    }
    
    @objc private func mirrorTapped(_ sender: UIButton) {
        parentView?.handleSettingsInteraction()
        guard let title = sender.title(for: .normal) else { return }
        let isMirrored = title == "Mirror On"
        selectedIsMirrored = isMirrored
        updateButtonColors()
        onMirrorChanged?(isMirrored)
    }
    
    @objc private func videoOrientationTapped(_ sender: UIButton) {
        parentView?.handleSettingsInteraction()
        guard let title = sender.title(for: .normal) else { return }
        let orientation: AVCaptureVideoOrientation
        switch title {
        case "Landscape Left": orientation = .landscapeLeft
        case "Landscape Right": orientation = .landscapeRight
        case "Portrait": orientation = .portrait
        case "Portrait Upside Down": orientation = .portraitUpsideDown
        default: return
        }
        selectedVideoOrientation = orientation
        updateButtonColors()
        onVideoOrientationChanged?(orientation)
    }

    // Add new method to check available cameras
    private func checkAvailableCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        let availableCameras = discoverySession.devices
        
        // If only one camera is available
        if availableCameras.count == 1 {
            let availableCamera = availableCameras[0]
            let availablePosition = availableCamera.position
            
            // Check if saved position in UserDefaults is different from available position
            if let savedPositionRaw = UserDefaults.standard.object(forKey: UserDefaultsKeys.position) as? Int,
               let savedPosition = AVCaptureDevice.Position(rawValue: savedPositionRaw),
               savedPosition != availablePosition {
                // Update UserDefaults with available position
                UserDefaults.standard.set(availablePosition.rawValue, forKey: UserDefaultsKeys.position)
            }
            
            // Disable the button for the unavailable camera position
            for button in positionButtons {
                if let title = button.title(for: .normal) {
                    let buttonPosition: AVCaptureDevice.Position = title == "Front" ? .front : .back
                    if buttonPosition != availablePosition {
                        button.isEnabled = false
                        button.alpha = 0.5
                    } else {
                        // Set the available camera as selected
                        button.backgroundColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.5)
                        selectedPosition = availablePosition
                    }
                }
            }
        }
    }

    // Add new method for mouse movement detection
    private func setupMouseMovementDetection() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMouseMovement(_:)))
        panGesture.minimumNumberOfTouches = 0 // This allows mouse movement detection
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handleMouseMovement(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation = gesture.translation(in: self)
            if abs(translation.x) > 5 || abs(translation.y) > 5 { // Threshold to avoid too frequent updates
                showToast(message: "Mouse movement detected")
                gesture.setTranslation(.zero, in: self)
            }
        }
    }
    
    private func showToast(message: String) {
        // Remove existing toast if any
        viewWithTag(999)?.removeFromSuperview()
        
        let toastLabel = UILabel()
        toastLabel.tag = 999
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            toastLabel.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        // Animate toast appearance and disappearance
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
}
