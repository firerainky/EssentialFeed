//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/27.
//

import Foundation

public class RemoteFeedLoader: FeedLoader {
    
    public typealias Result = FeedLoader.Result
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private var url: URL
    private var client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            
            switch result {
            case let .success((data, response)):
                completion(RemoteFeedLoader.map(data, from: response))
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemsMapper.map(data: data, response: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
