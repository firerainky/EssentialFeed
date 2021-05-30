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
    func get(from: URL, completion: @escaping (HTTPClientResult) -> Void)
}
