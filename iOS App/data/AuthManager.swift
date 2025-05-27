//
//  AuthManager.swift
//  Citrus
//
//  Created by Luka Verč on 16. 5. 25.
//

import UserNotifications
import UIKit

class AuthManager {
    static let shared = AuthManager()

    public let baseURL = /*"http://192.168.121.139:1004"*/"https://api.getyoa.app/yoaapi"
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

    public var isLoggedIn: Bool {
        return token != nil && hasCreatedAccount
    }

    public func getStoredUsername() -> String? {
        return self.savedUsername
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

                    if let user = json["user"] as? [String: Any],
                       let name = user["name"] as? String {
                        UserData.shared.fullName = name
                    }

                    // ✅ Upload APNs token if available
                    if let apnsToken = UserDefaults.standard.string(forKey: "apnsToken") {
                        self.uploadDeviceToken(token: apnsToken)
                    }

                    self.flushLoginQueue(with: .success(()))
                } else {
                    self.clearCredentials()
                    self.flushLoginQueue(with: .failure(NSError(domain: "NoToken", code: 401)))
                }

            case .failure(let error as NSError):
                if error.code == 401 || error.code == 403 {
                    self.clearCredentials()
                }
                self.flushLoginQueue(with: .failure(error))

            case .failure(let error):
                self.flushLoginQueue(with: .failure(error))
            }
        }
    }

    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let body = ["username": username, "password": password]

        postRequest(endpoint: "/login", body: body) { result in
            switch result {
            case .success(let json):
                if let token = json["token"] as? String {
                    self.token = token
                    self.savedUsername = username
                    self.savedPassword = password
                    self.hasCreatedAccount = true

                    if let user = json["user"] as? [String: Any],
                       let name = user["name"] as? String {
                        UserData.shared.fullName = name
                    }

                    // ✅ Upload APNs token if available
                    if let apnsToken = UserDefaults.standard.string(forKey: "apnsToken") {
                        self.uploadDeviceToken(token: apnsToken)
                    }

                    // Ask for push notification permission
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        if settings.authorizationStatus == .notDetermined {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                if granted {
                                    DispatchQueue.main.async {
                                        UIApplication.shared.registerForRemoteNotifications()
                                    }
                                } else {
                                    print("🔕 Push permission denied or error: \(error?.localizedDescription ?? "None")")
                                }
                            }
                        }
                    }

                    completion(true)
                } else {
                    completion(false)
                }
            case .failure:
                completion(false)
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
        if let apnsToken = UserDefaults.standard.string(forKey: "apnsToken") {
            removeDeviceToken(token: apnsToken) { success in
                print(success ? "✅ Device token removed from server" : "❌ Failed to remove token from server")
            }
        }

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
            // Try login with saved credentials
            login { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    self.signOut()
                    completion(.failure(NSError(domain: "LoginFailed", code: 401)))
                }
            }
        } else {
            // Validate current token
            checkToken { valid in
                if valid {
                    completion(.success(()))
                } else {
                    // Try to re-login
                    self.login { result in
                        switch result {
                        case .success:
                            completion(.success(()))
                        case .failure:
                            self.signOut()
                            completion(.failure(NSError(domain: "ReLoginFailed", code: 403)))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Token Check

    private func checkToken(completion: @escaping (Bool) -> Void) {
        guard let token = token else {
            completion(false)
            return
        }

        guard let url = URL(string: baseURL + "/check-auth") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error:", error)
                // Don't sign out — attempt re-login instead
                self.retryLoginIfPossible(completion: completion)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    print("❌ Unauthorized — attempting re-login")
                    self.retryLoginIfPossible(completion: completion)
                    return
                }
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let _ = json["user"] as? [String: Any] else {
                print("❌ Invalid token response — trying re-login")
                self.retryLoginIfPossible(completion: completion)
                return
            }

            // Token is valid
            if let user = json["user"] as? [String: Any],
               let name = user["name"] as? String {
                UserData.shared.fullName = name
            }

            completion(true)
        }.resume()
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


    private func clearCredentials() {
        self.token = nil
        self.savedUsername = nil
        self.savedPassword = nil
        self.hasCreatedAccount = false
    }


    private func retryLoginIfPossible(completion: @escaping (Bool) -> Void) {
        self.login { result in
            switch result {
            case .success:
                print("✅ Token refreshed via login")
                completion(true)
            case .failure:
                self.signOut()
                completion(false)
            }
        }
    }


    public func checkServerConnectivity(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL + "/check-connectivity") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                print("⚠️ Server unreachable:", error?.localizedDescription ?? "No response")
                completion(false)
            }
        }.resume()
    }


    func uploadSleepScore(value: Double, date: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]

                let body: [String: Any] = [
                    "type": "sleep",
                    "value": value,
                    "date": formatter.string(from: date)
                ]

                self.postRequest(endpoint: "/health/upload-health-metric", body: body) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    func deleteFriend(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                // First, fetch friends to find ID
                self.getFriends { result in
                    switch result {
                    case .success(let friends):
                        guard let friend = friends.first(where: { $0["username"] as? String == username }),
                              let friendId = friend["id"] as? Int else {
                            completion(.failure(NSError(domain: "FriendNotFound", code: 404)))
                            return
                        }

                        guard let url = URL(string: "\(self.baseURL)/friends/delete-friendship?friendId=\(friendId)") else {
                            completion(.failure(NSError(domain: "BadURL", code: 400)))
                            return
                        }

                        var request = URLRequest(url: url)
                        request.httpMethod = "DELETE"
                        request.setValue("Bearer \(self.token ?? "")", forHTTPHeaderField: "Authorization")

                        URLSession.shared.dataTask(with: request) { _, response, error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }

                            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                                completion(.failure(NSError(domain: "DeleteFailed", code: httpResponse.statusCode)))
                                return
                            }

                            completion(.success(()))
                        }.resume()

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Profile Update Endpoints

    func changeName(to newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let body = ["name": newName]
                self.patchRequest(endpoint: "/profile/name", body: body, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func changeUsername(to newUsername: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let body = ["username": newUsername]
                self.patchRequest(endpoint: "/profile/username", body: body) { result in
                    switch result {
                    case .success:
                        self.savedUsername = newUsername
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func changePassword(oldPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let body = [
                    "oldPassword": oldPassword,
                    "newPassword": newPassword
                ]
                self.patchRequest(endpoint: "/profile/password", body: body) { result in
                    switch result {
                    case .success:
                        self.savedPassword = newPassword
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func patchRequest(endpoint: String, body: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "BadURL", code: 400)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Server", code: httpResponse.statusCode)))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func getFriendSleepScores(for username: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        print("Fetching scores for: \(username)")

        ensureAuthenticated { result in
            switch result {
            case .success:
                guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    completion(.failure(NSError(domain: "EncodingError", code: 400)))
                    return
                }

                let endpoint = "/health/friend-sleep-scores?username=\(encodedUsername)&type=sleep"

                print("➡️ Calling endpoint:", endpoint)

                self.authenticatedGETWrapped(endpoint: endpoint, arrayKey: "scores", completion: completion)

            case .failure(let error):
                print("❌ Auth failed:", error)
                completion(.failure(error))
            }
        }
    }


    func getFriendEvents(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                self.authenticatedGETWrapped(endpoint: "/events/get-events", arrayKey: "data", completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func uploadEvent(metadata: [String: Any], type: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let body: [String: Any] = ["metadata": metadata, "type": type]

        ensureAuthenticated { result in
            switch result {
            case .success:
                self.postRequest(endpoint: "/events/upload-event", body: body, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func reactToEvent(eventId: Int, reaction: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let body: [String: Any] = ["eventId": eventId, "reaction": reaction]

        ensureAuthenticated { result in
            switch result {
            case .success:
                self.postRequest(endpoint: "/events/react-to-event", body: body, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteEventReaction(reactionId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                guard let url = URL(string: self.baseURL + "/events/event-reaction/\(reactionId)") else {
                    completion(.failure(NSError(domain: "BadURL", code: 400)))
                    return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                if let token = self.token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                URLSession.shared.dataTask(with: request) { _, response, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                        completion(.failure(NSError(domain: "Server", code: httpResponse.statusCode)))
                    } else {
                        completion(.success(()))
                    }
                }.resume()
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    func getEvents(for userId: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let endpoint = "/events/get-events/user/\(userId)"
                self.authenticatedGETWrapped(endpoint: endpoint, arrayKey: "data", completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getEventReactions(eventId: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let endpoint = "/events/get-event-reactions?eventId=\(eventId)"
                self.authenticatedGETWrapped(endpoint: endpoint, arrayKey: "reactions", completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteEvent(eventId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                guard let url = URL(string: "\(self.baseURL)/events/delete/\(eventId)") else {
                    completion(.failure(NSError(domain: "BadURL", code: 400)))
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(self.token ?? "")", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { _, response, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                        completion(.failure(NSError(domain: "Server", code: httpResponse.statusCode)))
                    } else {
                        completion(.success(()))
                    }
                }.resume()

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    public func uploadDeviceToken(token: String) {
        guard let url = URL(string: baseURL + "/notifications/register-device-token"),
              let jwt = self.token else {
            print("❌ Missing token or bad URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Upload error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Device token uploaded")
            } else {
                print("⚠️ Upload failed:", response.debugDescription)
            }
        }.resume()
    }


    func sendPoke(toUserId: Int, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ensureAuthenticated { result in
            switch result {
            case .success:
                let body: [String: Any] = [
                    "toUserId": toUserId,
                    "message": message
                ]
                self.postRequest(endpoint: "/notifications/poke", body: body) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func removeDeviceToken(token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL + "/notifications/remove-device-token") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let tokenValue = self.token {
            request.addValue("Bearer \(tokenValue)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = ["token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Error removing token:", error)
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}
