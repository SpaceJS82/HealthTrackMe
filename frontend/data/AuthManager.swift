//
//  AuthManager.swift
//  Citrus
//
//  Created by Luka Verč on 16. 5. 25.
//

import Foundation

class AuthManager {
    static let shared = AuthManager()

    private let baseURL = "http://localhost:3000"
    private let tokenKey = "jwtToken"

    private var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }

    private var savedUsername: String? {
        get { UserDefaults.standard.string(forKey: "username") }
        set { UserDefaults.standard.set(newValue, forKey: "username") }
    }

    private var savedPassword: String? {
        get { UserDefaults.standard.string(forKey: "password") }
        set { UserDefaults.standard.set(newValue, forKey: "password") }
    }

    private var hasCreatedAccount: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCreatedAccount") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCreatedAccount") }
    }

    var willAutoLogin: Bool {
        return hasCreatedAccount && savedUsername != nil && savedPassword != nil
    }

    private var isLoggingIn = false
    private var loginQueue: [(Result<Void, Error>) -> Void] = []

    private init() {}

    // MARK: - Public API

    func login(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let username = savedUsername, let password = savedPassword else {
            completion(.failure(NSError(domain: "NoCredentials", code: 401)))
            return
        }

        isLoggingIn = true
        loginQueue.append(completion)

        let body = ["username": username, "password": password]

        postRequest(endpoint: "/login", body: body) { result in
            switch result {
            case .success(let json):
                if let token = json["token"] as? String {
                    self.token = token
                    self.flushLoginQueue(with: .success(()))
                } else {
                    self.flushLoginQueue(with: .failure(NSError(domain: "NoToken", code: 401)))
                }
            case .failure(let error):
                self.flushLoginQueue(with: .failure(error))
            }
        }
    }

    func register(username: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        let body = ["username": username, "password": password, "name": name]

        postRequest(endpoint: "/register", body: body) { result in
            switch result {
            case .success:
                self.savedUsername = username
                self.savedPassword = password
                self.hasCreatedAccount = true
                self.login { result in
                    switch result {
                    case .success:
                        completion(true)
                    case .failure:
                        completion(false)
                    }
                }
            case .failure:
                completion(false)
            }
        }
    }

    func signOut() {
        token = nil
        hasCreatedAccount = false
        savedUsername = nil
        savedPassword = nil
        isLoggingIn = false
        loginQueue.removeAll()
        print("👋 Signed out")
    }

    func ensureAuthenticated(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isLoggingIn else {
            loginQueue.append(completion)
            return
        }

        if token == nil {
            login(completion: completion)
        } else {
            checkToken { valid in
                if valid {
                    completion(.success(()))
                } else {
                    self.token = nil
                    self.login(completion: completion)
                }
            }
        }
    }

    // MARK: - Token Check

    private func checkToken(completion: @escaping (Bool) -> Void) {
        authenticatedGET(endpoint: "/check-auth") { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }

    // MARK: - API Calls

    func getFriends(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard hasCreatedAccount else {
            completion(.success([]))
            return
        }

        ensureAuthenticated { result in
            switch result {
            case .success:
                self.authenticatedGETWrapped(endpoint: "/friends/get-friends", arrayKey: "friends", completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getFriendRequests(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard hasCreatedAccount else {
            completion(.success([]))
            return
        }

        ensureAuthenticated { result in
            switch result {
            case .success:
                self.authenticatedGETWrapped(endpoint: "/invites/received", arrayKey: "data", completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func sendFriendRequest(to receiverUsername: String, completion: @escaping (APIErrorType?) -> Void) {
        guard hasCreatedAccount else {
            completion(nil)
            return
        }

        ensureAuthenticated { result in
            switch result {
            case .success:
                let body: [String: Any] = ["username": receiverUsername]

                self.postRequest(endpoint: "/invites/", body: body) { result in
                    switch result {
                    case .success:
                        completion(nil)
                    case .failure(let error):
                        print("❌ Error sending request:", error)
                        completion(.network)
                    }
                }

            case .failure:
                completion(.unauthorized)
            }
        }
    }

    func answerFriendRequest(id: Int, approve: Bool, completion: @escaping (APIErrorType?) -> Void) {
        guard hasCreatedAccount else {
            completion(nil)
            return
        }

        ensureAuthenticated { result in
            switch result {
            case .success:
                let endpoint = "/invites/\(id)" + (approve ? "/accept" : "")
                var request = URLRequest(url: URL(string: self.baseURL + endpoint)!)
                request.httpMethod = approve ? "POST" : "DELETE"
                request.setValue("Bearer \(self.token ?? "")", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { _, _, error in
                    if let error = error {
                        print("❌ Answer request failed:", error)
                        completion(.network)
                        return
                    }
                    completion(nil)
                }.resume()

            case .failure:
                completion(.unauthorized)
            }
        }
    }

    func removeFriend(withId id: Int, completion: @escaping (APIErrorType?) -> Void) {
        guard hasCreatedAccount else {
            completion(nil)
            return
        }

        ensureAuthenticated { result in
            switch result {
            case .success:
                let endpoint = "/friends/delete-friendship?friendId=\(id)"
                guard let url = URL(string: self.baseURL + endpoint) else {
                    completion(.network)
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(self.token ?? "")", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { _, _, error in
                    if let error = error {
                        print("❌ Remove friend failed:", error)
                        completion(.network)
                        return
                    }
                    completion(nil)
                }.resume()

            case .failure:
                completion(.unauthorized)
            }
        }
    }

    // MARK: - Networking Core

    private func authenticatedGET(endpoint: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "NoToken", code: 401)))
            return
        }

        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "BadURL", code: 400)))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            self.handleResponse(data: data, error: error, completion: completion)
        }.resume()
    }

    private func postRequest(endpoint: String, body: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "BadURL", code: 400)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            self.handleSingleResponse(data: data, error: error, completion: completion)
        }.resume()
    }

    private func handleResponse(data: Data?, error: Error?, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            completion(.failure(NSError(domain: "ParseError", code: 500)))
            return
        }

        completion(.success(json))
    }

    private func handleSingleResponse(data: Data?, error: Error?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(.failure(NSError(domain: "ParseError", code: 500)))
            return
        }

        completion(.success(json))
    }

    private func flushLoginQueue(with result: Result<Void, Error>) {
        isLoggingIn = false
        loginQueue.forEach { $0(result) }
        loginQueue.removeAll()
    }

    private func authenticatedGETWrapped(endpoint: String, arrayKey: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "NoToken", code: 401)))
            return
        }

        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "BadURL", code: 400)))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let array = jsonObject[arrayKey] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "ParseError", code: 500)))
                return
            }

            completion(.success(array))
        }.resume()
    }
}
