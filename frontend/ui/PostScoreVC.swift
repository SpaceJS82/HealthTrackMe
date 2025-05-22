//
//  PostSleepScoreVC.swift
//  Citrus
//
//  Created by Luka Verč on 22. 5. 25.
//

import UIKit

class PostScoreVC: UIViewController {
    
    // MARK: - Data
    private var score: Double!
    private var customTitle: String = ""
    private var message: String = ""
    private var postButtonText: String = ""
    private var animationFolder: String = ""
    private var scoreColor: UIColor = .title
    
    public var onPost: ((PostScoreVC) -> Void)?
    
    // MARK: - UI
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let characterView = CharacterView(frame: .zero)
    private let scoreLabel = UILabel()
    private let explanationLabel = UILabel()
    
    private let postButton = UIButton()
    private let skipButton = UIButton()
    
    // MARK: - Init
    convenience init(score: Double,
                     scoreColor: UIColor,
                     title: String,
                     message: String,
                     postButtonTitle: String = "Share".localized(),
                     animation: String) {
        self.init()
        self.score = score
        self.scoreColor = scoreColor
        self.customTitle = title
        self.message = message
        self.postButtonText = postButtonTitle
        self.animationFolder = animation
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let sheet = self.sheetPresentationController, #available(iOS 16.0, *) {
            sheet.animateChanges {
                sheet.detents = [
                    .custom { _ in self.estimatedHeight() }
                ]
                sheet.prefersGrabberVisible = false
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contentView.frame = view.bounds
        let maxWidth = contentView.frame.width - 30
        
        titleLabel.frame = CGRect(x: 15, y: 20, width: maxWidth, height: 1000)
        titleLabel.sizeToFit()
        titleLabel.center.x = view.center.x
        
        characterView.frame = CGRect(x: (view.frame.width - 180) / 2, y: titleLabel.frame.maxY + 10, width: 180, height: 180)
        
        scoreLabel.frame = CGRect(x: 15, y: characterView.frame.maxY + 5, width: maxWidth, height: 30)
        
        explanationLabel.frame = CGRect(x: 15, y: scoreLabel.frame.maxY + 10, width: maxWidth, height: 1000)
        explanationLabel.sizeToFit()
        
        postButton.frame = CGRect(x: 15, y: explanationLabel.frame.maxY + 20, width: maxWidth, height: 50)
        skipButton.frame = CGRect(x: 15, y: postButton.frame.maxY + 10, width: maxWidth, height: 50)
    }

    // MARK: - Dynamic Height
    private func estimatedHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let textHeight = message.height(withConstrainedWidth: screenWidth - 30, font: explanationLabel.font)
        let titleHeight = customTitle.height(withConstrainedWidth: screenWidth - 30, font: titleLabel.font)
        return 20 + titleHeight + 10 + 180 + 5 + 30 + 10 + textHeight + 20 + 50 + 10 + 50 + 30
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(contentView)
        
        titleLabel.text = customTitle
        titleLabel.textColor = .title
        titleLabel.font = .roundedFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        characterView.contentMode = .scaleAspectFit
        characterView.setAnimation(animationFolder)
        contentView.addSubview(characterView)
        
        scoreLabel.text = "\(Int(score * 100))/100"
        scoreLabel.textColor = scoreColor
        scoreLabel.font = .roundedFont(ofSize: 20, weight: .semibold)
        scoreLabel.textAlignment = .center
        contentView.addSubview(scoreLabel)
        
        explanationLabel.text = message
        explanationLabel.textColor = .secondaryText
        explanationLabel.font = .roundedFont(ofSize: 17, weight: .regular)
        explanationLabel.textAlignment = .center
        explanationLabel.numberOfLines = 0
        contentView.addSubview(explanationLabel)
        
        postButton.setTitle(postButtonText, for: .normal)
        postButton.backgroundColor = .customBlue
        postButton.setTitleColor(.white, for: .normal)
        postButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        postButton.layer.cornerRadius = 20
        postButton.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.onPost?(self)
            self.dismiss(animated: true)
        }), for: .touchUpInside)
        contentView.addSubview(postButton)
        
        skipButton.setTitle("Skip".localized(), for: .normal)
        skipButton.backgroundColor = .secondaryBackground
        skipButton.setTitleColor(.title, for: .normal)
        skipButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        skipButton.layer.cornerRadius = 20
        skipButton.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.dismiss(animated: true)
        }), for: .touchUpInside)
        contentView.addSubview(skipButton)
    }
}


// MARK: - Helpers

fileprivate extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}
