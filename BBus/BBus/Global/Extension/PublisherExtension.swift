//
//  PublisherExtension.swift
//  BBus
//
//  Created by 이지수 on 2021/11/18.
//

import Foundation
import Combine

extension Publisher where Output == (Data, Int), Failure == Error {
    func mapJsonBBusAPIError() -> AnyPublisher<Data, Error> {
        self.tryMap({ data, order -> Data in
            // TODO: JSON BBUSAPIError map 로직 필요
            return data
        }).eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Error {
    func retry(_ currentTokenExhaustedHandler: @escaping () -> Void, handler wholeTokenExhaustedHandler: @escaping (_ error: Error) -> Void) -> AnyPublisher<Self.Output, Never> {
        self.catch({ error -> AnyPublisher<Self.Output, Never> in
            switch error {
            case BBusAPIError.noMoreAccessKeyError, BBusAPIError.trafficExceed:
                wholeTokenExhaustedHandler(error)
            default:
                currentTokenExhaustedHandler()
            }
            
            let publisher = PassthroughSubject<Self.Output, Never>()
            DispatchQueue.global().async {
                publisher.send(completion: .finished)
            }
            return publisher.eraseToAnyPublisher()
        }).eraseToAnyPublisher()
    }
}

