//
//  SearchBusCoordinator.swift
//  BBus
//
//  Created by Kang Minsang on 2021/11/02.
//

import UIKit

class SearchCoordinator: BusRoutePushable, StationPushable {
    var finishDelegate: CoordinatorFinishDelegate?
    var navigationPresenter: UINavigationController?
    var childCoordinators: [Coordinator]

    init(presenter: UINavigationController?) {
        self.navigationPresenter = presenter
        self.childCoordinators = []
    }

    func start() {
        let viewController = SearchViewController()
        viewController.coordinator = self
        self.navigationPresenter?.pushViewController(viewController, animated: true)
    }

    func terminate() {
        self.navigationPresenter?.popViewController(animated: true)
        self.coordinatorDidFinish()
    }
}
