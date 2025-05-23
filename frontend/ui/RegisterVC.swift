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
    private let confirmPasswordField = UITextField()

    private let usernameContainer = UIView()
    private let passwordContainer = UIView()
    private let confirmPasswordContainer = UIView()

    private let registerButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.getNavigationItem(image: "xmark", target: self, action: #selector(onClose), backgroundColor: .secondaryBackground)

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

        // Email field
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

        // Password field
        passwordField.placeholder = "Password".localized()
        passwordField.isSecureTextEntry = true
        passwordField.font = .roundedFont(ofSize: 17, weight: .regular)
        passwordField.textColor = .title
        passwordField.delegate = self
        passwordField.returnKeyType = .next

        passwordContainer.backgroundColor = .secondaryBackground
        passwordContainer.layer.cornerRadius = 20
        passwordContainer.layer.masksToBounds = true
        passwordContainer.addSubview(passwordField)
        view.addSubview(passwordContainer)

        // Confirm Password field
        confirmPasswordField.placeholder = "Confirm Password".localized()
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.font = .roundedFont(ofSize: 17, weight: .regular)
        confirmPasswordField.textColor = .title
        confirmPasswordField.delegate = self
        confirmPasswordField.returnKeyType = .done

        confirmPasswordContainer.backgroundColor = .secondaryBackground
        confirmPasswordContainer.layer.cornerRadius = 20
        confirmPasswordContainer.layer.masksToBounds = true
        confirmPasswordContainer.addSubview(confirmPasswordField)
        view.addSubview(confirmPasswordContainer)

        // Register button
        registerButton.setTitle("Create Account".localized(), for: .normal)
        registerButton.titleLabel?.font = .roundedFont(ofSize: 17, weight: .semibold)
        registerButton.backgroundColor = .customBlue
        registerButton.tintColor = .white
        registerButton.layer.cornerRadius = 20
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        view.addSubview(registerButton)

        // Login button
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

        confirmPasswordContainer.frame = CGRect(x: padding, y: passwordContainer.frame.maxY + 10, width: view.frame.width - 2 * padding, height: fieldHeight)
        confirmPasswordField.frame = CGRect(x: 15, y: 0, width: confirmPasswordContainer.frame.width - 30, height: fieldHeight)

        registerButton.frame = CGRect(x: padding, y: confirmPasswordContainer.frame.maxY + 30, width: view.frame.width - 2 * padding, height: fieldHeight)
        loginButton.frame = CGRect(x: padding, y: registerButton.frame.maxY + 10, width: view.frame.width - 2 * padding, height: fieldHeight)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            confirmPasswordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    // MARK: - Actions

    @objc private func registerTapped() {
        view.endEditing(true)

        let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPassword = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")

        guard emailPredicate.evaluate(with: username) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        guard !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill out all password fields.")
            return
        }

        guard password == confirmPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords do not match. Please try again.")
            return
        }

        AuthManager.shared.register(username: username, password: password, name: UserData.shared.fullName) { success in
            AuthManager.shared.login(username: username, password: password) { success in
                DispatchQueue.main.async {
                    if success {
                        self.sharingVC.refresh()
                        self.dismiss(animated: true)
                    } else {
                        SharingManager.shared.displayError(error: .unknown, on: self)
                    }
                }
            }
        }
    }

    @objc private func loginTapped() {
        self.navigationController?.pushViewController(LoginVC(for: self.sharingVC), animated: true)
    }

    @objc
    private func onClose() {
        self.dismiss(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title.localized(), message: message.localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
        self.present(alert, animated: true)
    }
}
