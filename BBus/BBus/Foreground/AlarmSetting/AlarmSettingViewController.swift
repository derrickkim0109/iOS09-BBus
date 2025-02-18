//
//  AlarmSettingViewController.swift
//  BBus
//
//  Created by 김태훈 on 2021/11/01.
//

import UIKit
import Combine

final class AlarmSettingViewController: UIViewController, BaseViewControllerType {
    
    weak var coordinator: AlarmSettingCoordinator?
    private let viewModel: AlarmSettingViewModel?
    private lazy var alarmSettingView = AlarmSettingView()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(viewModel: AlarmSettingViewModel) {
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
        
        self.configureColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.alarmSettingView.startLoader()
        self.viewModel?.configureObserver()
        self.viewModel?.activateLoaderActiveStatus()
        self.viewModel?.refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel?.cancelObserver()
    }
    
    // MARK: - Configure
    func configureLayout() {
        self.view.addSubviews(self.alarmSettingView)

        NSLayoutConstraint.activate([
            self.alarmSettingView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.alarmSettingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.alarmSettingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.alarmSettingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    func configureDelegate() {
        self.alarmSettingView.configureDelegate(self)
    }

    private func configureColor() {
        self.view.backgroundColor = BBusColor.white
        self.alarmSettingView.configureColor(color: BBusColor.black)
    }
    
    func bindAll() {
        self.bindBusArriveInfos()
        self.bindBusStationInfos()
        self.bindErrorMessage()
        self.bindLoaderActiveStatus()
    }
    
    private func bindBusArriveInfos() {
        self.viewModel?.$busArriveInfos
            .filter { !$0.changedByTimer }
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] _ in
                self?.alarmSettingView.reload()
            })
            .store(in: &self.cancellables)
    }
    
    private func bindBusStationInfos() {
        self.viewModel?.$busStationInfos
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] infos in
                if let infos = infos {
                    self?.alarmSettingView.reload()
                    if let viewModel = self?.viewModel,
                       let stationName = infos.first?.name {
                        self?.alarmSettingView.configureTitle(busName: viewModel.busName,
                                                                 stationName: stationName,
                                                                 routeType: viewModel.routeType)
                    }
                }
                else {
                    self?.noInfoAlert()
                }
            })
            .store(in: &self.cancellables)
    }
    
    private func bindErrorMessage() {
        self.viewModel?.$networkError
            .compactMap({$0})
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.networkAlert()
            })
            .store(in: &self.cancellables)
    }
    
    private func bindLoaderActiveStatus() {
        self.viewModel?.$loaderActiveStatus
            .dropFirst()
            .filter({ !$0 })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] a in
                self?.alarmSettingView.stopLoader()
            })
            .store(in: &self.cancellables)
    }
    
    func refresh() {
        self.viewModel?.refresh()
    }
    
    private func alarmSettingAlert(message: String) {
        let controller = UIAlertController()
        let action = UIAlertAction(title: message, style: .cancel, handler: nil)
        controller.addAction(action)
        self.coordinator?.delegate?.presentAlertToNavigation(controller: controller, completion: nil)
    }

    private func alarmSettingActionSheet(titleMessage: String, buttonMessage: String, yes: @escaping () -> Void) {
        let controller = UIAlertController(title: nil, message: titleMessage, preferredStyle: .actionSheet)

        let OKAction = UIAlertAction(title: buttonMessage, style: .destructive) { _ in
            yes()
        }
        let CancelAction = UIAlertAction(title: "취소", style: .cancel)
        controller.addAction(OKAction)
        controller.addAction(CancelAction)
        self.coordinator?.delegate?.presentAlertToNavigation(controller: controller, completion: nil)
    }
    
    private func networkAlert() {
        let controller = UIAlertController(title: "네트워크 장애", message: "네트워크 장애가 발생하여 앱이 정상적으로 동작되지 않습니다.", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default, handler: nil)
        controller.addAction(action)
        self.coordinator?.delegate?.presentAlertToNavigation(controller: controller, completion: nil)
    }
    
    private func noInfoAlert() {
        let controller = UIAlertController(title: "알람 에러",
                                           message: "죄송합니다. 현재 알람 서비스가 제공되지 않는 버스입니다.",
                                           preferredStyle: .alert)
        let action = UIAlertAction(title: "확인",
                                   style: .default,
                                   handler: { [weak self] _ in self?.coordinator?.terminate() })
        controller.addAction(action)
        self.coordinator?.delegate?.presentAlertToNavigation(controller: controller, completion: nil)
    }
}

// MARK: - DataSource: UITableView
extension AlarmSettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return AlarmSettingView.tableViewSectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            guard let info = self.viewModel?.busArriveInfos.first else { return 0 }
            return info.arriveRemainTime != nil ? (self.viewModel?.busArriveInfos.count ?? 0) : 1
        case 1:
            guard let info = self.viewModel?.busStationInfos else { return 0 }
            return info.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let info = self.viewModel?.busArriveInfos[indexPath.row] else { return UITableViewCell() }
            if (info.arriveRemainTime == nil && indexPath.row == 0) {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: NoneInfoTableViewCell.reusableID, for: indexPath) as? NoneInfoTableViewCell else { return UITableViewCell() }
                return cell
            }
            else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: GetOnStatusCell.reusableID, for: indexPath) as? GetOnStatusCell else { return UITableViewCell() }
                
                cell.configure(routeType: self.viewModel?.routeType)
                cell.configureDelegate(self)
                self.viewModel?.$busArriveInfos
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] busArriveInfos in
                        guard let info = busArriveInfos[indexPath.row],
                              let cell = cell else { return }
                        
                        cell.configure(order: String(indexPath.row+1),
                                       remainingTime: info.arriveRemainTime?.toString(),
                                       remainingStationCount: info.relativePosition,
                                       busCongestionStatus: info.congestion?.toString(),
                                       arrivalTime: info.estimatedArrivalTime,
                                       currentLocation: info.currentStation,
                                       busNumber: info.plainNumber)
                    }
                    .store(in: &cell.cancellables)
                GetOnAlarmController.shared.$viewModel
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] getOnAlarmViewModel in
                        if let getOnAlarmViewModel = getOnAlarmViewModel,
                           info.vehicleId == getOnAlarmViewModel.getOnAlarmStatus.vehicleId,
                           self?.viewModel?.stationOrd == getOnAlarmViewModel.getOnAlarmStatus.targetOrd {
                            cell.configure(alarmButtonActive: true)
                        }
                        else {
                            cell.configure(alarmButtonActive: false)
                        }
                    }
                    .store(in: &cell.cancellables)
                
                return cell
            }
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: GetOffTableViewCell.reusableID, for: indexPath) as? GetOffTableViewCell else { return UITableViewCell() }
            guard let infos = self.viewModel?.busStationInfos else { return cell }
            let info = infos[indexPath.item]
            
            cell.configure(beforeColor: indexPath.item == 0 ? .clear : BBusColor.bbusGray,
                           afterColor: indexPath.item == infos.count - 1 ? .clear : BBusColor.bbusGray,
                           title: info.name,
                           description: indexPath.item == 0 ? "\(info.arsId)" : "\(info.arsId) | \(info.estimatedTime)분 소요",
                           type: indexPath.item == 0 ? .getOn : .waypoint)
            cell.configureDelegate(self)
            GetOffAlarmController.shared.$viewModel
                .receive(on: DispatchQueue.main)
                .sink { [weak self] getOffAlarmViewModel in
                    if let getOffAlarmViewModel = getOffAlarmViewModel,
                       self?.viewModel?.busRouteId == getOffAlarmViewModel.getOffAlarmStatus.busRouteId,
                       info.ord == getOffAlarmViewModel.getOffAlarmStatus.targetOrd {
                        cell.configure(alarmButtonActive: true)
                    }
                    else {
                        cell.configure(alarmButtonActive: false)
                    }
                }
                .store(in: &cell.cancellables)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "승차알람"
        case 1:
            return "하차알람"
        default:
            return nil
        }
    }
}

// MARK: - Delegate : UITableView
extension AlarmSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            guard let info = self.viewModel?.busArriveInfos.arriveInfos[indexPath.row] else { return 0 }
            switch info.arriveRemainTime {
            case nil :
                return indexPath.row == 0 ? NoneInfoTableViewCell.height : GetOnStatusCell.singleInfoCellHeight
            default :
                return GetOnStatusCell.infoCellHeight
            }
        case 1:
            return GetOffTableViewCell.cellHeight
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        header.contentView.backgroundColor = BBusColor.white
        header.textLabel?.textColor = BBusColor.black
        header.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return AlarmSettingView.tableViewHeaderHeight
    }
}

// MARK: - Delegate : BackButton
extension AlarmSettingViewController: BackButtonDelegate {
    func touchedBackButton() {
        self.coordinator?.terminate()
    }
}

// MARK: - Delegate: RefreshButton
extension AlarmSettingViewController: RefreshButtonDelegate {
    func buttonTapped() {
        self.refresh()
    }
}

// MARK: - Delegate: GetOffAlarmButton
extension AlarmSettingViewController: GetOffAlarmButtonDelegate {
    func shouldGoToMovingStatusScene(from cell: UITableViewCell) {
        guard let busRouteId = self.viewModel?.busRouteId,
              let indexPath = self.alarmSettingView.indexPath(for: cell),
              let startStationArsId = self.viewModel?.busStationInfos?.first?.arsId,
              let endStationArsId = self.viewModel?.busStationInfos?[indexPath.item].arsId,
              let targetOrd = self.viewModel?.busStationInfos?[indexPath.item].ord else { return }

        if startStationArsId == endStationArsId {
            self.alarmSettingAlert(message: "해당 정거장으로 하차알람을 등록할 수 없습니다.")
        }
        else {
            let result = GetOffAlarmController.shared.start(targetOrd: targetOrd, busRouteId: busRouteId, arsId: startStationArsId)
            switch result {
            case .success:
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.coordinator?.openMovingStatus(busRouteId: busRouteId, fromArsId: startStationArsId, toArsId: endStationArsId)
                }
            case .sameAlarm:
                self.alarmSettingActionSheet(titleMessage: "하차 알람을 종료하시겠습니까?", buttonMessage: "종료") {
                    self.coordinator?.closeMovingStatus()
                }
            case .duplicated:
                self.alarmSettingActionSheet(titleMessage: "이미 설정되어있는 하차알람이 있습니다.\n 재설정 하시겠습니까?", buttonMessage: "재설정") {
                    GetOffAlarmController.shared.stop()
                    _ = GetOffAlarmController.shared.start(targetOrd: targetOrd, busRouteId: busRouteId, arsId: endStationArsId)
                    UIView.animate(withDuration: 0.3) { [weak self] in
                        self?.coordinator?.resetMovingStatus(busRouteId: busRouteId, fromArsId: startStationArsId, toArsId: endStationArsId)
                    }
                }
            }
        }
    }
}

// MARK: - Delegate: GetOnAlarmButton
extension AlarmSettingViewController: GetOnAlarmButtonDelegate {
    func buttonTapped(for cell: UITableViewCell) {
        guard let indexPath = self.alarmSettingView.indexPath(for: cell),
              let arriveInfo = self.viewModel?.busArriveInfos.arriveInfos[indexPath.item],
              let busRouteId = self.viewModel?.busRouteId,
              let stationId = self.viewModel?.stationId,
              let targetOrd = self.viewModel?.stationOrd,
              let vehicleId = self.viewModel?.busArriveInfos.arriveInfos[indexPath.item].vehicleId,
              let busName = self.viewModel?.busName else { return }
        if let count = Int(String(arriveInfo.relativePosition?.prefixNumber() ?? "0")),
           count <= 1 {
            let arrivingSoonMessage = "버스가 곧 도착합니다"
            self.alarmSettingAlert(message: arrivingSoonMessage)
        }
        else {
            let result = GetOnAlarmController.shared.start(targetOrd: targetOrd,
                                                           vehicleId: vehicleId,
                                                           busName: busName,
                                                           busRouteId: busRouteId,
                                                           stationId: stationId)
            switch result {
            case .success: break
            case .sameAlarm:
                self.alarmSettingActionSheet(titleMessage: "승차 알람을 종료하시겠습니까?", buttonMessage: "종료") {
                    GetOnAlarmController.shared.stop()
                }
            case .duplicated:
                self.alarmSettingActionSheet(titleMessage: "이미 설정되어있는 승차알람이 있습니다.\n 재설정 하시겠습니까?", buttonMessage: "재설정") {
                    GetOnAlarmController.shared.stop()
                    let _ = GetOnAlarmController.shared.start(targetOrd: targetOrd,
                                                                   vehicleId: vehicleId,
                                                                   busName: busName,
                                                                   busRouteId: busRouteId,
                                                                   stationId: stationId)
                }
            }
        }
    }
}
