//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/30.
//

import Foundation

public protocol HTTPClient {
    
    typealias Result = Swift.Result<(data: Data, response: HTTPURLResponse), Error>
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
