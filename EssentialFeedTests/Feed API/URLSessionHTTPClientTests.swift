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
    
    func test_getFromURL_performGetRequestWithURL() {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "https://a-url.com")!
        let exp = expectation(description: "Wait for observing request complete.")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        let sut = URLSeesionHTTPClient()
        sut.get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_getFailureOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "any error", code: 1, userInfo: nil)
        
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)
        
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
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        private struct Stub {
            var data: Data?
            var response: URLResponse?
            var error: Error?
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error? = nil) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(self)
            stub = nil
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            self.observer = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            observer?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
