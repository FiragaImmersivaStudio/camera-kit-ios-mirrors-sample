//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import AVKit
import Photos
import UIKit

/// Preview view controller for showing recorded video previews
public class VideoPreviewViewController: PreviewViewController {

    // MARK: Properties

    /// URL which contains video file
    public let videoUrl: URL

    /// AVPlayerItem for video file url
    lazy var playerItem = AVPlayerItem(url: videoUrl)

    /// AVQueuePlayer for the video
    lazy var videoPlayer = AVQueuePlayer(playerItem: playerItem)

    // MARK: Views

    /// AVPlayerViewController for the video
    lazy var playerController: AVPlayerViewController = {
        let controller = AVPlayerViewController()
        controller.player = videoPlayer
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        return controller
    }()

    /// Player looper to loop video automatically
    lazy var playerLooper = AVPlayerLooper(player: videoPlayer, templateItem: playerItem)

    // MARK: Init

    /// Init with url to video file
    /// - Parameter videoUrl: url to video file
    public init(videoUrl: URL) {
        self.videoUrl = videoUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupVideoPlayer()

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackgroundNotification(_:)),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForegroundNotification(_:)),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    // MARK: Action Overrides

    override func uploadPreview() {
        do {
            let videoData = try Data(contentsOf: videoUrl)
            
            showLoading()
            videoPlayer.play() // Ensure video continues playing
            
            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: "https://file.firaga.studio/api/upload")!)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Get saved app code from UserDefaults
            let appCode = UserDefaults.standard.string(forKey: "savedAppCode") ?? ""
            
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
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
        } catch {
            print("Failed to read video data: \(error.localizedDescription)")
            hideLoading()
        }
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

    // MARK: App Lifecyle Notifications

    @objc private func appDidEnterBackgroundNotification(_ notification: Notification) {
        videoPlayer.pause()
    }

    @objc private func appWillEnterForegroundNotification(_ notification: Notification) {
        videoPlayer.play()
    }
}

// MARK: Video Player

extension VideoPreviewViewController {
    fileprivate func setupVideoPlayer() {
        addChild(playerController)
        view.insertSubview(playerController.view, at: 0)
        playerController.didMove(toParent: self)
        playerController.view.accessibilityIdentifier = PreviewElements.playerControllerView.id

        NSLayoutConstraint.activate([
            playerController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        guard playerLooper.error == nil else { return }
        videoPlayer.play()
    }
}
