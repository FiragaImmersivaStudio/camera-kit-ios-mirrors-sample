//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import Foundation
import SCSDKCameraKit

// Example implementation of [LensRemoteApiService] which receives requests from lenses that use the
// [Remote Service Module](https://docs.snap.com/lens-studio/references/guides/lens-features/remote-apis/remote-service-module)
// feature. The remote API spec ID is provided for demo and testing purposes -
// CameraKit user applications are expected to define their own specs for any remote API that they are interested to
// communicate with. Please reach out to CameraKit support team at https://docs.snap.com/snap-kit/support
// to find out more on how to define and use this feature.
class CatFactRemoteApiServiceProvider: NSObject, LensRemoteApiServiceProvider {

    var supportedApiSpecIds: Set<String> = ["03d765c5-20bd-4495-9a27-30629649cf57"]

    func remoteApiService(for lens: Lens) -> LensRemoteApiService {
        print("[CatFactRemoteApiServiceProvider] Creating new remote API service for lens: \(lens.id)")
        return CatFactRemoteApiService()
    }
}

class CatFactRemoteApiService: NSObject, LensRemoteApiService {

    private enum Constants {
        static let scheme = "https"
        static let host = "catfact.ninja"
    }

    private let urlSession: URLSession = .shared

    func processRequest(
        _ request: LensRemoteApiRequest,
        responseHandler: @escaping (LensRemoteApiServiceCallStatus, LensRemoteApiResponseProtocol) -> Void
    ) -> LensRemoteApiServiceCall {
        print("[CatFactRemoteApiService] Processing request for endpoint: \(request.endpointId)")
        
        guard let url = url(request: request) else {
            print("[CatFactRemoteApiService] Failed to create URL for request")
            return IgnoredRemoteApiServiceCall()
        }
        
        print("[CatFactRemoteApiService] Making request to URL: \(url.absoluteString)")

        let task = urlSession.dataTask(with: url) { data, urlResponse, error in
            if let error = error {
                print("[CatFactRemoteApiService] Request failed with error: \(error.localizedDescription)")
            } else {
                print("[CatFactRemoteApiService] Request completed successfully")
            }
            
            let apiResponse = LensRemoteApiResponse(
                request: request,
                status: error != nil ? .badRequest : .success,
                metadata: [:],
                body: data)

            responseHandler(.answered, apiResponse)

            print("[CatFactRemoteApiService] Request data: \(String(data: data ?? Data(), encoding: .utf8) ?? "no data")")
        }

        task.resume()
        print("[CatFactRemoteApiService] Request task started")

        return URLRequestRemoteApiServiceCall(task: task)
    }

    private func url(request: LensRemoteApiRequest) -> URL? {
        var components = URLComponents()
        components.host = Constants.host
        components.path = "/" + request.endpointId
        components.scheme = Constants.scheme
        let url = components.url
        print("[CatFactRemoteApiService] Generated URL: \(url?.absoluteString ?? "nil")")
        return url
    }
}

class URLRequestRemoteApiServiceCall: NSObject, LensRemoteApiServiceCall {

    let task: URLSessionDataTask
    let status: LensRemoteApiServiceCallStatus = .ongoing

    init(task: URLSessionDataTask) {
        self.task = task
        super.init()
        print("[URLRequestRemoteApiServiceCall] Initialized with task")
    }

    func cancelRequest() {
        print("[URLRequestRemoteApiServiceCall] Cancelling request")
        task.cancel()
    }
}

class IgnoredRemoteApiServiceCall: NSObject, LensRemoteApiServiceCall {
    let status: LensRemoteApiServiceCallStatus = .ignored

    func cancelRequest() {
        print("[IgnoredRemoteApiServiceCall] Cancel request called (no-op)")
        // no-op
    }
}
