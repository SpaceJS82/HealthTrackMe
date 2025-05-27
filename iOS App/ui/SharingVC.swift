//
//  SharingVC.swift
//  Citrus
//
//  Created by Luka Verč on 14. 5. 25.
//

import UIKit
import HealthKit

class SharingVC: GradientViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //Data
    private var isFirstRefresh: Bool = true
    private var isRefreshing: Bool = false
    fileprivate var data: [SharingManager.PersonData] = []
    private var selectedIndex: IndexPath?

    //UI
    private let indicatorVC = ActivityIndicatorVC()

    private let navigationTitleLabel = NavigationLabel()
    private var navigationButton: UIBarButtonItem!

    private let headerView = SharingHeader()

    private let refreshControl = UIRefreshControl()
    public let tableView = UITableView(frame: .zero, style: .grouped)

    private let setUpButton = UIButton()
    private let setUpExplanationView = UILabel()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.isFirstRefresh {
            self.refresh()
        }

        if !UserData.shared.sharingExplainerShown {
            self.present(ThemeNavigationViewController(rootViewController: ExplainerVC(icon: SFSymbol(systemName: "person.2.fill"), mainText: "Say hello to Sharing".localized(), subText: "Connect and share your health journey with firends, from workouts to sleep scores... Motivate each other, celebrate progress, and stay on track together.".localized(), color: .customOrange) {
                UserData.shared.sharingExplainerShown = true
            }), animated: true)
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.setGradient(color1: UIColor.secondaryText.withAlphaComponent(0.15), color2: .groupedBackground.withAlphaComponent(0.15))

        tableView.frame = view.bounds

        setUpButton.frame = CGRect(x: (view.frame.width - 200) / 2, y: (view.frame.height) / 2 - 25, width: 200, height: 50)

        setUpExplanationView.autoFrame(x: (view.frame.width - 200) / 2, y: setUpButton.frame.maxY + 15, width: 200)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .groupedBackground

        //Navigation
        navigationTitleLabel.text = "Sharing".localized()
        navigationTitleLabel.textColor = .title
        navigationTitleLabel.font = UIFont.roundedFont(ofSize: 17, weight: .semibold)
        navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel

        self.navigationButton = self.getNavigationItem(image: "person.crop.circle", target: nil, action: nil, backgroundColor: .groupedSecondaryBackground)
        (self.navigationButton.customView as? UIButton)?.showsMenuAsPrimaryAction = true
        (self.navigationButton.customView as? UIButton)?.menu = UIMenu(children: [

            // Edit Name
            UIAction(title: "Edit name".localized(), handler: { _ in
                let alert = UIAlertController(title: "Edit name".localized(), message: nil, preferredStyle: .alert)
                alert.addTextField { $0.placeholder = "Enter new name".localized() }
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
                alert.addAction(UIAlertAction(title: "Save".localized(), style: .default, handler: { _ in
                    let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if newName.count < 2 {
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
                    self.refresh()
                }))
                alert.view.tintColor = .customBlue
                self.present(alert, animated: true)
            })

        ])


        tableView.isHidden = true
        tableView.register(PersonCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorEffect = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(onRefreshControl), for: .valueChanged)
        refreshControl.tintColor = .title
        tableView.refreshControl = refreshControl


        setUpButton.isHidden = true
        setUpButton.backgroundColor = .customBlue
        setUpButton.layer.cornerRadius = 20
        setUpButton.layer.cornerCurve = .continuous
        setUpButton.setTitle("Set up my profile".localized(), for: .normal)
        setUpButton.setTitleColor(.white, for: .normal)
        setUpButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        setUpButton.addAction(UIAction(handler: { _ in
            self.present(ThemeNavigationViewController(rootViewController: RegisterVC(for: self)), animated: true)
        }), for: .touchUpInside)
        view.addSubview(setUpButton)

        setUpExplanationView.isHidden = true
        setUpExplanationView.text = "Set up your profile to start sharing your moments on your wellbeing jounrey with friends.".localized()
        setUpExplanationView.textAlignment = .left
        setUpExplanationView.textColor = .secondaryText
        setUpExplanationView.font = .roundedFont(ofSize: 14, weight: .regular)
        setUpExplanationView.numberOfLines = 0
        view.addSubview(setUpExplanationView)

        if #available(iOS 18.0, *) {
            indicatorVC.setDismissAction {
                self.tabBarController?.setTabBarHidden(false, animated: true)
            }
        }

        self.refresh()
    }

    @objc
    private func onRefreshControl() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.refresh()
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
    public func refresh() {

        guard !self.isRefreshing else { return }
        self.isRefreshing = true

        if self.isFirstRefresh {
            self.present(self.indicatorVC, animated: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.indicatorVC.dismiss(animated: true)
                }
            }
        }

        AuthManager.shared.checkServerConnectivity { success in
            if success {
                let dispatchGroup = DispatchGroup()

                dispatchGroup.enter()
                SharingManager.shared.getEventData { data, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            SharingManager.shared.displayError(error: error, on: self) {
                                self.refresh()
                            }
                        } else {
                            self.headerView.refresh(with: data.sorted(by: {$0.date > $1.date}))
                        }
                    }
                    dispatchGroup.leave()
                }

                dispatchGroup.enter()
                SharingManager.shared.getPersonData { data, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            SharingManager.shared.displayError(error: error, on: self) {
                                self.refresh()
                            }
                        } else {
                            self.data = data.sorted(by: {
                                let score0 = $0.sleepScore ?? 0
                                let score1 = $1.sleepScore ?? 0

                                if score0 == score1 {
                                    return $0.name < $1.name
                                } else {
                                    return score0 > score1
                                }
                            })
                            self.tableView.reloadData()
                        }
                    }
                    dispatchGroup.leave()
                }

                dispatchGroup.notify(queue: .main) {
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                    self.isFirstRefresh = false

                    self.navigationItem.rightBarButtonItem = AuthManager.shared.willAutoLogin ? self.navigationButton : nil

                    self.tableView.isHidden = !AuthManager.shared.willAutoLogin
                    self.setUpButton.isHidden = AuthManager.shared.willAutoLogin
                    self.setUpExplanationView.isHidden = AuthManager.shared.willAutoLogin

                    self.indicatorVC.dismiss(animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    let alert = AlertVC(icon: UIImage(systemName: "wifi.slash"), title: "No internet connection".localized(), body: "Yoa needs access to the internet so it can ask your friends what they did today.\nTry again later.".localized(), closeIconName: "arrow.trianglehead.clockwise") { _ in
                        self.refresh()
                    }

                    self.indicatorVC.dismiss(animated: true)

                    let navigation = ThemeNavigationViewController(rootViewController: alert)
                    navigation.modalPresentationStyle = .overCurrentContext
                    navigation.modalTransitionStyle = .crossDissolve
                    self.present(navigation, animated: true)

                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                    self.isFirstRefresh = false
                }

            }
        }

    }

    //Scrollview delegates
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if -self.tableView.contentOffset.y + 40 < view.safeAreaInsets.top + 10 {
            self.navigationTitleLabel.show()
        } else {
            self.navigationTitleLabel.hide()
        }
    }

    //TableView delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 480
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PersonCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PersonCell {
            cell.refresh(with: self.data[indexPath.row])
            cell.row = indexPath.row
        }
    }


    //Classes
    private class SharingHeader: UIView {

        //Data
        private var data: [SharingManager.EventData] = []

        //UI
        public let titleView = UILabel()

        private let highlightsLabel = UILabel()
        private let eventsStack = MyHStack()
        private let emptyLabel = UILabel()

        private let frendsTitle = UILabel()
        private let friendsButton = UIButton()

        override func layoutSubviews() {
            super.layoutSubviews()

            titleView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: 40)

            highlightsLabel.frame = CGRect(x: 15, y: titleView.frame.maxY + 30, width: self.frame.width - 30, height: 40)
            eventsStack.frame = CGRect(x: 0, y: highlightsLabel.frame.maxY - 3, width: self.frame.width, height: 313)
            emptyLabel.frame = eventsStack.frame

            frendsTitle.frame = CGRect(x: 15, y: eventsStack.frame.maxY + 10, width: self.frame.width - 30, height: 40)
            friendsButton.frame = CGRect(x: 15, y: eventsStack.frame.maxY + 10, width: self.frame.width - 30, height: 40)

        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            titleView.text = "Sharing".localized()
            titleView.font = UIFont.roundedFont(ofSize: 32, weight: .bold)
            titleView.textColor = .title
            titleView.textAlignment = .left
            self.addSubview(titleView)

            highlightsLabel.text = "Highlights".localized()
            highlightsLabel.font = UIFont.roundedFont(ofSize: 20, weight: .semibold)
            highlightsLabel.textColor = .title
            highlightsLabel.textAlignment = .left
            self.addSubview(highlightsLabel)

            self.addSubview(eventsStack)

            emptyLabel.text = "No event shared with you yet".localized()
            emptyLabel.textColor = .secondaryText
            emptyLabel.textAlignment = .center
            emptyLabel.font = .roundedFont(ofSize: 17, weight: .regular)
            emptyLabel.numberOfLines = 0
            self.addSubview(emptyLabel)

            frendsTitle.text = "Friends".localized()
            frendsTitle.font = UIFont.roundedFont(ofSize: 17, weight: .semibold)
            frendsTitle.textColor = .title
            frendsTitle.textAlignment = .left
            self.addSubview(frendsTitle)

            friendsButton.setTitle("Requests".localized(), for: .normal)
            friendsButton.setTitleColor(.customBlue, for: .normal)
            friendsButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
            friendsButton.contentHorizontalAlignment = .right
            friendsButton.addAction(UIAction(handler: { _ in
                self.viewController?.navigationController?.pushViewController(FriendRequestsVC(), animated: true)
            }), for: .touchUpInside)
            self.addSubview(friendsButton)

        }

        public func refresh(with: [SharingManager.EventData]) {
            self.data = with
            self.eventsStack.setViews(self.data.enumerated().map({ index, data in
                return EventCell(data: data, header: self)
                    .size(CGSize(width: 283))
                    .padding(UIEdgeInsets(top: 5, left: (index == 0) ? 15 : 0, bottom: 22, right: (index == self.data.count - 1) ? 15 : 2))
            }))
            self.emptyLabel.isHidden = !self.data.isEmpty
        }

        private class EventCell: MyStack.StackView, UIContextMenuInteractionDelegate, EmojiSelectorVCDelegate {

            //Data
            private var data: SharingManager.EventData?
            private var header: SharingHeader!

            //UI
            private let backView = UIView()

            private let messageView = UILabel()
            private let timeLabel = UILabel()

            private let imageBackground = UIView()
            private let imageView = UIImageView()

            private let titleView = UILabel()
            private let subTitleView = UILabel()

            private let rightSideReactionBadge = UILabel()
            private let leftSideReactionBadge = UILabel()
            private let reactionsButton = UIButton()

            convenience init(data: SharingManager.EventData, header: SharingHeader) {
                self.init()
                self.data = data
                self.header = header

                self.refresh(with: data)

            }

            override func layoutSubviews() {
                super.layoutSubviews()

                backView.frame = CGRect(x: 0, y: 8, width: self.frame.width - 8, height: self.frame.height - 8)
                backView.layer.cornerRadius = 24
                backView.setDefaultShadow()
                self.layer.shadowRadius = 5

                messageView.frame = CGRect(x: 30, y: 20, width: backView.frame.width - 60, height: 45)
                timeLabel.frame = CGRect(x: 30, y: messageView.frame.maxY, width: backView.frame.width - 60, height: 15)

                imageBackground.frame = CGRect(x: (backView.frame.width - 100) / 2, y: timeLabel.frame.maxY + 10, width: 100, height: 100)
                imageBackground.layer.cornerRadius = 100 / 2

                imageView.frame = CGRect(x: (imageBackground.frame.width - 70) / 2, y: (imageBackground.frame.height - 70) / 2, width: 70, height: 70)

                titleView.frame = CGRect(x: 30, y: imageBackground.frame.maxY + 20, width: backView.frame.width - 60, height: 25)
                subTitleView.frame = CGRect(x: 30, y: titleView.frame.maxY, width: backView.frame.width - 60, height: 25)

                rightSideReactionBadge.frame = CGRect(x: self.frame.width - 35, y: 0, width: 35, height: 35)
                rightSideReactionBadge.layer.cornerRadius = 35 / 2
                rightSideReactionBadge.layer.borderWidth = 2
                rightSideReactionBadge.layer.borderColor = UIColor.groupedBackground.cgColor

                leftSideReactionBadge.frame = CGRect(x: self.frame.width - 60, y: 0, width: 35, height: 35)
                leftSideReactionBadge.layer.cornerRadius = 35 / 2
                leftSideReactionBadge.layer.borderWidth = 2
                leftSideReactionBadge.layer.borderColor = UIColor.groupedBackground.cgColor

                reactionsButton.frame = CGRect(x: leftSideReactionBadge.frame.minX, y: leftSideReactionBadge.frame.minY, width: rightSideReactionBadge.frame.maxX - leftSideReactionBadge.frame.minX, height: rightSideReactionBadge.frame.height)

            }

            override init(frame: CGRect) {
                super.init(frame: frame)

                backView.layer.cornerCurve = .continuous
                backView.backgroundColor = .groupedSecondaryBackground
                self.addSubview(backView)

                messageView.textAlignment = .left
                messageView.textColor = .title
                messageView.adjustsFontSizeToFitWidth = true
                messageView.font = .roundedFont(ofSize: 17, weight: .semibold)
                messageView.numberOfLines = 2
                backView.addSubview(messageView)

                timeLabel.textAlignment = .left
                timeLabel.textColor = .secondaryText
                timeLabel.adjustsFontSizeToFitWidth = true
                timeLabel.font = .roundedFont(ofSize: 10, weight: .regular)
                backView.addSubview(timeLabel)

                imageBackground.backgroundColor = .groupedBackground
                backView.addSubview(imageBackground)

                imageView.contentMode = .scaleAspectFit
                imageBackground.addSubview(imageView)

                titleView.textAlignment = .center
                titleView.textColor = .customGreen
                titleView.adjustsFontSizeToFitWidth = true
                titleView.font = .roundedFont(ofSize: 20, weight: .semibold)
                backView.addSubview(titleView)

                subTitleView.textAlignment = .center
                subTitleView.textColor = .title
                subTitleView.adjustsFontSizeToFitWidth = true
                subTitleView.font = .roundedFont(ofSize: 17, weight: .semibold)
                backView.addSubview(subTitleView)

                rightSideReactionBadge.textColor = .title
                rightSideReactionBadge.textAlignment = .center
                rightSideReactionBadge.font = .roundedFont(ofSize: 14, weight: .semibold)
                rightSideReactionBadge.adjustsFontSizeToFitWidth = true
                rightSideReactionBadge.backgroundColor = .groupedSecondaryBackground
                rightSideReactionBadge.clipsToBounds = true
                self.addSubview(rightSideReactionBadge)

                leftSideReactionBadge.textColor = .title
                leftSideReactionBadge.textAlignment = .center
                leftSideReactionBadge.font = .roundedFont(ofSize: 14, weight: .semibold)
                leftSideReactionBadge.adjustsFontSizeToFitWidth = true
                leftSideReactionBadge.backgroundColor = .groupedSecondaryBackground
                leftSideReactionBadge.clipsToBounds = true
                self.addSubview(leftSideReactionBadge)

                reactionsButton.addTarget(self, action: #selector(onReactions), for: .touchUpInside)
                self.addSubview(reactionsButton)

                let interaction = UIContextMenuInteraction(delegate: self)
                backView.addInteraction(interaction)

            }

            public func refresh(with data: SharingManager.EventData) {
                self.data = data
                self.timeLabel.text = Date.now.timeIntervalSince(data.date).howMuchTimeAgoDescription

                if data.reactions.isEmpty {
                    self.rightSideReactionBadge.isHidden = true
                    self.leftSideReactionBadge.isHidden = true
                } else if data.reactions.count == 1 {
                    self.rightSideReactionBadge.isHidden = false
                    self.rightSideReactionBadge.text = data.reactions.last?.content
                    self.leftSideReactionBadge.isHidden = true
                } else {
                    self.leftSideReactionBadge.isHidden = false
                    self.leftSideReactionBadge.text = data.reactions.last?.content
                    self.rightSideReactionBadge.isHidden = false
                    self.rightSideReactionBadge.text = String(data.reactions.count - 1) + "+"
                }

                if data.type == .workout {
                    self.messageView.text = "_NAME_ finished a workout".localized().replacingOccurrences(of: "_NAME_", with: data.user?.name ?? "Unknown")

                    self.imageView.image = data.getIcon()
                    self.imageView.tintColor = .customGreen

                    self.titleView.text = data.getMainText()

                    if let workout = data.getWorkout() {
                        self.subTitleView.text = workout.getCustomTitle()
                    }
                } else if data.type == .healthAchievement {
                    let healthType = data.metaData?["metricType"] as? String ?? "sleep"
                    if healthType == "sleep" {
                        self.messageView.text = "_NAME_ shared their sleep quality".localized().replacingOccurrences(of: "_NAME_", with: data.user?.name ?? "Unknown")
                        self.imageView.tintColor = .customPurple
                        self.titleView.textColor = .customPurple
                    } else if healthType == "stress" {
                        self.messageView.text = "_NAME_ shared their stress score".localized().replacingOccurrences(of: "_NAME_", with: data.user?.name ?? "Unknown")
                        self.imageView.tintColor = .customBlue
                        self.titleView.textColor = .customBlue
                    } else if healthType == "graphData" {
                        self.messageView.text = "_NAME_ shared a new health metric".localized().replacingOccurrences(of: "_NAME_", with: data.user?.name ?? "Unknown")
                        self.imageView.tintColor = .customOrange
                        self.titleView.textColor = .customOrange
                    }

                    self.titleView.text = data.getMainText()

                    self.imageView.image = data.getIcon()

                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE"
                    self.subTitleView.text = formatter.string(from: data.date)
                }
            }

            @objc
            private func onReactions() {
                guard let data = self.data, !data.reactions.isEmpty else { return }
                guard let sharingVC = self.viewController as? SharingVC else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let vc = EventReactionsVC(event: data)
                vc.sharingVC = sharingVC
                self.viewController?.present(ThemeNavigationViewController(rootViewController: vc), animated: true)
            }

            func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

                guard let vc = self.viewController as? SharingVC,
                      let data = self.data else {
                    return nil
                }

                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in

                    let reactToEvent = UIAction(title: "React".localized(), image: UIImage(systemName: "star")) { _ in
                        if let viewController = self.viewController {
                            let emojiPicker = EmojiSelectorVC()
                            emojiPicker.delegate = self
                            viewController.present(ThemeNavigationViewController(rootViewController: emojiPicker), animated: true)
                        }
                    }

                    let removeReaction = UIAction(title: "Remove reaction".localized(), image: UIImage(systemName: "star.slash"), attributes: .destructive) { _ in
                        if let reactionId = data.reactions.filter({$0.user.isMe}).first?.id {
                            SharingManager.shared.deleteReaction(id: reactionId) { success in
                                DispatchQueue.main.async {
                                    if success {
                                        data.reactions.removeAll(where: {$0.user.isMe})
                                        self.refresh(with: data)
                                    } else {
                                        SharingManager.shared.displayError(error: .unknown, on: vc)
                                    }
                                }
                            }
                        }
                    }

                    let hideAction = UIAction(title: "Hide from friends".localized(), image: UIImage(systemName: "eye.slash"), attributes: .destructive) { _ in
                        let alert = UIAlertController(title: "Hide?".localized(), message: "Are you sure you want to hide this event?", preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Hide".localized(), style: .destructive, handler: { _ in
                            SharingManager.shared.deleteEvent(id: data.id) { success in
                                DispatchQueue.main.async {
                                    if success {
                                        self.header.data.removeAll(where: {$0.id == data.id})
                                        self.header.refresh(with: self.header.data)
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

                    if let user = self.data?.user {
                        if user.isMe {
                            return UIMenu(children: [
                                hideAction
                            ])
                        } else {
                            if data.reactions.filter({$0.user.isMe}).isEmpty {
                                return UIMenu(children: [
                                    reactToEvent
                                ])
                            } else {
                                reactToEvent.title = "Change reaction".localized()
                                return UIMenu(children: [
                                    reactToEvent,
                                    removeReaction
                                ])
                            }
                        }
                    } else {
                        return nil
                    }
                }
            }

            func didSelectEmoji(emoji: String) {

                guard let sharingVC = self.viewController as? SharingVC else { return }

                if let event = self.data {
                    SharingManager.shared.reactToEvent(event: event, reaction: emoji) { newReaction in
                        DispatchQueue.main.async {
                            if let reaction = newReaction {
                                event.reactions.removeAll(where: {$0.user.isMe})
                                event.reactions.insert(reaction, at: 0)
                                self.refresh(with: event)
                            } else {
                                SharingManager.shared.displayError(error: .unknown, on: sharingVC)
                            }
                        }
                    }
                } else {
                    SharingManager.shared.displayError(error: .unknown, on: sharingVC)
                }
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

    private class PersonCell: UITableViewCell, UIContextMenuInteractionDelegate {

        //Data
        private var data: SharingManager.PersonData?
        public var row: Int = 0

        //UI
        private let backView = UIView()
        private let iconView = UILabel()

        private let nameLabel = UILabel()
        private let scoreLabel = UILabel()

        private let button = UIButton()

        override func layoutSubviews() {
            super.layoutSubviews()

            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24
            backView.setDefaultShadow()

            iconView.frame = CGRect(x: 15, y: (backView.frame.height - 50) / 2, width: 50, height: 50)
            iconView.layer.cornerRadius = 25

            let x = iconView.frame.maxX
            nameLabel.frame = CGRect(x: x + 15, y: (backView.frame.height / 2) - 25, width: backView.frame.width - x - 45, height: 25)
            scoreLabel.frame = CGRect(x: x + 15, y: nameLabel.frame.maxY, width: backView.frame.width - x - 45, height: 25)

            button.frame = backView.bounds

        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            self.contentView.isHidden = true
            self.backgroundColor = .clear

            backView.layer.cornerCurve = .continuous
            backView.backgroundColor = .groupedSecondaryBackground
            self.addSubview(backView)

            iconView.backgroundColor = .groupedBackground
            iconView.font = .roundedFont(ofSize: 24, weight: .bold)
            iconView.textColor = .title
            iconView.textAlignment = .center
            iconView.clipsToBounds = true
            backView.addSubview(iconView)

            nameLabel.textAlignment = .left
            nameLabel.textColor = .title
            nameLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            backView.addSubview(nameLabel)

            scoreLabel.textAlignment = .left
            backView.addSubview(scoreLabel)

            button.addAction(UIAction(handler: { _ in
                if let data = self.data {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    let vc = FriendVC(data)
                    if let sharingVC = self.viewController as? SharingVC {
                        sharingVC.selectedIndex = IndexPath(row: self.row, section: 0)

                        if #available(iOS 18.0, *) {
                            vc.preferredTransition = .zoom(sourceViewProvider: { context in
                                if let index = sharingVC.selectedIndex, let cell = sharingVC.tableView.cellForRow(at: index) as? PersonCell {
                                    return cell
                                } else {
                                    return nil
                                }
                            })
                        }

                    }
                    self.viewController?.navigationController?.pushViewController(vc, animated: true)
                }
            }), for: .touchUpInside)
            backView.addSubview(button)

            let interaction = UIContextMenuInteraction(delegate: self)
            backView.addInteraction(interaction)

        }

        public func refresh(with: SharingManager.PersonData) {
            self.data = with

            if let initial = data?.name.first, !with.isMe {
                self.iconView.text = String(initial)
            } else {
                self.iconView.text = "🍊"
            }

            self.nameLabel.text = with.isMe ? "Me".localized() : data?.name

            let firstPart = "Sleep".localized()
            var secondPart = ""
            if let score = with.sleepScore {
                secondPart = "\(Int((score) * 100))/100"
            } else {
                secondPart = "--"
            }

            let attributedText = NSMutableAttributedString(
                string: firstPart + " ",
                attributes: [
                    .font: UIFont.roundedFont(ofSize: 17, weight: .regular),
                    .foregroundColor: UIColor.secondaryText
                ]
            )

            attributedText.append(NSAttributedString(
                string: secondPart,
                attributes: [
                    .font: UIFont.roundedFont(ofSize: 17, weight: .semibold),
                    .foregroundColor: UIColor.customPurple
                ]
            ))

            self.scoreLabel.attributedText = attributedText

        }

        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            guard let data = data else { return nil }

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in

                let copyUsernameAction = UIAction(title: "Copy username".localized()) { _ in
                    UIPasteboard.general.string = data.username
                }

                let removeAction = UIAction(title: "Remove friend".localized(), attributes: .destructive) { _ in
                    let alert = UIAlertController(title: "Remove friend?".localized(), message: "Are you sure you want to remove this friend, you cann't undo this.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive, handler: { _ in
                        SharingManager.shared.removeFriend(username: data.username) { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    SharingManager.shared.displayError(error: error, on: self.viewController!)
                                } else {
                                    if let vc = self.viewController as? SharingVC {
                                        vc.data.removeAll(where: {$0.username == data.username})
                                        vc.tableView.reloadData()
                                    }
                                }
                            }
                        }
                    }))

                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

                    alert.view.tintColor = .customBlue

                    self.viewController?.present(alert, animated: true)
                }

                let messageAction = UIAction(title: "Send a message".localized()) { _ in
                    guard let data = self.data, let viewController = self.viewController else { return }

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

                        SharingManager.shared.sendPoke(to: data, message: message) { success in
                            DispatchQueue.main.async {
                                if success {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                } else {
                                    SharingManager.shared.displayError(error: .unknown, on: viewController)
                                }
                            }
                        }
                    }))
                    alert.view.tintColor = .customBlue
                    viewController.present(alert, animated: true)
                }

                var actions: [UIMenuElement] = [copyUsernameAction]
                if !data.isMe {
                    actions.append(contentsOf: [messageAction, removeAction])
                }

                return UIMenu(children: actions)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}


fileprivate extension TimeInterval {
    var howMuchTimeAgoDescription: String {
        if abs(self) < 60 {
            return "Now".localized()
        } else if abs(self) < 3600 {
            let minutes = Int(self / 60)
            return "\(minutes)\("min ago".localized())"
        } else  if abs(self) < 3600 * 24 {
            let hours = Int(self / 3600)
            return "\(hours)\("h ago".localized())"
        } else {
            let days = Int(self / (3600 * 24))
            return "\(days)\("d ago".localized())"
        }
    }
}
