//
//  MovingStatusViewController.swift
//  BBus
//
//  Created by Minsang on 2021/11/15.
//

import UIKit
import Combine
import CoreLocation

typealias MovingStatusCoordinator = MovingStatusOpenCloseDelegate & MovingStatusFoldUnfoldDelegate & AlertCreateToNavigationDelegate & AlertCreateToMovingStatusDelegate

final class MovingStatusViewController: UIViewController, BaseViewControllerType {
    
    static private let alarmIdentifier: String = "GetOffAlarm"

    weak var coordinator: MovingStatusCoordinator?
    private let viewModel: MovingStatusViewModel?
    private lazy var movingStatusView = MovingStatusView()
    
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: MovingStatusViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = nil
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.baseViewDidLoad()

        self.movingStatusView.startLoader()
        self.movingStatusView.configureBusTag()
        self.configureLocationManager()
    }

    private func configureLocationManager() {
        GetOffAlarmController.shared.configureAlarmPermission(self)
    }
    
    // MARK: - Configure
    func configureLayout() {
        self.view.addSubviews(self.movingStatusView)
        
        NSLayoutConstraint.activate([
            self.movingStatusView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.movingStatusView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.movingStatusView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.movingStatusView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    func configureDelegate() {
        self.movingStatusView.configureDelegate(self)
    }

    func bindAll() {
        self.bindLoader()
        self.bindHeaderBusInfo()
        self.bindRemainTime()
        self.bindCurrentStation()
        self.bindStationInfos()
        self.bindBoardedBus()
        self.bindIsTerminated()
        self.bindGetOffMessage()
    }

    private func bindGetOffMessage() {
        self.viewModel?.$message
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] message in
                guard let message = message else { return }
                self?.pushGetOffAlarm(message: message)
            })
            .store(in: &self.cancellables)
    }

    private func bindHeaderBusInfo() {
        self.viewModel?.$busInfo
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] busInfo in
                guard let busInfo = busInfo else { return }
                self?.movingStatusView.configureBusName(to: busInfo.busName)
                self?.movingStatusView.configureColorAndBusIcon(type: busInfo.type)
                self?.movingStatusView.configureBusTag(bus: nil)
            })
            .store(in: &self.cancellables)
    }

    private func bindRemainTime() {
        self.viewModel?.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] remainingTime in
                self?.movingStatusView.configureHeaderInfo(remainStation: self?.viewModel?.remainingStation, remainTime: remainingTime)
            })
            .store(in: &self.cancellables)
    }

    private func bindCurrentStation() {
        self.viewModel?.$remainingStation
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] currentStation in
                self?.movingStatusView.configureHeaderInfo(remainStation: currentStation, remainTime: self?.viewModel?.remainingTime)
            })
            .store(in: &self.cancellables)
    }

    private func bindStationInfos() {
        self.viewModel?.$stationInfos
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.movingStatusView.reload()
            })
            .store(in: &self.cancellables)
    }

    private func bindBoardedBus() {
        self.viewModel?.$boardedBus
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] boardedBus in
                self?.movingStatusView.configureBusTag(bus: boardedBus)
            })
            .store(in: &self.cancellables)
    }

    private func bindIsTerminated() {
        self.viewModel?.$isterminated
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isTerminated in
                if isTerminated {
                    self?.terminateAlert()
                }
            })
            .store(in: &self.cancellables)
    }

    private func bindLoader() {
        self.viewModel?.$stopLoader
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isStop in
                if isStop {
                    self?.movingStatusView.stopLoader()
                }
            })
            .store(in: &self.cancellables)
    }
    
    private func bindErrorMessage() {
        self.viewModel?.$networkError
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let _ = error else { return }
                self?.networkAlert()
            })
            .store(in: &self.cancellables)
    }
    
    func refresh() {
        self.viewModel?.updateAPI()
    }
    
    private func networkAlert() {
        let controller = UIAlertController(title: "네트워크 장애", message: "네트워크 장애가 발생하여 앱이 정상적으로 동작되지 않습니다.", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default, handler: nil)
        controller.addAction(action)
        
        guard let isFolded = self.viewModel?.isFolded else { return }
        if isFolded {
            self.coordinator?.presentAlertToNavigation(controller: controller, completion: nil)
        }
        else {
            self.coordinator?.presentAlertToMovingStatus(controller: controller, completion: nil)
        }
    }

    private func terminateAlert() {
        let controller = UIAlertController(title: "하차 종료", message: "하차 정거장에 도착하여 알람이 종료되었습니다.", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            self?.coordinator?.close()
        })
        controller.addAction(action)

        guard let isFolded = self.viewModel?.isFolded else { return }
        if isFolded {
            self.coordinator?.presentAlertToNavigation(controller: controller, completion: nil)
        }
        else {
            self.coordinator?.presentAlertToMovingStatus(controller: controller, completion: nil)
        }
    }

    private func pushGetOffAlarm(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "하차 알람"
        content.body = message
        content.badge = Int(truncating: content.badge ?? 0) + 1 as NSNumber
        let request = UNNotificationRequest(identifier: Self.alarmIdentifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

// MARK: - DataSource: UITableView
extension MovingStatusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.stationInfos.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MovingStatusTableViewCell.reusableID, for: indexPath) as? MovingStatusTableViewCell else { return UITableViewCell() }
        guard let stationInfo = self.viewModel?.stationInfos[indexPath.row] else { return cell }

        cell.configure(speed: stationInfo.speed,
                       afterSpeed: stationInfo.afterSpeed,
                       index: indexPath.row,
                       count: stationInfo.count,
                       title: stationInfo.title)
        
        return cell
    }
}

// MARK: - Delegate : UITableView
extension MovingStatusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return GetOffTableViewCell.cellHeight
    }
}

// MARK: - Delegate : BottomIndicatorButton
extension MovingStatusViewController: BottomIndicatorButtonDelegate {
    func shouldUnfoldMovingStatusView() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.viewModel?.unfold()
            self?.coordinator?.unfold()
        }
    }
}

// MARK: - Delegate : BottomIndicatorButton
extension MovingStatusViewController: FoldButtonDelegate {
    func shouldFoldMovingStatusView() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.viewModel?.fold()
            self?.coordinator?.fold()
        }
    }
}

// MARK: - Delegate : EndAlarmButton
extension MovingStatusViewController: EndAlarmButtonDelegate {
    func shouldEndAlarm() {
        self.coordinator?.close()
    }
}

// MARK: - Delegate: RefreshButton
extension MovingStatusViewController: RefreshButtonDelegate {
    func buttonTapped() {
        self.refresh()
    }
}

// MARK: - Delegate: CLLocation
extension MovingStatusViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            self.viewModel?.findBoardBus(gpsY: Double(coordinate.latitude), gpsX: Double(coordinate.longitude))
        }
    }
}
