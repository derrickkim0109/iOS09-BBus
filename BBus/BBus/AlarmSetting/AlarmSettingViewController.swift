//
//  AlarmSettingViewController.swift
//  BBus
//
//  Created by 김태훈 on 2021/11/01.
//

import UIKit

class AlarmSettingViewController: UIViewController {

    enum Color {
        static let white = UIColor.white
        static let black = UIColor.black
        static let clear = UIColor.clear
        static let red = UIColor.red
        static let lightGray = UIColor.lightGray
        static let darkGray = UIColor.darkGray
        static let blueBus = UIColor.systemBlue
        static let tableViewSeperator = UIColor.systemGray6
        static let tableViewCellSubTitle = UIColor.systemGray
        static let tagBusNumber = UIColor.darkGray
        static let tagBusCongestion = UIColor.red
        static let greenLine = UIColor.green
        static let redLine = UIColor.red
        static let tableBackground = UIColor.systemGray5
        static let iconColor = UIColor(named: "alarmIconGrayColor")
        static let alarmTint = UIColor(named: "bbusGray")
    }
    
    enum Image {
        static let waypoint = UIImage(named: "StationCenterCircle")
        static let getOn = UIImage(named: "GetOn")
        static let clockIcon = UIImage(systemName: "clock")
        static let locationIcon = UIImage(named: "locationIcon")
        static let busIcon = UIImage(named: "grayBusIcon")
        static let alarmOffIcon = UIImage(named: "alarmOff")
        static let alarmOnIcon = UIImage(named: "alarmOn")
    }

    weak var coordinator: AlarmSettingCoordinator?
    private lazy var alarmSettingView = AlarmSettingView()
    private lazy var customNavigationBar = CustomNavigationBar()
    private lazy var refreshButton: UIButton = {
        let radius: CGFloat = 25

        let button = UIButton()
        button.setImage(MyImage.refresh, for: .normal)
        button.layer.cornerRadius = radius
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.darkGray
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureLayout()
        self.configureColor()
        self.configureDelegate()
        self.configureMOCKDATA()
    }
    
    // MARK: - Configure
    private func configureLayout() {
        let refreshButtonWidthAnchor: CGFloat = 50
        let refreshTrailingBottomInterval: CGFloat = -16

        self.view.addSubview(self.customNavigationBar)
        self.customNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.customNavigationBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.customNavigationBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.customNavigationBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        self.view.addSubview(self.alarmSettingView)
        self.alarmSettingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.alarmSettingView.topAnchor.constraint(equalTo: self.customNavigationBar.bottomAnchor),
            self.alarmSettingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.alarmSettingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.alarmSettingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        self.view.addSubview(self.refreshButton)
        self.refreshButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.refreshButton.widthAnchor.constraint(equalToConstant: refreshButtonWidthAnchor),
            self.refreshButton.heightAnchor.constraint(equalToConstant: refreshButtonWidthAnchor),
            self.refreshButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: refreshTrailingBottomInterval),
            self.refreshButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: refreshTrailingBottomInterval)
        ])
    }

    private func configureDelegate() {
        self.alarmSettingView.configureDelegate(self)
        self.customNavigationBar.configureDelegate(self)
    }

    private func configureColor() {
        self.view.backgroundColor = Color.white
        self.customNavigationBar.configureTintColor(color: Color.black)
        self.customNavigationBar.configureAlpha(alpha: 1)
    }

    private func configureMOCKDATA() {
        self.customNavigationBar.configureTitle(NSAttributedString(string: "461 ∙ 예술인마을.사당초등학교"))
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
            return 2
        case 1:
            return 10
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: GetOnStatusCell.reusableID, for: indexPath) as? GetOnStatusCell else { return UITableViewCell() }

            cell.configure(busColor: Color.blueBus)
            cell.configure(order: String(indexPath.row+1),
                           remainingTime: "2분 18초",
                           remainingStationCount: "2번째전",
                           busCongestionStatus: "여유",
                           arrivalTime: "오후 04시 11분 도착 예정",
                           currentLocation: "낙성대입구",
                           busNumber: "서울74사3082")
            cell.configureDelegate(self)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: GetOffTableViewCell.reusableID, for: indexPath) as? GetOffTableViewCell else { return UITableViewCell() }

            cell.configure(beforeColor: indexPath.item == 0 ? .clear : AlarmSettingViewController.Color.lightGray,
                           afterColor: indexPath.item == 9 ? .clear : AlarmSettingViewController.Color.lightGray,
                           title: "신촌오거리.현대백화점",
                           description: "14062 | 2분 소요",
                           type: indexPath.item == 0 ? .getOn : .waypoint)
            cell.configureDelegate(self)
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
            return GetOnStatusCell.cellHeight
        case 1:
            return GetOffTableViewCell.cellHeight
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        header.contentView.backgroundColor = Color.white
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

// MARK: - Delegate: GetOffAlarmButton
extension AlarmSettingViewController: GetOffAlarmButtonDelegate {
    func shouldGoToMovingStatusScene() {
        self.coordinator?.pushToMovingStatus()
    }
}

// MARK: - Delegate: GetOnAlarmButton
extension AlarmSettingViewController: GetOnAlarmButtonDelegate {
    func toggleGetOnAlarmSetting() {
        print("toggle Alarm")
    }
}