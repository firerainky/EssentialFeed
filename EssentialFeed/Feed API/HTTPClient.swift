//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/30.
//

import Foundation

public enum HTTPClientResult {
    case success(data: Data, response: HTTPURLResponse)
    case failure(Swift.Error)
}

public protocol HTTPClient {
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
