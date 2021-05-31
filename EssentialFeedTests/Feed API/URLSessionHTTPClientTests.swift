//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/31.
//

import Foundation
import XCTest
import EssentialFeed

class URLSeesionHTTPClient: HTTPClient {
    var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url, completionHandler: { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }).resume()
    }
}

class URLSeesionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_getFailureOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "any error", code: 1, userInfo: nil)
        
        URLProtocolStub.stub(url: url, error: error)
        
        let sut = URLSeesionHTTPClient()
        let exp = expectation(description: "Wait for get completion.")
        
        URLProtocolStub.startInterceptingRequests()
        
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stubs = [URL : Stub]()
        
        private struct Stub {
            var error: Error?
        }
        
        static func stub(url: URL, error: Error? = nil) {
            let stub = Stub(error: error)
            stubs[url] = stub
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(self)
            stubs = [:]
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
                return
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
