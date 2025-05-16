//
//  RegisterVC.swift
//  Citrus
//
//  Created by Luka Verč on 16. 5. 25.
//

import UIKit

class RegisterVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - Data
    private var sharingVC: SharingVC!
    
    convenience init(for vc: SharingVC) {
        self.init()
        self.sharingVC = vc
    }

    // MARK: - UI
    private let titleLabel = UILabel()
    
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    
    private let usernameContainer = UIView()
    private let passwordContainer = UIView()
    
    private let registerButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.getNavigationItem(image: "chevron.left", target: self, action: #selector(onBack), backgroundColor: .secondaryBackground)

        view.backgroundColor = .background
        setupUI()
    }
    
    private func setupUI() {
        // Title
        titleLabel.text = "Create an account".localized()
        titleLabel.font = UIFont.roundedFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .title
        view.addSubview(titleLabel)
        
        // Username
        usernameField.placeholder = "Username".localized()
        usernameField.autocapitalizationType = .none
        usernameField.font = .roundedFont(ofSize: 17, weight: .regular)
        usernameField.textColor = .title
        usernameField.delegate = self
        usernameField.returnKeyType = .next
        
        usernameContainer.backgroundColor = .secondaryBackground
        usernameContainer.layer.cornerRadius = 20
        usernameContainer.layer.masksToBounds = true
        usernameContainer.addSubview(usernameField)
        view.addSubview(usernameContainer)
        
        // Password
        passwordField.placeholder = "Password".localized()
        passwordField.isSecureTextEntry = true
        passwordField.font = .roundedFont(ofSize: 17, weight: .regular)
        passwordField.textColor = .title
        passwordField.delegate = self
        passwordField.returnKeyType = .done

        passwordContainer.backgroundColor = .secondaryBackground
        passwordContainer.layer.cornerRadius = 20
        passwordContainer.layer.masksToBounds = true
        passwordContainer.addSubview(passwordField)
        view.addSubview(passwordContainer)
        
        // Register Button
        registerButton.setTitle("Create Account".localized(), for: .normal)
        registerButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        registerButton.backgroundColor = .customBlue
        registerButton.tintColor = .white
        registerButton.layer.cornerRadius = 20
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        view.addSubview(registerButton)
        
        // Already have account
        loginButton.setTitle("🔐 I already have an account".localized(), for: .normal)
        loginButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        loginButton.backgroundColor = .secondaryBackground
        loginButton.tintColor = .title
        loginButton.layer.cornerRadius = 20
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        view.addSubview(loginButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let padding: CGFloat = 15
        let fieldHeight: CGFloat = 50

        titleLabel.frame = CGRect(x: padding, y: 120, width: view.frame.width - 2 * padding, height: 40)

        usernameContainer.frame = CGRect(x: padding, y: titleLabel.frame.maxY + 40, width: view.frame.width - 2 * padding, height: fieldHeight)
        usernameField.frame = CGRect(x: 15, y: 0, width: usernameContainer.frame.width - 30, height: fieldHeight)

        passwordContainer.frame = CGRect(x: padding, y: usernameContainer.frame.maxY + 10, width: view.frame.width - 2 * padding, height: fieldHeight)
        passwordField.frame = CGRect(x: 15, y: 0, width: passwordContainer.frame.width - 30, height: fieldHeight)

        registerButton.frame = CGRect(x: padding, y: passwordContainer.frame.maxY + 30, width: view.frame.width - 2 * padding, height: fieldHeight)
        loginButton.frame = CGRect(x: padding, y: registerButton.frame.maxY + 10, width: view.frame.width - 2 * padding, height: fieldHeight)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    // MARK: - Actions
    
    @objc private func registerTapped() {
        view.endEditing(true)
        
        let username = self.usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = self.passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !username.isEmpty, !password.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Information".localized(),
                message: "Please enter both username and password.".localized(),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Done", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        AuthManager.shared.register(username: username, password: password, name: UserData.shared.fullName) { success in
            DispatchQueue.main.async {
                self.onBack()
            }
        }
    }
    
    @objc private func loginTapped() {
        self.onBack()
    }
    
    @objc private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
}
