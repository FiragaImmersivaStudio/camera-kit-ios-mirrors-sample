import UIKit

protocol LicenseInputDelegate: AnyObject {
    func didReceivePartnerGroupId(_ partnerGroupId: String?, customText: [String: String]?, customColor: [String: String]?, cancelTimeout: Int?, isHide: Bool?)
}

class LicenseInputViewController: UIViewController {
    weak var delegate: LicenseInputDelegate?
    
    // Variable to enable/disable virtual keyboard
    var isVirtualKeyboardEnabled: Bool = true
    
    private let primaryColor = UIColor(red: 0.96, green: 0.67, blue: 0.26, alpha: 1.0) // #F4AB43

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "firaga")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Firaga Studio"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.96, green: 0.67, blue: 0.26, alpha: 1.0) // #F4AB43
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Masukkan kode aplikasi"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "kode aplikasi"
        tf.borderStyle = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white
        tf.textColor = .black
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(white: 0.8, alpha: 1.0).cgColor // abu-abu muda
        // Tambahkan padding kiri dan kanan
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: tf.frame.height))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: tf.frame.height))
        tf.rightViewMode = .always
        // Placeholder warna hitam
        tf.attributedPlaceholder = NSAttributedString(string: "kode aplikasi", attributes: [
            .foregroundColor: UIColor.black
        ])
        // Disable default keyboard
        tf.inputView = UIView()
        return tf
    }()
    
    private let keyboardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var keyboardButtons: [UIButton] = []
    private let deleteButton = UIButton(type: .system)
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.96, green: 0.67, blue: 0.26, alpha: 1.0) // #F4AB43
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var countdownTimer: Timer?
    private var countdownValue: Int = 8
    private var isCountdownActive = false
    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let debugButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ladybug.fill"), for: .normal)
        button.tintColor = UIColor(red: 0.96, green: 0.67, blue: 0.26, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.99, alpha: 1.0)
        setupLayout()
        setupVirtualKeyboard()
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        debugButton.addTarget(self, action: #selector(debugTapped), for: .touchUpInside)
        setupAutofillAndCountdown()
        setupInteractionObservers()
        
        // Auto-focus to text field and show keyboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.textField.becomeFirstResponder()
            if self.isVirtualKeyboardEnabled {
                self.showVirtualKeyboard()
            }
        }
    }
    
    private func setupLayout() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.99, alpha: 1.0)
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        view.addSubview(cardView)
        view.addSubview(debugButton)
        view.addSubview(keyboardView)
        cardView.addSubview(instructionLabel)
        cardView.addSubview(textField)
        cardView.addSubview(submitButton)
        cardView.addSubview(activityIndicator)
        view.addSubview(countdownLabel)
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            debugButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            debugButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            debugButton.widthAnchor.constraint(equalToConstant: 44),
            debugButton.heightAnchor.constraint(equalToConstant: 44),
            
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),

            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cardView.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 32),
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
            
            instructionLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            instructionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            textField.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            textField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            submitButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
            
            countdownLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 32),
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 220)
        ])
        
        // Show keyboard permanently if enabled
        if isVirtualKeyboardEnabled {
            keyboardView.isHidden = false
            keyboardView.alpha = 1
        }
        
        // Fade-in animasi pada card
        cardView.alpha = 0
        UIView.animate(withDuration: 0.7, delay: 0.1, options: [.curveEaseIn], animations: {
            self.cardView.alpha = 1
        }, completion: nil)
    }
    
    private func setupAutofillAndCountdown() {
        if let savedCode = UserDefaults.standard.string(forKey: "savedAppCode"), !savedCode.isEmpty {
            textField.text = savedCode
            startCountdown()
        }
    }

    private func startCountdown() {
        countdownValue = 8
        isCountdownActive = true
        countdownLabel.isHidden = false
        updateCountdownLabel()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countdownTick), userInfo: nil, repeats: true)
    }

    private func cancelCountdown() {
        isCountdownActive = false
        countdownLabel.isHidden = true
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    @objc private func countdownTick() {
        countdownValue -= 1
        updateCountdownLabel()
        if countdownValue <= 0 {
            cancelCountdown()
            submitTapped()
        }
    }

    private func updateCountdownLabel() {
        countdownLabel.text = "Otomatis submit dalam \(countdownValue) detik..."
    }

    private func setupInteractionObservers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidInteract))
        view.addGestureRecognizer(tapGesture)
        textField.addTarget(self, action: #selector(userDidInteract), for: .editingChanged)
    }

    @objc private func userDidInteract() {
        if isCountdownActive {
            cancelCountdown()
        }
    }
    
    @objc private func submitTapped() {
        // Hilangkan fokus pada semua input
        view.endEditing(true)
        
        // Hide keyboard
        hideVirtualKeyboard()
        
        // Disable tombol submit
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor.gray
        
        let code = textField.text ?? ""
        // Simpan kode aplikasi ke UserDefaults (boleh kosong)
        UserDefaults.standard.setValue(code, forKey: "savedAppCode")
        UserDefaults.standard.synchronize()

        // Set mode debug
        UserDefaults.standard.set(false, forKey: "isDebugMode")
        UserDefaults.standard.synchronize()
        
        // Tampilkan overlay loading
        loadingOverlay.isHidden = false
        activityIndicator.startAnimating()
        
        if code.isEmpty {
            self.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
            return
        }
        fetchPartnerGroupId(for: code)
    }
    
    @objc private func debugTapped() {
        // Hilangkan fokus pada semua input
        view.endEditing(true)
        
        // Hide keyboard
        hideVirtualKeyboard()
        
        // Disable tombol submit
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor.gray
        
        let code = textField.text ?? ""
        // Simpan kode aplikasi ke UserDefaults (boleh kosong)
        UserDefaults.standard.setValue(code, forKey: "savedAppCode")
        UserDefaults.standard.synchronize()
        
        // Set mode debug
        UserDefaults.standard.set(true, forKey: "isDebugMode")
        UserDefaults.standard.synchronize()
        
        // Tampilkan overlay loading
        loadingOverlay.isHidden = false
        activityIndicator.startAnimating()
        
        if code.isEmpty {
            self.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
            return
        }
        fetchPartnerGroupId(for: code)
    }
    
    private func showExpirationAlert() {
        let alertController = UIAlertController(
            title: "Peringatan",
            message: "AR Mirror telah kadaluarsa, silahkan hubungi Firaga Studio",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Re-enable submit button after alert is dismissed
            self?.submitButton.isEnabled = true
            self?.submitButton.backgroundColor = UIColor(red: 0.96, green: 0.67, blue: 0.26, alpha: 1.0) // #F4AB43
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

    private func fetchPartnerGroupId(for code: String) {
        let urlString = "https://license.firaga.studio/api/license/\(code)"
        guard let url = URL(string: urlString) else {
            self.activityIndicator.stopAnimating()
            self.showToast(message: "Format URL tidak valid")
            self.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
            }
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.showToast(message: "Gagal terhubung ke server")
                    self?.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dataDict = json["data"] as? [String: Any],
                   let licenseData = dataDict["license_data"] as? [String: Any],
                   let partnerGroupId = licenseData["partnergroupid"] as? String, !partnerGroupId.isEmpty {
                    
                    // Check expiration date if it exists
                    if let expiredAtString = licenseData["expired_at"] as? String,
                       let expiredAt = ISO8601DateFormatter().date(from: expiredAtString) {
                        let currentDate = Date()
                        if currentDate > expiredAt {
                            DispatchQueue.main.async {
                                // hide loading overlay
                                self?.loadingOverlay.isHidden = true
                                self?.activityIndicator.stopAnimating()
                                // show expiration alert
                                self?.showExpirationAlert()
                            }
                            return
                        }
                    }
                    
                    // Extract custom_text if it exists
                    let customText = licenseData["custom_text"] as? [String: String]
                    
                    // Extract custom_color if it exists
                    let customColor = licenseData["custom_color"] as? [String: String]
                    print("🔍 Debug: API Response - custom_color value: \(String(describing: customColor))")
                    
                    // Extract cancel_timeout if it exists
                    let cancelTimeoutStr = licenseData["cancel_timeout"] as? String
                    let cancelTimeout = Int(cancelTimeoutStr ?? "")
                    print("🔍 Debug: API Response - cancel_timeout value: \(String(describing: cancelTimeout))")
                    
                    // Extract is_hide if it exists
                    let isHide = licenseData["is_hide"] as? Bool
                    print("🔍 Debug: API Response - is_hide value: \(String(describing: isHide))")
                    
                    // If not expired or no expiration date, continue
                    DispatchQueue.main.async {
                        self?.delegate?.didReceivePartnerGroupId(partnerGroupId, customText: customText, customColor: customColor, cancelTimeout: cancelTimeout, isHide: isHide)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showToast(message: "Kode aplikasi tidak valid atau tidak ditemukan")
                        self?.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showToast(message: "Terjadi kesalahan pada data server")
                    self?.delegate?.didReceivePartnerGroupId(nil, customText: nil, customColor: nil, cancelTimeout: nil, isHide: nil)
                }
            }
        }
        task.resume()
    }
    
    private func setupVirtualKeyboard() {
        // Add tap gesture to textField to show keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualKeyboard))
        textField.addGestureRecognizer(tapGesture)
        textField.isUserInteractionEnabled = true
        
        // Don't show virtual keyboard if disabled
        if !isVirtualKeyboardEnabled {
            textField.inputView = nil
            return
        }
        
        // Setup keyboard keys with QWERTY layout
        let keyLabels = [
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M", "⌫"]
        ]
        
        let buttonWidth: CGFloat = 30
        let buttonHeight: CGFloat = 40
        let horizontalSpacing: CGFloat = 5
        let verticalSpacing: CGFloat = 10
        
        for (rowIndex, row) in keyLabels.enumerated() {
            // Calculate row offset for centering
            let totalRowWidth = CGFloat(row.count) * (buttonWidth + horizontalSpacing) - horizontalSpacing
            let rowOffset = (view.frame.width - totalRowWidth) / 2
            
            for (colIndex, keyLabel) in row.enumerated() {
                let button = UIButton(type: .system)
                button.setTitle(keyLabel, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.layer.cornerRadius = 6
                button.translatesAutoresizingMaskIntoConstraints = false
                
                keyboardView.addSubview(button)
                
                // Position button
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: buttonWidth),
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                    button.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: rowOffset + CGFloat(colIndex) * (buttonWidth + horizontalSpacing)),
                    button.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 15 + CGFloat(rowIndex) * (buttonHeight + verticalSpacing))
                ])
                
                if keyLabel == "⌫" {
                    deleteButton.setTitle(keyLabel, for: .normal)
                    deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                    deleteButton.backgroundColor = .white
                    deleteButton.setTitleColor(.systemRed, for: .normal)
                    deleteButton.layer.cornerRadius = 6
                    deleteButton.translatesAutoresizingMaskIntoConstraints = false
                    
                    keyboardView.addSubview(deleteButton)
                    
                    NSLayoutConstraint.activate([
                        deleteButton.widthAnchor.constraint(equalToConstant: buttonWidth),
                        deleteButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                        deleteButton.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: rowOffset + CGFloat(colIndex) * (buttonWidth + horizontalSpacing)),
                        deleteButton.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 15 + CGFloat(rowIndex) * (buttonHeight + verticalSpacing))
                    ])
                    
                    deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
                } else {
                    keyboardButtons.append(button)
                    button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                }
            }
        }
    }
    
    @objc private func showVirtualKeyboard() {
        // Only show virtual keyboard if enabled
        if isVirtualKeyboardEnabled {
            keyboardView.isHidden = false
            keyboardView.alpha = 1
        } else {
            // Use default iOS keyboard if virtual keyboard is disabled
            textField.inputView = nil
            textField.becomeFirstResponder()
        }
    }
    
    @objc private func hideVirtualKeyboard() {
        keyboardView.isHidden = true
    }
    
    @objc private func keyTapped(_ sender: UIButton) {
        guard let digit = sender.titleLabel?.text else { return }
        textField.text = (textField.text ?? "") + digit
        userDidInteract()
    }
    
    @objc private func deleteButtonTapped() {
        if var text = textField.text, !text.isEmpty {
            text.removeLast()
            textField.text = text
        }
        userDidInteract()
    }
}

extension UIViewController {
    func showToast(message: String, duration: Double = 2.0) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastLabel)
        
        let horizontalPadding: CGFloat = 32
        let bottomPadding: CGFloat = 80
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            toastLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomPadding),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        
        UIView.animate(withDuration: 0.4, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: duration, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
} 