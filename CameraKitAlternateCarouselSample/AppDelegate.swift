//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import UIKit
import SCSDKCameraKit
import SCSDKCreativeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SnapchatDelegate {

    private enum Constants {
        static var partnerGroupId = "845fe30b-b436-42a7-be3c-2da1c3390aa6" // default
        static var cancelTimeout: Int?
        static var isHide: Bool?
    }

    var window: UIWindow?
    fileprivate var supportedOrientations: UIInterfaceOrientationMask = .portrait

    let snapAPI = SCSDKSnapAPI()
    let cameraController = SampleCameraController()

    // Public getter for cancel timeout
    static var cancelTimeout: Int? {
        return Constants.cancelTimeout
    }
    
    // Public getter for is_hide
    static var isHide: Bool? {
        return Constants.isHide
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Langsung tampilkan LicenseInputViewController
        let licenseVC = LicenseInputViewController()
        licenseVC.delegate = self
        window?.rootViewController = licenseVC
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func cameraKitViewController(_ viewController: UIViewController, openSnapchat screen: SnapchatScreen) {
        switch screen {
        case .profile, .lens(_):
            // not supported yet in creative kit (1.4.2), should be added in next version
            break
        case .photo(let image):
            let photo = SCSDKSnapPhoto(image: image)
            let content = SCSDKPhotoSnapContent(snapPhoto: photo)
            sendSnapContent(content, viewController: viewController)
        case .video(let url):
            let video = SCSDKSnapVideo(videoUrl: url)
            let content = SCSDKVideoSnapContent(snapVideo: video)
            sendSnapContent(content, viewController: viewController)
        }
    }

    private func sendSnapContent(_ content: SCSDKSnapContent, viewController: UIViewController) {
        viewController.view.isUserInteractionEnabled = false
        snapAPI.startSending(content) { error in
            DispatchQueue.main.async {
                viewController.view.isUserInteractionEnabled = true
            }
            if let error = error {
                print("Failed to send content to Snapchat with error: \(error.localizedDescription)")
                return
            }
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return supportedOrientations
    }
}

// MARK: Helper Orientation Methods

extension AppDelegate: AppOrientationDelegate {

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        supportedOrientations = orientation
    }

    func unlockOrientation() {
        supportedOrientations = .allButUpsideDown
    }

}

// MARK: Data Provider

class SampleCameraController: CameraController {
    override func configureDataProvider() -> DataProviderComponent {
        DataProviderComponent(
            deviceMotion: nil, userData: UserDataProvider(), lensHint: nil, location: nil,
            mediaPicker: lensMediaProvider, remoteApiServiceProviders: [
                CatFactRemoteApiServiceProvider(),
                CaptureRemoteApiServiceProvider()
            ])
    }
}

// MARK: - LicenseInputDelegate

extension AppDelegate: LicenseInputDelegate {
    func didReceivePartnerGroupId(_ partnerGroupId: String?, customText: [String: String]?, customColor: [String: String]?, cancelTimeout: Int?, isHide: Bool?) {
        if let id = partnerGroupId, !id.isEmpty {
            AppDelegate.Constants.partnerGroupId = id
        } else {
            AppDelegate.Constants.partnerGroupId = "845fe30b-b436-42a7-be3c-2da1c3390aa6" // default
        }
        
        // Store custom text in UserDefaults if available
        if let customText = customText {
            UserDefaults.standard.set(customText, forKey: "customText")
        } else {
            UserDefaults.standard.removeObject(forKey: "customText")
        }
        
        // Store custom color in UserDefaults if available
        if let customColor = customColor {
            print("🎨 Debug: Saving customColor to UserDefaults: \(customColor)")
            UserDefaults.standard.set(customColor, forKey: "customColor")
        } else {
            print("🎨 Debug: No customColor received, removing from UserDefaults")
            UserDefaults.standard.removeObject(forKey: "customColor")
        }
        
        // Store cancel timeout as a simple static property for easy access
        AppDelegate.Constants.cancelTimeout = cancelTimeout
        
        // Store is_hide for snap watermark visibility control
        AppDelegate.Constants.isHide = isHide
        
        UserDefaults.standard.synchronize()
        
        // Load CameraKit
        cameraController.groupIDs = [AppDelegate.Constants.partnerGroupId]
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }
        cameraController.snapchatDelegate = self
        let cameraViewController = CameraViewController(cameraController: cameraController)
        cameraViewController.appOrientationDelegate = self
        
        // Set mode debug jika ada
        let isDebugMode = UserDefaults.standard.bool(forKey: "isDebugMode")
        cameraViewController.isDebugMode = isDebugMode
        
        window?.rootViewController = cameraViewController
    }
}
