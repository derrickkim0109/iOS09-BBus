//
//  Service.swift
//  BBus
//
//  Created by Kang Minsang on 2021/11/10.
//

import Foundation
import Combine

enum NetworkError: Error {
    case accessKeyError, urlError, unknownError, noDataError, noResponseError, responseError, trafficExceed
}

// TODO: - Service Return Type 수정 필요
class Service {
    static let shared = Service()
    
    private let accessKey = (Bundle.main.infoDictionary?["API_ACCESS_KEY"] as? String)
    private init() { }

    func get(url: String, params: [String: String], on queue: DispatchQueue) -> AnyPublisher<Data, Error> {
        let publisher = PassthroughSubject<Data, Error>()
        
        let userDefaultKey = "APIRequestCount"
        let apiRequestCount = UserDefaults.standard.object(forKey: userDefaultKey) as? Int ?? 0
        if apiRequestCount > 300 {
            queue.async { [weak publisher] in publisher?.send(completion: .failure(NetworkError.trafficExceed)) }
            return publisher.eraseToAnyPublisher()
        }
        UserDefaults.standard.set(apiRequestCount + 1, forKey: userDefaultKey)
        
        queue.async { [weak self, weak publisher] in
            guard let self = self else { return }
            guard let accessKey = self.accessKey else {
                publisher?.send(completion: .failure(NetworkError.accessKeyError))
                return
            }
            guard var components = URLComponents(string: url) else {
                publisher?.send(completion: .failure(NetworkError.urlError))
                return
            }
            var items: [URLQueryItem] = []
            params.forEach() { item in
                items.append(URLQueryItem(name: item.key, value: item.value))
            }
            components.queryItems = items
            if let query = components.percentEncodedQuery  {
                components.percentEncodedQuery = query + "&serviceKey=" + accessKey
            }
            
            if let url = components.url {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        publisher?.send(completion: .failure(error))
                        return
                    }
                    guard let response = response as? HTTPURLResponse else {
                        publisher?.send(completion: .failure(NetworkError.noResponseError))
                        return
                    }
                    if response.statusCode != 200 {
                        publisher?.send(completion: .failure(NetworkError.responseError))
                        return
                    }
                    if let data = data {
                        publisher?.send(data)
                    }
                    else {
                        publisher?.send(completion: .failure(NetworkError.noDataError))
                    }
                }.resume()
            }
            else {
                publisher?.send(completion: .failure(NetworkError.urlError))
            }
        }
        return publisher.eraseToAnyPublisher()
    }
}
