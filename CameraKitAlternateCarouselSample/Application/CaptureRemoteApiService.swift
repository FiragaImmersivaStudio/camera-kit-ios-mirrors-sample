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
                // https://api-record.firaga.studio/capture_trigger?type=photo&app=firagamirror&timestamp=<timestamp>&duration=<duration>
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
                // https://api-record.firaga.studio/capture_stop?app=firagamirror
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
                // https://api-record.firaga.studio/stats_impression_count?count=1&start_at=<start_at>&end_at=<end_at>&app=firagamirror
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let start_at = jsonDict["start_at"] as? String
                let end_at = jsonDict["end_at"] as? String
                
                print("Received statistic impression count request from lens: \(app ?? "unknown")")
                

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
                // https://api-record.firaga.studio/stats_play_count?count=1&start_at=<start_at>&end_at=<end_at>&play_time=1&app=firagamirror
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let start_at = jsonDict["start_at"] as? String
                let end_at = jsonDict["end_at"] as? String
                let play_time = jsonDict["play_time"] as? Int
                
                print("Received statistic play count request from lens: \(app ?? "unknown")")

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
                // https://api-record.firaga.studio/stats_notice_count?app=firagamirror&count=1&start_at=<start_at>&end_at=<end_at>&face_time=1
                let app = jsonDict["app"] as? String
                let count = jsonDict["count"] as? Int
                let start_at = jsonDict["start_at"] as? String
                let end_at = jsonDict["end_at"] as? String
                let face_time = jsonDict["face_time"] as? Int
                
                print("Received statistic notice count request from lens: \(app ?? "unknown")")

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
