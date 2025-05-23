//
//  LoginVC.swift
//  Citrus
//
//  Created by Luka Verč on 16. 5. 25.
//

import UIKit

class LoginVC: UIViewController, UITextFieldDelegate {
    
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
    
    private let loginButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.getNavigationItem(image: "chevron.left", target: self, action: #selector(onBack), backgroundColor: .secondaryBackground)

        view.backgroundColor = .background
        setupUI()
    }

    private func setupUI() {
        // Title
        titleLabel.text = "Join your friends".localized()
        titleLabel.font = UIFont.roundedFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .title
        view.addSubview(titleLabel)

        // Username
        usernameField.placeholder = "Email".localized()
        usernameField.keyboardType = .emailAddress
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

        // Login Button
        loginButton.setTitle("Login", for: .normal)
        loginButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        loginButton.backgroundColor = .customBlue
        loginButton.tintColor = .white
        loginButton.layer.cornerRadius = 20
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        view.addSubview(loginButton)

        // Register Button
        registerButton.setTitle("👋 My first time here", for: .normal)
        registerButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        registerButton.backgroundColor = .secondaryBackground
        registerButton.tintColor = .title
        registerButton.layer.cornerRadius = 20
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        view.addSubview(registerButton)
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

        loginButton.frame = CGRect(x: padding, y: passwordContainer.frame.maxY + 30, width: view.frame.width - 2 * padding, height: fieldHeight)
        registerButton.frame = CGRect(x: padding, y: loginButton.frame.maxY + 10, width: view.frame.width - 2 * padding, height: fieldHeight)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Actions
    @objc private func loginTapped() {
        view.endEditing(true)

        let username = self.usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = self.passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !username.isEmpty, !password.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Information".localized(),
                message: "Please enter both email and password.".localized(),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Done".localized(), style: .default))
            self.present(alert, animated: true)
            return
        }

        // Simple email format validation
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        if !emailPredicate.evaluate(with: username) {
            let alert = UIAlertController(
                title: "Invalid Email".localized(),
                message: "Please enter a valid email address.".localized(),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
            self.present(alert, animated: true)
            return
        }

        AuthManager.shared.login(username: username, password: password) { success in
            DispatchQueue.main.async {
                if success {
                    self.sharingVC.refresh()
                    self.dismiss(animated: true)
                } else {
                    SharingManager.shared.displayError(error: .userNotFound, on: self)
                }
            }
        }
    }

    @objc private func registerTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
}
