//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Photos
import UIKit

/// Base preview view controller that describes properties and views of all preview controllers
public class PreviewViewController: UIViewController {

    /// Callback when user presses close button and dismisses preview view controller
    public var onDismiss: (() -> Void)?

    /// Store original button colors for focus management
    private var buttonOriginalColors: [UIButton: UIColor] = [:]
    
    /// Store original button text colors for focus management
    private var buttonOriginalTextColors: [UIButton: UIColor] = [:]
    
    /// Static property to track last upload timestamp across all preview instances
    private static var lastUploadTimestamp: Date?
    
    /// Currently focused button
    private var focusedButton: UIButton? {
        didSet {
            // Restore old button's original color
            if let oldButton = oldValue,
               let originalColor = buttonOriginalColors[oldButton] {
                oldButton.backgroundColor = originalColor
            }
            
            // Set focused button to blue
            focusedButton?.backgroundColor = .systemBlue
        }
    }

    /// Timer for cancel button timeout
    private var cancelTimeoutTimer: Timer?
    private var cancelTimeoutValue: Int = 0
    private var originalCancelText: String = ""
    
    /// Timer for QR code timeout
    private var qrCodeTimeoutTimer: Timer?
    private var qrCodeTimeoutValue: Int = 10 // 30 seconds timeout for QR code

    /// Get custom button text from UserDefaults with fallback to default
    private func getButtonText(for key: String, defaultText: String) -> String {
        guard let customText = UserDefaults.standard.dictionary(forKey: "customText") as? [String: String],
              let text = customText[key], !text.isEmpty else {
            return defaultText
        }
        return text
    }
    
    /// Get custom button color from UserDefaults with fallback to default
    private func getButtonColor(for key: String, defaultColor: UIColor) -> UIColor {
        print("🎨 Debug: getButtonColor called for key: \(key)")
        
        guard let customColor = UserDefaults.standard.dictionary(forKey: "customColor") as? [String: String] else {
            print("🎨 Debug: No customColor found in UserDefaults")
            return defaultColor
        }
        
        print("🎨 Debug: customColor dictionary: \(customColor)")
        
        guard let colorHex = customColor[key], !colorHex.isEmpty else {
            print("🎨 Debug: No color found for key '\(key)' or empty value")
            return defaultColor
        }
        
        print("🎨 Debug: Found hex color '\(colorHex)' for key '\(key)'")
        
        if let parsedColor = UIColor(hex: colorHex) {
            print("🎨 Debug: Successfully parsed color: \(parsedColor)")
            return parsedColor
        } else {
            print("🎨 Debug: Failed to parse hex color '\(colorHex)'")
            return defaultColor
        }
    }

    /// Get custom button text color from UserDefaults with fallback to default
    private func getButtonTextColor(for key: String, defaultColor: UIColor) -> UIColor {
        print("🎨 Debug: getButtonTextColor called for key: \(key)")
        
        guard let customText = UserDefaults.standard.dictionary(forKey: "customText") as? [String: String] else {
            print("🎨 Debug: No customText found in UserDefaults")
            return defaultColor
        }
        
        print("🎨 Debug: customText dictionary: \(customText)")
        
        guard let colorHex = customText[key], !colorHex.isEmpty else {
            print("🎨 Debug: No text color found for key '\(key)' or empty value")
            return defaultColor
        }
        
        print("🎨 Debug: Found hex text color '\(colorHex)' for key '\(key)'")
        
        if let parsedColor = UIColor(hex: colorHex) {
            print("🎨 Debug: Successfully parsed text color: \(parsedColor)")
            return parsedColor
        } else {
            print("🎨 Debug: Failed to parse hex text color '\(colorHex)'")
            return defaultColor
        }
    }
    
    /// Validate if upload is allowed based on interval settings
    internal func validateUploadInterval() -> Bool {
        let intervalUpload = AppDelegate.intervalUpload ?? 10 // Default 10 seconds
        let currentTime = Date()
        
        // Check if this is the first upload
        guard let lastUpload = PreviewViewController.lastUploadTimestamp else {
            print("🔄 Upload Validation: First upload allowed")
            PreviewViewController.lastUploadTimestamp = currentTime
            return true
        }
        
        let timeSinceLastUpload = currentTime.timeIntervalSince(lastUpload)
        
        if timeSinceLastUpload >= TimeInterval(intervalUpload) {
            print("🔄 Upload Validation: Upload allowed - interval: \(timeSinceLastUpload)s (required: \(intervalUpload)s)")
            PreviewViewController.lastUploadTimestamp = currentTime
            return true
        } else {
            print("🚫 Upload Validation: Upload blocked - interval: \(timeSinceLastUpload)s (required: \(intervalUpload)s)")
            return false
        }
    }

    // MARK: View Properties

    fileprivate let closeButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = PreviewElements.closeButton.id
        button.setImage(
            UIImage(named: "ck_close_x", in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemGray
        return button
    }()

    fileprivate let uploadButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    fileprivate let cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    fileprivate let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    fileprivate let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate let qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    fileprivate let qrCodeCloseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate let qrCodeCountdownLabel: UILabel = {
        let label = UILabel()
        label.text = "QR code akan hilang dalam 20 detik"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    fileprivate lazy var uploadButtonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [uploadButton, cancelButton])
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: Setup

    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Refresh colors in case they were updated after initial setup
        refreshButtonColors()
        
        // Become first responder to handle keyboard commands
        becomeFirstResponder()
        print("🔍 Debug: PreviewViewController became first responder: \(isFirstResponder)")
        
        // Notify that preview is now active
        NotificationCenter.default.post(name: .previewDidAppear, object: nil)
        print("🔍 Debug: PreviewViewController appeared, posted notification")
    }
    
    private func refreshButtonColors() {
        print("🎨 Debug: Refreshing button colors...")
        
        let uploadColor = getButtonColor(for: "button_upload", defaultColor: .systemGray)
        let cancelColor = getButtonColor(for: "button_cancel", defaultColor: .systemGray)
        
        let uploadTextColor = getButtonTextColor(for: "button_upload_color", defaultColor: .white)
        let cancelTextColor = getButtonTextColor(for: "button_cancel_color", defaultColor: .white)
        
        uploadButton.backgroundColor = uploadColor
        cancelButton.backgroundColor = cancelColor
        
        uploadButton.setTitleColor(uploadTextColor, for: .normal)
        cancelButton.setTitleColor(cancelTextColor, for: .normal)
        
        // Update stored original colors
        buttonOriginalColors[uploadButton] = uploadColor
        buttonOriginalColors[cancelButton] = cancelColor
        
        // Update stored original text colors
        buttonOriginalTextColors[uploadButton] = uploadTextColor
        buttonOriginalTextColors[cancelButton] = cancelTextColor
        
        print("🎨 Debug: Colors refreshed - upload: \(uploadColor), cancel: \(cancelColor)")
        print("🎨 Debug: Text colors refreshed - upload: \(uploadTextColor), cancel: \(cancelTextColor)")
    }

    private func setup() {
        view.backgroundColor = .black
        setupUploadButtons()
        setupLoadingIndicator()
        setupOverlayView()
        setupQRCodeView()
        
        // Test hex color parsing
        testHexColorParsing()
        
        // Configure button titles with custom text
        uploadButton.setTitle(getButtonText(for: "button_upload", defaultText: "Upload"), for: .normal)
        originalCancelText = getButtonText(for: "button_cancel", defaultText: "Cancel")
        cancelButton.setTitle(originalCancelText, for: .normal)
        
        // Configure button colors with custom color
        let uploadColor = getButtonColor(for: "button_upload", defaultColor: .systemGray)
        let cancelColor = getButtonColor(for: "button_cancel", defaultColor: .systemGray)
        
        let uploadTextColor = getButtonTextColor(for: "button_upload_color", defaultColor: .white)
        let cancelTextColor = getButtonTextColor(for: "button_cancel_color", defaultColor: .white)
        
        print("🎨 Debug: Setting uploadButton color to: \(uploadColor)")
        print("🎨 Debug: Setting cancelButton color to: \(cancelColor)")
        print("🎨 Debug: Setting uploadButton text color to: \(uploadTextColor)")
        print("🎨 Debug: Setting cancelButton text color to: \(cancelTextColor)")
        
        uploadButton.backgroundColor = uploadColor
        cancelButton.backgroundColor = cancelColor
        
        uploadButton.setTitleColor(uploadTextColor, for: .normal)
        cancelButton.setTitleColor(cancelTextColor, for: .normal)
        
        // Store original colors for focus management
        buttonOriginalColors[uploadButton] = uploadColor
        buttonOriginalColors[cancelButton] = cancelColor
        
        // Store original text colors for focus management
        buttonOriginalTextColors[uploadButton] = uploadTextColor
        buttonOriginalTextColors[cancelButton] = cancelTextColor
        
        print("🎨 Debug: buttonOriginalColors: \(buttonOriginalColors)")
        print("🎨 Debug: buttonOriginalTextColors: \(buttonOriginalTextColors)")
        
        // Setup cancel timeout if available
        setupCancelTimeout()
        
        // Set initial focus
        focusedButton = uploadButton
    }
    
    private func testHexColorParsing() {
        print("🎨 Debug: Testing hex color parsing...")
        
        // Test various hex formats
        let testColors = ["#FBDD12", "#FF5722", "FBDD12", "ff5722", "#000000", "#FFFFFF"]
        
        for hexString in testColors {
            if let color = UIColor(hex: hexString) {
                print("🎨 Debug: Successfully parsed '\(hexString)' -> \(color)")
            } else {
                print("🎨 Debug: Failed to parse '\(hexString)'")
            }
        }
        
        // Add test custom colors for debugging (uncomment for manual testing)
        // let testCustomColor = ["button_upload": "#FBDD12", "button_cancel": "#FF5722"]
        // UserDefaults.standard.set(testCustomColor, forKey: "customColor")
        // UserDefaults.standard.synchronize()
        // print("🎨 Debug: Added test custom colors: \(testCustomColor)")
        
        // Add test custom text colors for debugging (uncomment for manual testing)
        // let testCustomText = [
        //     "button_upload": "Upload",
        //     "button_cancel": "Cancel", 
        //     "button_upload_color": "#000000",
        //     "button_cancel_color": "#FFFFFF"
        // ]
        // UserDefaults.standard.set(testCustomText, forKey: "customText")
        // UserDefaults.standard.synchronize()
        // print("🎨 Debug: Added test custom text colors: \(testCustomText)")
    }

    private func setupCancelTimeout() {
        // Get timeout from AppDelegate instead of UserDefaults  
        let timeoutValue = AppDelegate.cancelTimeout ?? 0
        print("🔍 Debug: setupCancelTimeout called - timeoutValue from AppDelegate: \(timeoutValue)")
        
        // Don't setup if timer is already running
        if cancelTimeoutTimer != nil {
            print("🔍 Debug: Timer is already running, skipping setup")
            return
        }
        
        if timeoutValue > 0 {
            cancelTimeoutValue = timeoutValue
            print("🔍 Debug: Starting cancel timeout with value: \(cancelTimeoutValue)")
            startCancelTimeout()
        } else {
            print("🔍 Debug: No cancel timeout set or value is 0")
        }
    }
    
    private func startCancelTimeout() {
        print("🔍 Debug: startCancelTimeout called with value: \(cancelTimeoutValue)")
        cancelTimeoutTimer?.invalidate()
        
        updateCancelButtonText()
        
        cancelTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.cancelTimeoutValue -= 1
            print("🔍 Debug: Timer tick - cancelTimeoutValue: \(self.cancelTimeoutValue)")
            
            if self.cancelTimeoutValue <= 0 {
                print("🔍 Debug: Timeout reached 0 - auto dismissing")
                self.cancelTimeoutTimer?.invalidate()
                self.cancelTimeoutTimer = nil
                // Auto dismiss when timeout reaches 0
                self.cancelButtonPressed(self.cancelButton)
            } else {
                self.updateCancelButtonText()
            }
        }
        print("🔍 Debug: Timer scheduled successfully")
    }
    
    private func updateCancelButtonText() {
        let timeoutText = "\(originalCancelText) (\(cancelTimeoutValue))"
        print("🔍 Debug: Updating cancel button text to: \(timeoutText)")
        cancelButton.setTitle(timeoutText, for: .normal)
    }
    
    private func stopCancelTimeout() {
        print("🔍 Debug: stopCancelTimeout called")
        cancelTimeoutTimer?.invalidate()
        cancelTimeoutTimer = nil
        cancelButton.setTitle(originalCancelText, for: .normal)
    }
    
    private func startQRCodeTimeout() {
        print("🔍 Debug: startQRCodeTimeout called with value: \(qrCodeTimeoutValue)")
        qrCodeTimeoutTimer?.invalidate()
        
        updateQRCodeCountdownLabel()
        
        qrCodeTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.qrCodeTimeoutValue -= 1
            print("🔍 Debug: QR Code Timer tick - qrCodeTimeoutValue: \(self.qrCodeTimeoutValue)")
            
            if self.qrCodeTimeoutValue <= 0 {
                print("🔍 Debug: QR Code timeout reached 0 - auto closing")
                self.qrCodeTimeoutTimer?.invalidate()
                self.qrCodeTimeoutTimer = nil
                // Auto close QR code when timeout reaches 0
                self.qrCodeCloseButtonPressed(self.qrCodeCloseButton)
            } else {
                self.updateQRCodeCountdownLabel()
            }
        }
        print("🔍 Debug: QR Code timer scheduled successfully")
    }
    
    private func updateQRCodeCountdownLabel() {
        let countdownText = "QR code akan hilang dalam \(qrCodeTimeoutValue) detik"
        print("🔍 Debug: Updating QR code countdown text to: \(countdownText)")
        qrCodeCountdownLabel.text = countdownText
    }
    
    private func stopQRCodeTimeout() {
        print("🔍 Debug: stopQRCodeTimeout called")
        qrCodeTimeoutTimer?.invalidate()
        qrCodeTimeoutTimer = nil
        qrCodeCountdownLabel.isHidden = true
    }

    // MARK: First Responder
    
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: Keyboard Commands
    
    public override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscapeKey(_:)), discoverabilityTitle: "Back/Cancel"),
            UIKeyCommand(input: "r", modifierFlags: [], action: #selector(handleSpaceKey(_:)), discoverabilityTitle: "Select/Confirm")
        ]
        print("🔍 Debug: keyCommands called, returning \(commands.count) commands")
        return commands
    }

    @objc private func handleEscapeKey(_ sender: UIKeyCommand) {
        print("🔍 Debug: handleEscapeKey called")
        if qrCodeImageView.isHidden == false {
            // If QR code is visible, close it and the preview
            qrCodeCloseButtonPressed(qrCodeCloseButton)
            closeButtonPressed(closeButton)
        } else {
            // Otherwise, act as cancel button
            cancelButtonPressed(cancelButton)
        }
    }

    @objc private func handleSpaceKey(_ sender: UIKeyCommand) {
        print("🔍 Debug: handleSpaceKey called! Focused button: \(String(describing: focusedButton))")
        if let focused = focusedButton {
            // Trigger the focused button's action
            if focused == uploadButton {
                print("🔍 Debug: Triggering upload button")
                uploadButtonPressed(uploadButton)
            } else if focused == cancelButton {
                print("🔍 Debug: Triggering cancel button")
                cancelButtonPressed(cancelButton)
            } else if focused == closeButton {
                print("🔍 Debug: Triggering close button")
                closeButtonPressed(closeButton)
            } else if focused == qrCodeCloseButton {
                print("🔍 Debug: Triggering QR code close button")
                qrCodeCloseButtonPressed(qrCodeCloseButton)
                closeButtonPressed(closeButton)
            }
        } else {
            // If no button is focused, focus the upload button
            print("🔍 Debug: No button focused, setting focus to upload button")
            focusedButton = uploadButton
        }
    }

    // MARK: Overridable Actions

    func uploadPreview() {
        fatalError("upload preview action has to be implemented by subclass")
    }

    func showLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        uploadButtonStackView.isHidden = true
        overlayView.isHidden = true
        focusedButton = nil
        
        // Stop cancel timeout during loading
        stopCancelTimeout()
    }

    func hideLoading() {
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        uploadButtonStackView.isHidden = false
        overlayView.isHidden = true
        focusedButton = uploadButton
        
        // Only restart cancel timeout if upload buttons will remain visible
        // (they will be hidden when QR code is shown)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            // Check if upload buttons are still visible after a short delay
            if !self.uploadButtonStackView.isHidden {
                self.setupCancelTimeout()
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCancelTimeout()
        stopQRCodeTimeout()
        
        // Resign first responder to give control back to camera
        resignFirstResponder()
        print("🔍 Debug: PreviewViewController resigned first responder")
        
        // Notify that preview is no longer active
        NotificationCenter.default.post(name: .previewDidDisappear, object: nil)
        print("🔍 Debug: PreviewViewController disappearing, posted notification")
    }
}

// MARK: Close Button

extension PreviewViewController {
    fileprivate func setupCloseButton() {
        closeButton.addTarget(self, action: #selector(self.closeButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32.0),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
        ])
    }

    @objc private func closeButtonPressed(_ sender: UIButton) {
        onDismiss?()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Upload Buttons

extension PreviewViewController {
    fileprivate func setupUploadButtons() {
        uploadButton.addTarget(self, action: #selector(uploadButtonPressed(_:)), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(uploadButtonStackView)
        NSLayoutConstraint.activate([
            uploadButtonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButtonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32.0),
            uploadButtonStackView.widthAnchor.constraint(equalToConstant: 320),
            uploadButtonStackView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }

    @objc private func uploadButtonPressed(_ sender: UIButton) {
        uploadPreview()
    }

    @objc private func cancelButtonPressed(_ sender: UIButton) {
        stopCancelTimeout()
        onDismiss?()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Loading Indicator

extension PreviewViewController {
    fileprivate func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// MARK: Overlay View

extension PreviewViewController {
    fileprivate func setupOverlayView() {
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: QR Code View

extension PreviewViewController {
    fileprivate func setupQRCodeView() {
        view.addSubview(qrCodeImageView)
        view.addSubview(qrCodeCloseButton)
        view.addSubview(qrCodeCountdownLabel)
        
        NSLayoutConstraint.activate([
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            qrCodeImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor),
            
            qrCodeCountdownLabel.bottomAnchor.constraint(equalTo: qrCodeImageView.topAnchor, constant: -10),
            qrCodeCountdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeCountdownLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            qrCodeCountdownLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            qrCodeCountdownLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            qrCodeCloseButton.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 16),
            qrCodeCloseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeCloseButton.widthAnchor.constraint(equalToConstant: 44),
            qrCodeCloseButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        qrCodeCloseButton.addTarget(self, action: #selector(qrCodeCloseButtonPressed(_:)), for: .touchUpInside)
    }
    
    @objc private func qrCodeCloseButtonPressed(_ sender: UIButton) {
        stopQRCodeTimeout()
        qrCodeImageView.isHidden = true
        qrCodeCloseButton.isHidden = true
        qrCodeCountdownLabel.isHidden = true
        overlayView.isHidden = true
        uploadButtonStackView.isHidden = false
        closeButtonPressed(closeButton)
    }
    
    func showQRCode(_ qrCodeImage: UIImage) {
        // Stop cancel button timeout since upload buttons are hidden when QR code is shown
        stopCancelTimeout()
        
        qrCodeImageView.image = qrCodeImage
        qrCodeImageView.isHidden = false
        qrCodeCloseButton.isHidden = true
        qrCodeCountdownLabel.isHidden = false
        overlayView.isHidden = false
        uploadButtonStackView.isHidden = true
        focusedButton = nil
        
        // Reset timeout value and start countdown
        qrCodeTimeoutValue = 10
        startQRCodeTimeout()
    }
}

// MARK: - UIColor Extension for Hex Support

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexColor.hasPrefix("#") {
            hexColor.removeFirst()
        }
        
        print("🎨 Debug: Parsing hex color '\(hex)' -> cleaned: '\(hexColor)'")
        
        guard hexColor.count == 6 else {
            print("🎨 Debug: Invalid hex length: \(hexColor.count), expected 6")
            return nil
        }
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else {
            print("🎨 Debug: Failed to scan hex number from '\(hexColor)'")
            return nil
        }
        
        r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        b = CGFloat(hexNumber & 0x0000ff) / 255
        
        print("🎨 Debug: Parsed RGB: r=\(r), g=\(g), b=\(b)")
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
