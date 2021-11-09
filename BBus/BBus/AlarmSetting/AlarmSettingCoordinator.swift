//
//  AlarmSettingCoordinator.swift
//  BBus
//
//  Created by 김태훈 on 2021/11/03.
//

import UIKit

class AlarmSettingCoordinator: Coordinator {
    var finishDelegate: CoordinatorFinishDelegate?
    var movingStatusDelegate: MovingStatusOpenCloseDelegate?
    var navigationPresenter: UINavigationController?
    var childCoordinators: [Coordinator]

    init(presenter: UINavigationController?) {
        self.navigationPresenter = presenter
        self.childCoordinators = []
    }

    func start() {
        let viewController = AlarmSettingViewController()
        viewController.coordinator = self
        self.navigationPresenter?.pushViewController(viewController, animated: true)
    }

    func terminate() {
        self.navigationPresenter?.popViewController(animated: true)
        self.coordinatorDidFinish()
    }
    
    func openMovingStatus() {
        self.movingStatusDelegate?.open()
    }
    
    func closeMovingStatus() {
        self.movingStatusDelegate?.close()
    }
}
