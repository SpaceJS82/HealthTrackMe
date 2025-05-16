//
//  FriendRequestsVC.swift
//  Citrus
//
//  Created by Luka Verč on 15. 5. 25.
//

import UIKit

class FriendRequestsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //Data
    private var data: [SharingManager.FriendRequest] = []
    
    //UI
    private let refreshControl = UIRefreshControl()
    private let tableView = UITableView()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        tableView.contentInset.top = 30
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .groupedBackground

        self.navigationItem.titleView = {
            let label = UILabel()
            label.text = "Friend Requests".localized()
            label.textColor = .title
            label.font = .roundedFont(ofSize: 17, weight: .semibold)
            label.sizeToFit()
            return label
        }()
        
        self.navigationItem.leftBarButtonItem = self.getNavigationItem(image: "chevron.backward", target: self, action: #selector(onBack), backgroundColor: .groupedSecondaryBackground)
        
        self.navigationItem.rightBarButtonItem = self.getNavigationItem(image: "plus", target: self, action: #selector(onAdd), backgroundColor: .groupedSecondaryBackground)
        
        
        tableView.register(FriendRequestCell.self, forCellReuseIdentifier: "cell")
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
    private func onRefreshControl() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.refresh()
    }
    
    @objc
    private func refresh() {
        SharingManager.shared.getFriendRequests { requests, error in
            DispatchQueue.main.async {
                if let error = error {
                    SharingManager.shared.displayError(error: error, on: self) {
                        self.refresh()
                    }
                } else {
                    self.data = requests
                    self.tableView.reloadData()
                }
                
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc
    private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func onAdd() {
        let alert = UIAlertController(title: "Add Friend".localized(), message: "By username", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Friend's username".localized()
            textField.becomeFirstResponder()
        }

        alert.addAction(UIAlertAction(title: "Send request".localized(), style: .default, handler: { _ in
            if let username = alert.textFields?.first?.text {
                SharingManager.shared.sendFriendRequest(to: username) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            SharingManager.shared.displayError(error: error, on: self)
                        } else {
                            self.refresh()
                        }
                    }
                }
            } else {
                SharingManager.shared.displayError(error: .unknown, on: self)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

        alert.view.tintColor = .customBlue

        self.present(alert, animated: true)
    }


    //TableView delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendRequestCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FriendRequestCell {
            cell.refresh(with: self.data[indexPath.row])
        }
    }


    //Cell
    private class FriendRequestCell: UITableViewCell {

        //Data
        private var data: SharingManager.FriendRequest?

        //UI
        private let backView = UIView()
        private let nameLabel = UILabel()
        private let usernameLabel = UILabel()

        private let declineButton = UIButton()
        private let approveButton = UIButton()

        override func layoutSubviews() {
            super.layoutSubviews()

            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24

            nameLabel.frame = CGRect(x: 15, y: (backView.frame.height / 2) - 20, width: 200, height: 20)
            usernameLabel.frame = CGRect(x: 15, y: nameLabel.frame.maxY, width: 200, height: 18)

            approveButton.frame = CGRect(x: backView.frame.width - 60, y: (backView.frame.height - 45) / 2, width: 45, height: 45)
            approveButton.layer.cornerRadius = 45 / 2
            
            declineButton.frame = CGRect(x: approveButton.frame.minX - 55, y: (backView.frame.height - 45) / 2, width: 45, height: 45)
            declineButton.layer.cornerRadius = 45 / 2
            
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.contentView.isHidden = true
            self.backgroundColor = .clear
            
            backView.backgroundColor = .groupedSecondaryBackground
            backView.layer.cornerCurve = .continuous
            self.addSubview(backView)
            
            nameLabel.textAlignment = .left
            nameLabel.textColor = .title
            nameLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            backView.addSubview(nameLabel)
            
            usernameLabel.textAlignment = .left
            usernameLabel.textColor = .secondaryText
            usernameLabel.font = .roundedFont(ofSize: 14, weight: .regular)
            backView.addSubview(usernameLabel)
            
            declineButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(font: .roundedFont(ofSize: 17, weight: .semibold))), for: .normal)
            declineButton.backgroundColor = .groupedBackground
            declineButton.tintColor = .title
            declineButton.addAction(UIAction(handler: { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.decline()
            }), for: .touchUpInside)
            backView.addSubview(declineButton)
            
            approveButton.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(font: .roundedFont(ofSize: 17, weight: .semibold))), for: .normal)
            approveButton.backgroundColor = .customBlue
            approveButton.tintColor = .white
            approveButton.addAction(UIAction(handler: { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.approve()
            }), for: .touchUpInside)
            backView.addSubview(approveButton)
            
        }
        
        public func refresh(with: SharingManager.FriendRequest) {
            self.data = with
            
            self.nameLabel.text = data?.sender.name
            self.usernameLabel.text = "@" + (data?.sender.username ?? "")
        }
        
        @objc
        private func approve() {
            guard let data = self.data else { return }
            guard let viewController = self.viewController as? FriendRequestsVC else { return }
            
            SharingManager.shared.answerFriendRequest(to: data.sender.username, approve: true) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        SharingManager.shared.displayError(error: error, on: viewController)
                    } else {
                        viewController.data.removeAll(where: {$0.sender.username == data.sender.username})
                        viewController.tableView.reloadData()
                    }
                }
            }
        }
        
        @objc
        private func decline() {
            let alert = UIAlertController(title: "Decline request?".localized(), message: "Are you sure you want to decline this friend request, you cann't undo this.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Decline".localized(), style: .destructive, handler: { _ in
                
                guard let data = self.data else { return }
                guard let viewController = self.viewController as? FriendRequestsVC else { return }
                
                SharingManager.shared.answerFriendRequest(to: data.sender.username, approve: false) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            SharingManager.shared.displayError(error: error, on: viewController)
                        } else {
                            viewController.data.removeAll(where: {$0.sender.username == data.sender.username})
                            viewController.tableView.reloadData()
                        }
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
            
            alert.view.tintColor = .customBlue
            
            self.viewController?.present(alert, animated: true)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

}
