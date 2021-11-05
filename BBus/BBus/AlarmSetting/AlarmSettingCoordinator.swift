//
//  AlarmSettingCoordinator.swift
//  BBus
//
//  Created by 김태훈 on 2021/11/03.
//

import UIKit

class AlarmSettingCoordinator: MovingStatusPushable {
    var delegate: CoordinatorFinishDelegate?
    var presenter: UINavigationController
    var childCoordinators: [Coordinator]

    init(presenter: UINavigationController) {
        self.presenter = presenter
        self.childCoordinators = []
    }

    func start() {
        let viewController = AlarmSettingViewController()
        viewController.coordinator = self
        self.presenter.pushViewController(viewController, animated: true)
    }

    func terminate() {
        self.presenter.popViewController(animated: true)
        self.coordinatorDidFinish()
    }
}