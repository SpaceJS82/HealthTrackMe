//
//  FriendVC.swift
//  Citrus
//
//  Created by Luka Verč on 18. 5. 25.
//

import UIKit
import HealthKit

class FriendVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //Data
    private var isRefreshing: Bool = false
    private var data: SharingManager.PersonData!
    private var events: [SharingManager.EventData] = []

    //UI
    private var settingsButton: UIBarButtonItem!
    private let navigationTitleLabel = NavigationLabel()

    private let headerView = FriendHeader()

    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    convenience init(_ friend: SharingManager.PersonData) {
        self.init()
        self.data = friend

        self.navigationTitleLabel.text = friend.isMe ? "Me".localized() : friend.name
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //Navigation
        navigationTitleLabel.textColor = .title
        navigationTitleLabel.font = UIFont.roundedFont(ofSize: 17, weight: .semibold)
        navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel

        self.navigationItem.leftBarButtonItems = [
            self.getNavigationItem(image: "chevron.left", target: self, action: #selector(onBack), backgroundColor: .groupedSecondaryBackground)
        ]

        self.settingsButton = self.getNavigationItem(image: "slider.horizontal.3", target: nil, action: nil, backgroundColor: .groupedSecondaryBackground)
        if self.data.isMe {
            self.navigationItem.rightBarButtonItems = [self.settingsButton]
        } else {
            self.navigationItem.rightBarButtonItems = [self.settingsButton, self.getNavigationItem(image: "bubble.fill", target: self, action: #selector(onPoke), backgroundColor: .groupedSecondaryBackground)]
        }
        (self.settingsButton.customView as? UIButton)?.showsMenuAsPrimaryAction = true


        //Background
        view.backgroundColor = .groupedBackground

        self.headerView.friendsVC = self

        //Tableview
        tableView.register(ActivityCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorEffect = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        view.addSubview(tableView)

        refreshControl.addAction(UIAction(handler: { action in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.refresh()
        }), for: .valueChanged)
        refreshControl.tintColor = .title
        tableView.refreshControl = refreshControl
    }

    @objc
    private func refresh() {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true

        AuthManager.shared.checkServerConnectivity { success in
            if success {
                let dispatchGroup = DispatchGroup()
                var isError: Bool = false

                dispatchGroup.enter()
                SharingManager.shared.getSleepScoresForThisWeek(for: self.data.username) { scores, error in
                    DispatchQueue.main.async {
                        self.headerView.refresh(with: self.data, data: scores)
                    }

                    if let _ = error {
                        isError = true
                    }
                    dispatchGroup.leave()
                }

                dispatchGroup.enter()
                SharingManager.shared.getEvents(for: self.data) { data, error in
                    if let _ = error {
                        isError = true
                    }
                    self.events = data
                    dispatchGroup.leave()
                }

                dispatchGroup.notify(queue: .main) {

                    if isError {
                        SharingManager.shared.displayError(error: .unknown, on: self)
                    }

                    self.refreshControl.endRefreshing()
                    self.tableView.reloadData()

                    let menuItems: [UIMenuElement] = self.data.isMe ? [

                        // Edit Name
                        UIAction(title: "Edit name".localized(), handler: { _ in
                            let alert = UIAlertController(title: "Edit name".localized(), message: nil, preferredStyle: .alert)
                            alert.addTextField { $0.placeholder = "Enter new name".localized() }
                            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
                            alert.addAction(UIAlertAction(title: "Save".localized(), style: .default, handler: { _ in
                                guard let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), newName.count >= 2 else {
                                    self.showValidationError()
                                    return
                                }

                                AuthManager.shared.changeName(to: newName) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .failure:
                                            SharingManager.shared.displayError(error: .unknown, on: self)
                                        case .success:
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            self.data.name = newName
                                            UserData.shared.fullName = newName
                                            self.refresh()
                                        }
                                    }
                                }
                            }))
                            alert.view.tintColor = .customBlue
                            self.present(alert, animated: true)
                        }),

                        // Change Username
                        UIAction(title: "Change email".localized(), handler: { _ in
                            let alert = UIAlertController(title: "Change email".localized(), message: nil, preferredStyle: .alert)
                            alert.addTextField { $0.placeholder = "Enter new email".localized() }
                            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
                            alert.addAction(UIAlertAction(title: "Save".localized(), style: .default, handler: { _ in
                                let newUsername = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                                let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
                                guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: newUsername) else {
                                    self.showValidationError()
                                    return
                                }

                                AuthManager.shared.changeUsername(to: newUsername) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .failure:
                                            SharingManager.shared.displayError(error: .unknown, on: self)
                                        case .success:
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        }
                                    }
                                }
                            }))
                            alert.view.tintColor = .customBlue
                            self.present(alert, animated: true)
                        }),

                        // Change Password
                        UIAction(title: "Change password".localized(), handler: { _ in
                            let alert = UIAlertController(
                                title: "Change password".localized(),
                                message: nil,
                                preferredStyle: .alert
                            )

                            alert.addTextField {
                                $0.placeholder = "Current password".localized()
                                $0.isSecureTextEntry = true
                            }
                            alert.addTextField {
                                $0.placeholder = "New password".localized()
                                $0.isSecureTextEntry = true
                            }

                            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

                            alert.addAction(UIAlertAction(title: "Save".localized(), style: .default, handler: { _ in
                                let oldPassword = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                let newPassword = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                                guard oldPassword.count >= 2, newPassword.count >= 2 else {
                                    self.showValidationError()
                                    return
                                }

                                AuthManager.shared.changePassword(oldPassword: oldPassword, newPassword: newPassword) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success:
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        case .failure:
                                            SharingManager.shared.displayError(error: .unknown, on: self)
                                        }
                                    }
                                }
                            }))
                            alert.view.tintColor = .customBlue
                            self.present(alert, animated: true)
                        }),

                        // Sign Out
                        UIAction(title: "Sign out".localized(), attributes: .destructive, handler: { _ in
                            let alert = UIAlertController(title: "Are you sure?".localized(), message: "You will be signed out.".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
                            alert.addAction(UIAlertAction(title: "Sign out".localized(), style: .destructive, handler: { _ in
                                AuthManager.shared.signOut()
                                self.navigationController?.popViewController(animated: true)
                            }))
                            alert.view.tintColor = .customBlue
                            self.present(alert, animated: true)
                        })

                    ] : [

                        // Remove Friend
                        UIAction(title: "Remove friend".localized(), attributes: .destructive, handler: { _ in
                            let alert = UIAlertController(title: "Remove friend".localized(), message: "Are you sure you want to remove this friend?".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
                            alert.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive, handler: { _ in
                                SharingManager.shared.removeFriend(username: self.data.username) { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            SharingManager.shared.displayError(error: error, on: self)
                                        } else {
                                            self.navigationController?.popViewController(animated: true)
                                        }
                                    }
                                }
                            }))
                            alert.view.tintColor = .customBlue
                            self.present(alert, animated: true)
                        })
                    ]

                    (self.settingsButton.customView as? UIButton)?.menu = UIMenu(children: menuItems)

                    self.isRefreshing = false
                }
            } else {
                DispatchQueue.main.async {
                    let alert = AlertVC(icon: UIImage(systemName: "wifi.slash"), title: "No internet connection".localized(), body: "Yoa needs access to the internet so it can ask your friends what they did today.\nTry again later.".localized(), closeIconName: "arrow.trianglehead.clockwise") { _ in
                        self.refresh()
                    }

                    let navigation = ThemeNavigationViewController(rootViewController: alert)
                    navigation.modalPresentationStyle = .overCurrentContext
                    navigation.modalTransitionStyle = .crossDissolve
                    self.present(navigation, animated: true)

                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                }
            }
        }
    }

    private func showValidationError() {
        let errorAlert = UIAlertController(
            title: "Invalid Input".localized(),
            message: "Input must be at least 2 characters.".localized(),
            preferredStyle: .alert
        )
        errorAlert.addAction(UIAlertAction(title: "Done".localized(), style: .default))
        errorAlert.view.tintColor = .customBlue
        self.present(errorAlert, animated: true)
    }


    @objc
    private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    private func onPoke() {
        let alert = UIAlertController(
            title: "Send a message".localized(),
            message: "Will send a notification to them, if they have notifications turned on.".localized(),
            preferredStyle: .alert
        )

        alert.addTextField {
            $0.placeholder = "Message".localized()
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

        alert.addAction(UIAlertAction(title: "Send".localized(), style: .default, handler: { _ in
            let message = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard message.count >= 1 else {
                return
            }

            SharingManager.shared.sendPoke(to: self.data, message: message) { success in
                DispatchQueue.main.async {
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        SharingManager.shared.displayError(error: .unknown, on: self)
                    }
                }
            }
        }))
        alert.view.tintColor = .customBlue
        self.present(alert, animated: true)
    }

    //Scrollview delegates
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if -self.tableView.contentOffset.y + 40 < view.safeAreaInsets.top - 50 {
            self.navigationTitleLabel.show()
        } else {
            self.navigationTitleLabel.hide()
        }
    }

    //TableView delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 515
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ActivityCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ActivityCell {
            cell.refresh(with: self.events[indexPath.row])
        }
    }


    private class FriendHeader: UIView {

        //Data
        private var data: SharingManager.PersonData?

        //UI
        private let iconView = UILabel()
        private let nameView = UILabel()
        public var friendsVC: FriendVC!

        private let lastNightTitle = UILabel()
        private let ringBackView = UIView()
        private let ringView = PercentageRingView()
        private let ringIconView = UIImageView()
        private let characterBackView = UIView()
        private let characterView = CharacterView(frame: .zero)

        private let thisWeekLabel = UILabel()
        private let thisWeekUploadButton = UIButton()
        private let thisWeekTable = MyHStack()

        private let workoutsLabel = UILabel()

        override func layoutSubviews() {
            super.layoutSubviews()

            iconView.frame = CGRect(x: (self.frame.width - 75) / 2, y: 0, width: 75, height: 75)
            iconView.layer.cornerRadius = 75 / 2
            iconView.setDefaultShadow()
            nameView.frame = CGRect(x: 15, y: iconView.frame.maxY + 10, width: self.frame.width - 30, height: 25)

            lastNightTitle.frame = CGRect(x: 15, y: nameView.frame.maxY + 30, width: self.frame.width - 30, height: 20)

            ringBackView.frame = CGRect(x: 15, y: lastNightTitle.frame.maxY + 10, width: (self.frame.width - 40) / 2, height: 100)
            ringBackView.layer.cornerRadius = 24
            ringBackView.setDefaultShadow()
            ringView.frame = CGRect(x: (ringBackView.frame.width - 75) / 2, y: (ringBackView.frame.height - 75) / 2, width: 75, height: 75)
            ringIconView.frame = CGRect(x: (ringView.frame.width - 30) / 2, y: (ringView.frame.height - 30) / 2, width: 30, height: 30)

            characterBackView.frame = CGRect(x: ringBackView.frame.maxX + 10, y: lastNightTitle.frame.maxY + 10, width: (self.frame.width - 40) / 2, height: 100)
            ringBackView.layer.cornerRadius = 24
            characterBackView.setDefaultShadow()
            characterView.frame = CGRect(x: (ringBackView.frame.width - 85) / 2, y: (ringBackView.frame.height - 85) / 2, width: 85, height: 85)

            thisWeekLabel.frame = CGRect(x: 15, y: characterBackView.frame.maxY + 30, width: self.frame.width - 30, height: 20)
            thisWeekUploadButton.frame = CGRect(x: 15, y: characterBackView.frame.maxY + 30, width: self.frame.width - 30, height: 20)
            thisWeekTable.frame = CGRect(x: 15, y: thisWeekLabel.frame.maxY + 10, width: self.frame.width - 30, height: 100)
            thisWeekTable.layer.cornerRadius = 24
            thisWeekTable.setDefaultShadow()

            workoutsLabel.frame = CGRect(x: 15, y: self.frame.height - 50, width: self.frame.width - 30, height: 40)

        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            iconView.backgroundColor = .groupedSecondaryBackground
            iconView.clipsToBounds = true
            iconView.textAlignment = .center
            iconView.textColor = .title
            iconView.font = .roundedFont(ofSize: 42, weight: .semibold)
            self.addSubview(iconView)

            nameView.textAlignment = .center
            nameView.textColor = .title
            nameView.font = .roundedFont(ofSize: 17, weight: .semibold)
            self.addSubview(nameView)


            lastNightTitle.text = "Last night".localized()
            lastNightTitle.textAlignment = .left
            lastNightTitle.textColor = .title
            lastNightTitle.font = .roundedFont(ofSize: 17, weight: .semibold)
            self.addSubview(lastNightTitle)

            ringBackView.backgroundColor = .groupedSecondaryBackground
            ringBackView.layer.cornerRadius = 24
            ringBackView.layer.cornerCurve = .continuous
            self.addSubview(ringBackView)

            ringView.foregroundColorRing = .customPurple
            ringView.ringWidth = 7.5
            ringBackView.addSubview(ringView)

            ringIconView.image = UIImage(systemName: "moon.zzz.fill")
            ringIconView.contentMode = .scaleAspectFit
            ringIconView.tintColor = .title
            ringView.addSubview(ringIconView)

            characterBackView.backgroundColor = .groupedSecondaryBackground
            characterBackView.layer.cornerRadius = 24
            characterBackView.layer.cornerCurve = .continuous
            self.addSubview(characterBackView)

            characterView.contentMode = .scaleAspectFit
            characterBackView.addSubview(characterView)


            thisWeekLabel.text = "This week".localized()
            thisWeekLabel.textAlignment = .left
            thisWeekLabel.textColor = .title
            thisWeekLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            self.addSubview(thisWeekLabel)

            thisWeekUploadButton.isHidden = true
            thisWeekUploadButton.setTitle("Upload missing days", for: .normal)
            thisWeekUploadButton.setTitleColor(.customOrange, for: .normal)
            thisWeekUploadButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
            thisWeekUploadButton.contentHorizontalAlignment = .right
            thisWeekUploadButton.addAction(UIAction(handler: { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let calendar = Calendar.current
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let todayUTC = utcCalendar.startOfDay(for: Date())

                let dates = Array((0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: todayUTC) }.reversed())
                var isError = false

                func processNext(_ index: Int) {
                    guard index < dates.count else {
                        if isError {
                            SharingManager.shared.displayError(error: .unknown, on: self.friendsVC)
                        } else {
                            self.friendsVC.refresh()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        return
                    }

                    let date = dates[index]

                    HealthData.shared.getQualityOfSleep(for: date) { score in
                        SharingManager.shared.uploadSleepScore(value: score, date: date) { success in
                            if success {
                                print("✅ Uploaded score \(score) for \(date)")
                            } else {
                                isError = true
                            }

                            processNext(index + 1)
                        }
                    }
                }

                processNext(0)
            }), for: .touchUpInside)
            self.addSubview(thisWeekUploadButton)

            thisWeekTable.layer.cornerCurve = .continuous
            thisWeekTable.backgroundColor = .groupedSecondaryBackground
            self.addSubview(thisWeekTable)


            workoutsLabel.text = "Highlights".localized()
            workoutsLabel.textAlignment = .left
            workoutsLabel.textColor = .title
            workoutsLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            self.addSubview(workoutsLabel)

        }

        public func refresh(with: SharingManager.PersonData, data: [SharingManager.HealthMetric]) {
            self.data = with

            if let initial = with.name.first, !with.isMe {
                self.iconView.text = String(initial)
            } else {
                self.iconView.text = "🍊"
            }

            self.nameView.text = (with.isMe) ? "Me".localized() : with.name

            self.ringView.percent = (with.sleepScore ?? 0) * 100
            if let score = with.sleepScore {
                self.characterView.setAnimation(score.getBasicYoaForSleepScore())
            } else {
                self.characterView.setAnimation("Explorer")
            }

            self.thisWeekTable.setViews(data.map({ healthMetric in
                return SharingManager.PersonData.SleepScoreDate(date: healthMetric.date, score: healthMetric.value)
            }).sorted(by: {$0.date < $1.date}).enumerated().map({ index, item in
                return WeekDataCell(item)
                    .size(CGSize(width: (self.thisWeekTable.frame.width - 90) / 7))
                    .padding(UIEdgeInsets(left: index == 0 ? 15 : 0, right: index == 6 ? 15 : 10))
            }))

            self.thisWeekUploadButton.isHidden = !with.isMe || (with.isMe && data.filter({$0.value > 0}).count >= 7)

        }

        private class WeekDataCell: MyStack.StackView {

            private let dateLabel = UILabel()
            private let dayLabel = UILabel()
            private let ringView = PercentageRingView()

            convenience init(_ data: SharingManager.PersonData.SleepScoreDate) {
                self.init()

                self.ringView.percent = data.score * 100

                let calendar = Calendar.current
                let day = calendar.component(.day, from: data.date)

                dateLabel.text = "\(day)"

                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateFormat = "EEE"

                dayLabel.text = formatter.string(from: data.date)

            }

            override func layoutSubviews() {
                super.layoutSubviews()

                let y = (self.frame.height - 73) / 2

                dateLabel.frame = CGRect(x: 0, y: y, width: self.frame.width, height: 18)
                dayLabel.frame = CGRect(x: 0, y: dateLabel.frame.maxY, width: self.frame.width, height: 15)
                ringView.frame = CGRect(x: (self.frame.width - 35) / 2, y: dayLabel.frame.maxY + 5, width: 35, height: 35)

            }

            override init(frame: CGRect) {
                super.init(frame: frame)

                dateLabel.textAlignment = .center
                dateLabel.textColor = .title
                dateLabel.font = .roundedFont(ofSize: 15, weight: .semibold)
                self.addSubview(dateLabel)

                dayLabel.textAlignment = .center
                dayLabel.textColor = .secondaryText
                dayLabel.font = .roundedFont(ofSize: 10, weight: .semibold)
                self.addSubview(dayLabel)

                ringView.foregroundColorRing = .customPurple
                ringView.ringWidth = 5
                self.addSubview(ringView)

            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }


    private class ActivityCell: UITableViewCell, UIContextMenuInteractionDelegate {

        //Data
        private var event: SharingManager.EventData?


        //UI
        private let backView = UIView()

        private let iconView = UIImageView()
        private let titleView = UILabel()
        private let descriptionView = UILabel()

        override func layoutSubviews() {

            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24
            backView.setDefaultShadow()

            iconView.frame = CGRect(x: 20, y: 20, width: 35, height: 35)
            titleView.frame = CGRect(x: 75, y: 16, width: backView.frame.width - 90, height: 22)
            descriptionView.frame = CGRect(x: 75, y: titleView.frame.maxY, width: backView.frame.width - 90, height: 22)

        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            self.contentView.isHidden = true

            backView.layer.cornerCurve = .continuous
            self.addSubview(backView)

            iconView.contentMode = .scaleAspectFit
            backView.addSubview(iconView)

            titleView.text = "Title..."
            titleView.textAlignment = .left
            titleView.font = UIFont.roundedFont(ofSize: 17, weight: .semibold)
            backView.addSubview(titleView)

            descriptionView.text = "Description..."
            descriptionView.textAlignment = .left
            descriptionView.font = UIFont.systemFont(ofSize: 14)
            backView.addSubview(descriptionView)

            let interaction = UIContextMenuInteraction(delegate: self)
            backView.addInteraction(interaction)

        }

        func refresh(with: SharingManager.EventData) {

            self.event = with

            backView.backgroundColor = .groupedSecondaryBackground
            iconView.tintColor = .title
            titleView.textColor = .title
            descriptionView.textColor = .secondaryText

            if with.type == .workout {
                let workout = with.getWorkout()
                self.titleView.text = workout?.getWorkoutTitle()
                self.iconView.image = workout?.getWorkoutSymbolImage()
                self.iconView.tintColor = .customGreen
                self.descriptionView.text = with.getMainText()
            } else if with.type == .healthAchievement {
                let healthType = with.metaData?["metricType"] as? String ?? "sleep"
                if healthType == "sleep" {
                    self.titleView.text = "Sleep quality".localized()
                    self.iconView.tintColor = .customPurple
                } else if healthType == "stress" {
                    self.titleView.text = "Stress score".localized()
                    self.iconView.tintColor = .customBlue
                } else if healthType == "graphData" {
                    self.titleView.text = with.metaData?["metricTitle"] as? String
                    self.iconView.tintColor = .customOrange
                }

                self.descriptionView.text = with.getMainText()

                self.iconView.image = with.getIcon()
            }
        }

        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            guard let data = event,
                  let vc = self.viewController as? FriendVC,
                  data.user?.isMe ?? false else { return nil }

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in

                let removeAction = UIAction(title: "Hide from friends".localized(), attributes: .destructive) { _ in
                    let alert = UIAlertController(title: "Hide?".localized(), message: "Are you sure you want to hide this event?", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Hide".localized(), style: .destructive, handler: { _ in
                        SharingManager.shared.deleteEvent(id: data.id) { success in
                            DispatchQueue.main.async {
                                if success {
                                    vc.events.removeAll(where: {$0.id == data.id})
                                    vc.tableView.reloadData()
                                } else {
                                    SharingManager.shared.displayError(error: .unknown, on: vc)
                                }
                            }
                        }
                    }))

                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

                    alert.view.tintColor = .customBlue

                    vc.present(alert, animated: true)
                }

                return UIMenu(children: [removeAction])
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}
