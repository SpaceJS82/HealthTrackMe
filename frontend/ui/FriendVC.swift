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
    private var data: SharingManager.PersonData!
    private var workouts: [HKWorkout] = []
    
    //UI
    private let navigationTitleLabel = NavigationLabel()
    
    private let headerView = FriendHeader()
    
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    convenience init(_ friend: SharingManager.PersonData) {
        self.init()
        self.data = friend
        
        self.navigationTitleLabel.text = data?.name
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
        
        self.navigationItem.leftBarButtonItem = self.getNavigationItem(image: "chevron.left", target: self, action: #selector(onBack), backgroundColor: .secondaryBackground)
        
        
        //Background
        view.backgroundColor = .background
        
        
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
        self.headerView.refresh(with: self.data)
    }
    
    
    @objc
    private func onBack() {
        self.navigationController?.popViewController(animated: true)
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
        return self.workouts.count
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
            cell.refresh(with: self.workouts[indexPath.row])
        }
    }
    
    
    private class FriendHeader: UIView {
        
        //Data
        private var data: SharingManager.PersonData?
        
        //UI
        private let iconView = UILabel()
        private let nameView = UILabel()
        
        private let lastNightTitle = UILabel()
        private let ringBackView = UIView()
        private let ringView = PercentageRingView()
        private let ringIconView = UIImageView()
        private let characterBackView = UIView()
        private let characterView = CharacterView(frame: .zero)
        
        private let thisWeekLabel = UILabel()
        private let thisWeekTable = MyHStack()
        
        private let workoutsLabel = UILabel()
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            iconView.frame = CGRect(x: (self.frame.width - 75) / 2, y: 0, width: 75, height: 75)
            iconView.layer.cornerRadius = 75 / 2
            nameView.frame = CGRect(x: 15, y: iconView.frame.maxY + 10, width: self.frame.width - 30, height: 25)
            
            lastNightTitle.frame = CGRect(x: 15, y: nameView.frame.maxY + 30, width: self.frame.width - 30, height: 20)
            
            ringBackView.frame = CGRect(x: 15, y: lastNightTitle.frame.maxY + 10, width: (self.frame.width - 40) / 2, height: 100)
            ringBackView.layer.cornerRadius = 24
            ringView.frame = CGRect(x: (ringBackView.frame.width - 75) / 2, y: (ringBackView.frame.height - 75) / 2, width: 75, height: 75)
            ringIconView.frame = CGRect(x: (ringView.frame.width - 30) / 2, y: (ringView.frame.height - 30) / 2, width: 30, height: 30)
            
            characterBackView.frame = CGRect(x: ringBackView.frame.maxX + 10, y: lastNightTitle.frame.maxY + 10, width: (self.frame.width - 40) / 2, height: 100)
            ringBackView.layer.cornerRadius = 24
            characterView.frame = CGRect(x: (ringBackView.frame.width - 85) / 2, y: (ringBackView.frame.height - 85) / 2, width: 85, height: 85)
            
            thisWeekLabel.frame = CGRect(x: 15, y: characterBackView.frame.maxY + 30, width: self.frame.width - 30, height: 20)
            thisWeekTable.frame = CGRect(x: 15, y: thisWeekLabel.frame.maxY + 10, width: self.frame.width - 30, height: 100)
            thisWeekTable.layer.cornerRadius = 24
            
            workoutsLabel.frame = CGRect(x: 15, y: self.frame.height - 50, width: self.frame.width - 30, height: 40)
            
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            iconView.backgroundColor = .secondaryBackground
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
            
            ringBackView.backgroundColor = .secondaryBackground
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
            
            characterBackView.backgroundColor = .secondaryBackground
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
            
            thisWeekTable.layer.cornerCurve = .continuous
            thisWeekTable.backgroundColor = .secondaryBackground
            self.addSubview(thisWeekTable)
            
            
            workoutsLabel.text = "Activities".localized()
            workoutsLabel.textAlignment = .left
            workoutsLabel.textColor = .title
            workoutsLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            self.addSubview(workoutsLabel)
            
        }
        
        public func refresh(with: SharingManager.PersonData) {
            self.data = with
            
            if let initial = with.name.first {
                self.iconView.text = String(initial)
            }
            
            self.nameView.text = with.name
            
            self.ringView.percent = with.sleepScore * 100
            self.characterView.setAnimation(with.sleepScore.getBasicYoaForSleepScore())
            
            self.thisWeekTable.setViews([
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.6),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.7),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.35),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.44),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.88),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.90),
                SharingManager.PersonData.SleepScoreDate(date: .now, score: 0.72),
            ].enumerated().map({ index, data in
                return WeekDataCell(data)
                    .size(CGSize(width: (self.thisWeekTable.frame.width - 90) / 7))
                    .padding(UIEdgeInsets(left: index == 0 ? 15 : 0, right: index == 6 ? 15 : 10))
            }))
            
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
    
    
    private class ActivityCell: UITableViewCell {
        
        //Data
        private var activity: HKWorkout?
        
        
        //UI
        private let backView = UIView()
        
        private let iconView = UIImageView()
        private let titleView = UILabel()
        private let descriptionView = UILabel()
        
        override func layoutSubviews() {
            
            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24
            
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
            
        }
        
        func refresh(with: HKWorkout) {
            
            self.activity = with
            
            backView.backgroundColor = .groupedSecondaryBackground
            iconView.tintColor = .title
            titleView.textColor = .title
            descriptionView.textColor = .secondaryText
            
            self.titleView.text = with.getWorkoutTitle()
            var importantMetric = with.duration.toHoursMinutesString()
            if let distance = with.totalDistance {
                if UserData.shared.isUsingMetricSystem {
                    importantMetric = "\((distance.doubleValue(for: .meter()) / 1000).rounded(toPlaces: 1))km"
                } else {
                    importantMetric = "\((distance.doubleValue(for: .mile())).rounded(toPlaces: 1))mi"
                }
            }
            self.descriptionView.text = "\(with.endDate.toOrdinalDateString()) - \(importantMetric)"
            
            self.iconView.image = with.getWorkoutSymbolImage()?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 24, weight: .semibold)))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}
