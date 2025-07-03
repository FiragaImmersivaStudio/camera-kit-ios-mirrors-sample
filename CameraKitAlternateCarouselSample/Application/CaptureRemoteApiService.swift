// Copyright Snap Inc. All rights reserved.
// CameraKitSample

import Foundation
import SCSDKCameraKit

/// Implementation of RemoteApiServiceProvider for handling capture requests from Lens
class CaptureRemoteApiServiceProvider: NSObject, LensRemoteApiServiceProvider {
    // Add your API Spec ID from Lens Studio Portal here
    var supportedApiSpecIds: Set<String> = ["7c661976-0a8a-4a49-839e-c6eedc5b09ec"] // Replace with your actual API Spec ID
    
    func remoteApiService(for lens: Lens) -> LensRemoteApiService {
        return CaptureRemoteApiService()
    }
}

/// Service that processes capture requests from Lens
class CaptureRemoteApiService: NSObject, LensRemoteApiService {
    // Static/shared variable to track button state
    static var isButtonPressedWhileOnLens: Bool = false
    
    func processRequest(
        _ request: LensRemoteApiRequest,
        responseHandler: @escaping (LensRemoteApiServiceCallStatus, LensRemoteApiResponseProtocol) -> Void
    ) -> LensRemoteApiServiceCall {
        
        print("Received Lens Remote: \(request)")
        print("Received Lens Remote endpointId: \(request.endpointId)")

        let endpointId = request.endpointId

        if endpointId == "capture_trigger" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/capture_trigger?type=photo&app=firagamirror&timestamp=<timestamp>&duration=<duration>
                let captureType = jsonDict["type"] as? String
                let app = jsonDict["app"] as? String
                
                // Ambil parameter tambahan jika ada (durasi untuk video)
                var userInfo: [String: Any] = ["type": captureType ?? "photo"]
                
                // Tambahkan parameter durasi ke userInfo jika tipe capture adalah video
                if captureType == "video", let duration = jsonDict["duration"] as? String {
                    userInfo["duration"] = duration
                    print("Received video request with duration: \(duration) seconds")
                }
                
                print("Received capture request from lens: \(captureType ?? "unknown")")
                
                // Dispatch to main thread since we'll be interacting with UI
                DispatchQueue.main.async {
                    // Post notification for capture action
                    NotificationCenter.default.post(
                        name: NSNotification.Name("TriggerCapture"), 
                        object: nil, 
                        userInfo: userInfo
                    )
                }
                
                // Send success response back to lens
                let response = LensRemoteApiResponse(
                    request: request,
                    status: .success,
                    metadata: [:],
                    body: "{ \"status\": \"success\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, response)

                print("[CaptureRemoteApiService] Request data: \(String(data: response.body ?? Data(), encoding: .utf8) ?? "no data")")
            } else {
                // Body exists but could not be parsed as JSON
                let errorResponse = LensRemoteApiResponse(
                    request: request,
                    status: .badRequest,
                    metadata: [:],
                    body: "{ \"status\": \"error\", \"message\": \"[1] Invalid JSON format\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, errorResponse)
            }
        } else if endpointId == "capture_stop" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/capture_stop?app=firagamirror
                let app = jsonDict["app"] as? String
                print("Received capture stop request from lens: \(app ?? "unknown")")
                
                // Dispatch to main thread since we'll be interacting with UI
                DispatchQueue.main.async {
                    // Post notification for stop capture action
                    NotificationCenter.default.post(
                        name: NSNotification.Name("StopCapture"),
                        object: nil
                    )
                }
                
                // Send success response back to lens
                let response = LensRemoteApiResponse(
                    request: request,
                    status: .success,
                    metadata: [:],
                    body: "{ \"status\": \"success\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, response)
            } else {
                // Body exists but could not be parsed as JSON
                let errorResponse = LensRemoteApiResponse(
                    request: request,
                    status: .badRequest,
                    metadata: [:],
                    body: "{ \"status\": \"error\", \"message\": \"[2] Invalid JSON format\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, errorResponse)
            }
        } else if endpointId == "stats_impression_count" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/stats_impression_count?count=1&start_at=<start_at>&end_at=<end_at>&app=firagamirror
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let now = ISO8601DateFormatter().string(from: Date())
                let start_at = (jsonDict["start_at"] as? String) ?? now
                let end_at = (jsonDict["end_at"] as? String) ?? now
                
                print("Received statistic impression count request from lens: \(app ?? "unknown")")

                // hit that api with GET method, the output is json, if json.status is true, then print success, else print error
                let url = URL(string: "https://license.firaga.studio/api/stats_impression_count?count=\(count ?? 0)&start_at=\(start_at ?? "")&end_at=\(end_at ?? "")&app=\(app ?? "")")!
                let theReq = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: theReq) { data, response, error in
                    print("Received statistic impression count response from lens: \(data)")
                }
                task.resume()
            } else {
                // Body exists but could not be parsed as JSON
                let errorResponse = LensRemoteApiResponse(
                    request: request,
                    status: .badRequest,
                    metadata: [:],
                    body: "{ \"status\": \"error\", \"message\": \"[3] Invalid JSON format\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, errorResponse)
            }
        } else if endpointId == "stats_play_count" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/stats_play_count?count=1&start_at=<start_at>&end_at=<end_at>&play_time=1&app=firagamirror
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let now = ISO8601DateFormatter().string(from: Date())
                let start_at = (jsonDict["start_at"] as? String) ?? now
                let end_at = (jsonDict["end_at"] as? String) ?? now
                let play_time = jsonDict["play_time"] as? Int
                
                print("Received statistic play count request from lens: \(app ?? "unknown")")

                // hit that api with GET method, the output is json, if json.status is true, then print success, else print error
                let url = URL(string: "https://license.firaga.studio/api/stats_play_count?count=\(count ?? 0)&start_at=\(start_at ?? "")&end_at=\(end_at ?? "")&play_time=\(play_time ?? 0)&app=\(app ?? "")")!
                let theReq = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: theReq) { data, response, error in
                    print("Received statistic play count response from lens: \(data)")
                }
                task.resume()
            } else {
                // Body exists but could not be parsed as JSON
                let errorResponse = LensRemoteApiResponse(
                    request: request,
                    status: .badRequest,
                    metadata: [:],
                    body: "{ \"status\": \"error\", \"message\": \"[4] Invalid JSON format\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, errorResponse)
            }
        } else if endpointId == "stats_notice_count" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/stats_notice_count?app=firagamirror&count=1&start_at=<start_at>&end_at=<end_at>&face_time=1
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let now = ISO8601DateFormatter().string(from: Date())
                let start_at = (jsonDict["start_at"] as? String) ?? now
                let end_at = (jsonDict["end_at"] as? String) ?? now
                let face_time = jsonDict["face_time"] as? Int
                
                print("Received statistic notice count request from lens: \(app ?? "unknown")")

                // hit that api with GET method, the output is json, if json.status is true, then print success, else print error
                let url = URL(string: "https://license.firaga.studio/api/stats_notice_count?count=\(count ?? 0)&start_at=\(start_at ?? "")&end_at=\(end_at ?? "")&face_time=\(face_time ?? 0)&app=\(app ?? "")")!
                let theReq = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: theReq) { data, response, error in
                    print("Received statistic notice count response from lens: \(data)")
                }
                task.resume()
            } else {
                // Body exists but could not be parsed as JSON
                let errorResponse = LensRemoteApiResponse(
                    request: request,
                    status: .badRequest,
                    metadata: [:],
                    body: "{ \"status\": \"error\", \"message\": \"[5] Invalid JSON format\" }".data(using: .utf8)
                )
                
                responseHandler(.answered, errorResponse)
            }
        } else if endpointId == "handshake" {
            // Check if we can parse the body as JSON
            // if let jsonDict = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            if let jsonDict = request.parameters as? [String: Any] {
                // Body can be parsed as JSON
                // https://license.firaga.studio/api/handshake?app=firagamirror
                let app = jsonDict["app"] as? String

                print("Received handshake request from lens: \(app ?? "unknown")")

                let response = LensRemoteApiResponse(
                    request: request,
                    status: .success,
                    metadata: [:],
                    body: "{ \"status\": \"handshake success\" }".data(using: .utf8)
                )
                responseHandler(.answered, response)
            }
        } else if endpointId == "beacon_check_button_1" {
            // Beacon check every 2 seconds
            if Self.isButtonPressedWhileOnLens {
                // Reset after reporting
                Self.isButtonPressedWhileOnLens = false
                let response = LensRemoteApiResponse(
                    request: request,
                    status: .success,
                    metadata: [:],
                    body: "{ \"status\": \"begin_record\" }".data(using: .utf8)
                )
                responseHandler(.answered, response)
                print("🔍 Debug: Beacon triggered, user pressing the button")
            } else {
                let response = LensRemoteApiResponse(
                    request: request,
                    status: .success,
                    metadata: [:],
                    body: "{ \"status\": \"idle\" }".data(using: .utf8)
                )
                responseHandler(.answered, response)
                // print("🔍 Debug: Beacon triggered, user not pressing the button")
            }
        }

        return CaptureRemoteApiServiceCall()
    }
}

/// Simple implementation of LensRemoteApiServiceCall
class CaptureRemoteApiServiceCall: NSObject, LensRemoteApiServiceCall {
    let status: LensRemoteApiServiceCallStatus = .ongoing
    
    func cancelRequest() {
        // No-op implementation
    }
} 
