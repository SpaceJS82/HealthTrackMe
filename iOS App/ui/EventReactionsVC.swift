//
//  EventReactionsVC.swift
//  Citrus
//
//  Created by Luka Verč on 21. 5. 25.
//

import UIKit

class EventReactionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, EmojiSelectorVCDelegate {
    
    private var event: SharingManager.EventData!
    private var isRefreshing: Bool = false
    public var sharingVC: SharingVC!

    private let tableView = UITableView()
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No reactions yet".localized()
        label.textColor = .secondaryText
        label.font = .roundedFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    convenience init(event: SharingManager.EventData) {
        self.init()
        self.event = event
        
        if !(event.user?.isMe ?? false) {
            self.navigationItem.rightBarButtonItem = self.getNavigationItem(image: "plus", target: self, action: #selector(onAddReaction), backgroundColor: .groupedSecondaryBackground)
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true

        view.backgroundColor = .groupedBackground

        self.navigationItem.titleView = {
            let label = UILabel()
            label.text = "Reactions".localized()
            label.textColor = .title
            label.font = .roundedFont(ofSize: 17, weight: .semibold)
            label.sizeToFit()
            return label
        }()

        self.navigationItem.leftBarButtonItem = self.getNavigationItem(image: "xmark", target: self, action: #selector(onBack), backgroundColor: .groupedSecondaryBackground)

        tableView.register(ReactionCell.self, forCellReuseIdentifier: "ReactionCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorEffect = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        view.addSubview(tableView)

        tableView.addSubview(emptyStateLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        tableView.contentInset.top = 30
        emptyStateLabel.frame = tableView.bounds
    }

    @objc private func onBack() {
        self.sharingVC.refresh()
        self.dismiss(animated: true)
    }
    
    @objc
    private func onAddReaction() {
        let emojiPicker = EmojiSelectorVC()
        emojiPicker.delegate = self
        self.present(ThemeNavigationViewController(rootViewController: emojiPicker), animated: true)
    }
    
    func didSelectEmoji(emoji: String) {
        SharingManager.shared.reactToEvent(event: self.event, reaction: emoji) { newReaction in
            DispatchQueue.main.async {
                if let reaction = newReaction {
                    self.event.reactions.removeAll(where: {$0.user.isMe})
                    self.event.reactions.append(reaction)
                    self.tableView.reloadData()
                } else {
                    SharingManager.shared.displayError(error: .unknown, on: self)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.emptyStateLabel.isHidden = !self.event.reactions.isEmpty
        return self.event.reactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReactionCell", for: indexPath) as! ReactionCell
        cell.refresh(with: self.event.reactions.sorted(by: { $0.user.name > $1.user.name })[indexPath.row])
        cell.page = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    private class ReactionCell: UITableViewCell {
        private var data: SharingManager.EventReaction?
        public var page: EventReactionsVC!

        private let backView = UIView()
        private let reactionLabel = UILabel()
        private let nameLabel = UILabel()
        private let deleteButton = UIButton()

        override func layoutSubviews() {
            super.layoutSubviews()

            backView.frame = CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height - 10)
            backView.layer.cornerRadius = 24

            reactionLabel.frame = CGRect(x: 15, y: (backView.frame.height - 24)/2, width: 30, height: 24)
            nameLabel.frame = CGRect(x: 60, y: (backView.frame.height - 24)/2, width: backView.frame.width - 120, height: 24)
            deleteButton.frame = CGRect(x: backView.frame.width - 45, y: (backView.frame.height - 30)/2, width: 30, height: 30)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.contentView.isHidden = true
            self.backgroundColor = .clear

            backView.backgroundColor = .groupedSecondaryBackground
            backView.layer.cornerCurve = .continuous
            self.addSubview(backView)

            reactionLabel.font = .roundedFont(ofSize: 20, weight: .bold)
            reactionLabel.textColor = .title
            backView.addSubview(reactionLabel)

            nameLabel.font = .roundedFont(ofSize: 17, weight: .semibold)
            nameLabel.textColor = .title
            backView.addSubview(nameLabel)

            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.tintColor = .customRed
            deleteButton.addAction(UIAction(handler: { _ in
                if let data = self.data {
                    SharingManager.shared.deleteReaction(id: data.id) { success in
                        DispatchQueue.main.async {
                            if success {
                                self.page.event.reactions.removeAll(where: {$0.id == data.id})
                                self.page.tableView.reloadData()
                            } else {
                                SharingManager.shared.displayError(error: .unknown, on: self.page)
                            }
                        }
                    }
                }
            }), for: .touchUpInside)
            backView.addSubview(deleteButton)
        }

        public func refresh(with reaction: SharingManager.EventReaction) {
            self.data = reaction
            self.reactionLabel.text = reaction.content
            self.nameLabel.text = reaction.user.name
            self.deleteButton.isHidden = !reaction.user.isMe
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


