//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Photos
import UIKit

/// Preview view controller for showing captured photos and images
public class ImagePreviewViewController: PreviewViewController {

    // MARK: Properties

    /// UIImage to display
    public let image: UIImage

    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.accessibilityIdentifier = PreviewElements.imageView.id
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: Init

    /// Designated init to pass in required deps
    /// - Parameter image: UIImage to display
    public init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: Setup

    private func setup() {
        view.insertSubview(imageView, at: 0)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: Action Overrides

    override func uploadPreview() {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        showLoading()
        imageView.isHidden = false // Ensure image remains visible
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://file.firaga.studio/api/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Get saved app code from UserDefaults
        let appCode = UserDefaults.standard.string(forKey: "savedAppCode") ?? ""
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"group\"\r\n\r\n".data(using: .utf8)!)
        body.append(appCode.data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoading()
                
                if let error = error {
                    print("Upload failed: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success == true,
                       let responseData = json["data"] as? [String: Any],
                       let previewUrl = responseData["preview_url"] as? String {
                        
                        // Generate QR code from preview_url
                        let qrCode = self.generateQRCode(from: previewUrl)
                        self.showQRCode(qrCode)
                    } else {
                        print("Invalid response format")
                    }
                } catch {
                    print("Failed to parse response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let data = string.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        if let output = filter?.outputImage?.transformed(by: transform) {
            return UIImage(ciImage: output)
        }
        return UIImage()
    }
}
