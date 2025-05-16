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
    private var data: [SharingManager.PersonData] = []

    //UI
    private let navigationTitleLabel = NavigationLabel()

    private let headerView = SharingHeader()

    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.isFirstRefresh {
            self.refresh()
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.setGradient(color1: UIColor.secondaryText.withAlphaComponent(0.15), color2: .groupedBackground.withAlphaComponent(0.15))

        tableView.frame = view.bounds

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

        self.navigationItem.rightBarButtonItems = [
            self.getNavigationItem(image: "person.2.badge.gearshape.fill", target: self, action: #selector(onFriendsRequest), backgroundColor: .groupedSecondaryBackground)
        ]


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

        self.refresh()
    }

    @objc
    private func onFriendsRequest() {
        self.navigationController?.pushViewController(FriendRequestsVC(), animated: true)
    }

    @objc
    private func onRefreshControl() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.refresh()
    }

    @objc
    private func refresh() {

        guard !self.isRefreshing else { return }
        self.isRefreshing = true

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        SharingManager.shared.getEventData { data, error in
            DispatchQueue.main.async {
                if let error = error {
                    SharingManager.shared.displayError(error: error, on: self) {
                        self.refresh()
                    }
                } else {
                    self.headerView.refresh(with: data)
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
                    self.data = data
                    self.tableView.reloadData()
                }
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.refreshControl.endRefreshing()
            self.isRefreshing = false
            self.isFirstRefresh = false
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
        
        private let frendsTitle = UILabel()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            titleView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: 40)
            
            highlightsLabel.frame = CGRect(x: 15, y: titleView.frame.maxY + 30, width: self.frame.width - 30, height: 40)
            eventsStack.frame = CGRect(x: 0, y: highlightsLabel.frame.maxY + 2, width: self.frame.width, height: 288)
            
            frendsTitle.frame = CGRect(x: 15, y: eventsStack.frame.maxY + 30, width: self.frame.width - 30, height: 40)
            
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
            
            frendsTitle.text = "Friends".localized()
            frendsTitle.font = UIFont.roundedFont(ofSize: 17, weight: .semibold)
            frendsTitle.textColor = .title
            frendsTitle.textAlignment = .left
            self.addSubview(frendsTitle)
            
        }
        
        public func refresh(with: [SharingManager.EventData]) {
            self.data = with
            self.eventsStack.setViews(self.data.enumerated().map({ index, data in
                return EventCell(data: data)
                    .size(CGSize(width: 283))
                    .padding(UIEdgeInsets(left: (index == 0) ? 15 : 0,
                                          right: (index == self.data.count - 1) ? 15 : 2))
            }))
        }
        
        private class EventCell: MyStack.StackView {
            
            //Data
            private var data: SharingManager.EventData?
            
            //UI
            private let backView = UIView()
            
            private let messageView = UILabel()
            private let timeLabel = UILabel()
            
            private let imageBackground = UIView()
            private let imageView = UIImageView()
            
            private let titleView = UILabel()
            private let subTitleView = UILabel()
            
            convenience init(data: SharingManager.EventData) {
                self.init()
                self.data = data
                
                self.timeLabel.text = Date.now.timeIntervalSince(data.date).howMuchTimeAgoDescription
                
                if data.type == .workout {
                    self.messageView.text = "_NAME_ finished a workout".localized().replacingOccurrences(of: "_NAME_", with: data.user?.name ?? "Unknown")
                    
                    if let iconName = data.metaData?["icon"] as? String {
                        self.imageView.image = UIImage(systemName: iconName)
                    }
                    
                    if let metric = data.metaData?["metric"] as? String {
                        self.titleView.text = metric
                    }
                    
                    if let workoutType = data.metaData?["workoutType"] as? Int, let isIndoor = data.metaData?["isIndoor"] as? Bool {
                        let activityType = HKWorkoutActivityType(rawValue: UInt(workoutType)) ?? .barre
                        
                        let workout = HKWorkout(activityType: activityType,
                                                start: .now,
                                                end: .now,
                                                duration: 0,
                                                totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 0),
                                                totalDistance: HKQuantity(unit: .mile(), doubleValue: 0),
                                                metadata: [
                                                    HKMetadataKeyIndoorWorkout : isIndoor.hashValue
                                                ])
                        
                        self.subTitleView.text = workout.getWorkoutTitle()
                    }
                }
                
            }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                
                backView.frame = CGRect(x: 0, y: 8, width: self.frame.width - 8, height: self.frame.height - 8)
                backView.layer.cornerRadius = 24
                
                messageView.frame = CGRect(x: 30, y: 30, width: backView.frame.width - 60, height: 25)
                timeLabel.frame = CGRect(x: 30, y: messageView.frame.maxY, width: backView.frame.width - 60, height: 15)
                
                imageBackground.frame = CGRect(x: (backView.frame.width - 110) / 2, y: timeLabel.frame.maxY + 10, width: 110, height: 110)
                imageBackground.layer.cornerRadius = 110 / 2
                
                imageView.frame = CGRect(x: (imageBackground.frame.width - 70) / 2, y: (imageBackground.frame.height - 70) / 2, width: 70, height: 70)
                
                titleView.frame = CGRect(x: 30, y: imageBackground.frame.maxY + 20, width: backView.frame.width - 60, height: 25)
                subTitleView.frame = CGRect(x: 30, y: titleView.frame.maxY, width: backView.frame.width - 60, height: 25)
                
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
                self.addSubview(messageView)
                
                timeLabel.textAlignment = .left
                timeLabel.textColor = .secondaryText
                timeLabel.adjustsFontSizeToFitWidth = true
                timeLabel.font = .roundedFont(ofSize: 10, weight: .regular)
                self.addSubview(timeLabel)
                
                imageBackground.backgroundColor = .groupedBackground
                self.addSubview(imageBackground)
                
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = .customGreen
                imageBackground.addSubview(imageView)
                
                titleView.textAlignment = .center
                titleView.textColor = .customGreen
                titleView.adjustsFontSizeToFitWidth = true
                titleView.font = .roundedFont(ofSize: 20, weight: .semibold)
                self.addSubview(titleView)
                
                subTitleView.textAlignment = .center
                subTitleView.textColor = .title
                subTitleView.adjustsFontSizeToFitWidth = true
                subTitleView.font = .roundedFont(ofSize: 17, weight: .semibold)
                self.addSubview(subTitleView)
                
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private class PersonCell: UITableViewCell {
        
        //Data
        private var data: SharingManager.PersonData?
        
        //UI
        private let backView = UIView()
        private let iconView = UILabel()
        
        private let nameLabel = UILabel()
        private let scoreLabel = UILabel()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24
            
            iconView.frame = CGRect(x: 15, y: (backView.frame.height - 50) / 2, width: 50, height: 50)
            iconView.layer.cornerRadius = 25
            
            let x = iconView.frame.maxX
            nameLabel.frame = CGRect(x: x + 15, y: (backView.frame.height / 2) - 25, width: backView.frame.width - x - 45, height: 25)
            scoreLabel.frame = CGRect(x: x + 15, y: nameLabel.frame.maxY, width: backView.frame.width - x - 45, height: 25)
            
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
            
        }
        
        public func refresh(with: SharingManager.PersonData) {
            self.data = with
            
            if let initial = data?.name.first {
                self.iconView.text = String(initial)
            }
            
            self.nameLabel.text = data?.name
            
            let firstPart = "Sleep".localized()
            let secondPart = "\(Int((data?.sleepScore ?? 0) * 100))/100"

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
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}


extension TimeInterval {
    var howMuchTimeAgoDescription: String {
        if self < 60 {
            return "Now".localized()
        } else if self < 3600 {
            let minutes = Int(self / 60)
            return "\(minutes) min"
        } else {
            let hours = Int(self / 3600)
            return "\(hours) h"
        }
    }
}
