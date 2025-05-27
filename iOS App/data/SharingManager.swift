//
//  SharingManager.swift
//  Citrus
//
//  Created by Luka Verč on 14. 5. 25.
//

import UIKit

public enum APIErrorType: Int {
    case userNotFound = 404
    case internalServerError = 1
    case unknown = 300
    case network = 2
    case unauthorized = 200
    case userAlreadyExists = 220
}

class SharingManager {

    static private var instance: SharingManager?
    static public var shared: SharingManager {
        if let instance = SharingManager.instance {
            return instance
        } else {
            let instance = SharingManager()
            SharingManager.instance = instance
            return instance
        }
    }

    //Main page data

    public func getPersonData(completion: @escaping ([PersonData], APIErrorType?) -> ()) {
        AuthManager.shared.getFriends { result in
            switch result {
            case .success(let jsonArray):
                let persons: [PersonData] = jsonArray.compactMap { dict in
                    guard
                        let id = dict["id"] as? Int,
                        let name = dict["name"] as? String,
                        let username = dict["username"] as? String
                    else { return nil }

                    let person = PersonData(id: id, name: name, username: username)

                    person.sleepScore = dict["today_sleep_score"] as? Double

                    return person
                }

                completion(persons, nil)

            case .failure(let error):
                print("❌ Failed to fetch friends:")
                print(error)
                completion([], .network) // or .unknown depending on your error type
            }
        }
    }


    //Friends managment
    public func sendFriendRequest(to username: String, completion: @escaping (APIErrorType?) -> Void) {
        AuthManager.shared.sendFriendRequest(to: username, completion: completion)
    }

    public func answerFriendRequest(to username: String, approve: Bool, completion: @escaping ((APIErrorType?) -> ())) {
        // You’ll need the invite ID, so fetch the current requests first
        getFriendRequests { requests, error in
            guard error == nil else {
                completion(error)
                return
            }

            guard let match = requests.first(where: { $0.sender.username == username }) else {
                completion(.userNotFound)
                return
            }

            AuthManager.shared.answerFriendRequest(id: match.id, approve: approve, completion: completion)
        }
    }

    func removeFriend(username: String, completion: @escaping ((APIErrorType?) -> ())) {
        AuthManager.shared.deleteFriend(username: username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Friend deleted:", username)
                    completion(nil)
                case .failure(let error as NSError):
                    switch error.domain {
                    case "FriendNotFound":
                        completion(.userNotFound)
                    case "DeleteFailed":
                        completion(.internalServerError)
                    default:
                        completion(.network)
                    }
                }
            }
        }
    }

    public func getFriendRequests(completion: @escaping (([FriendRequest], APIErrorType?) -> ())) {
        AuthManager.shared.getFriendRequests { result in
            switch result {
            case .success(let rawRequests):
                print("📦 Raw parsed objects:", rawRequests)

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let requests: [FriendRequest] = rawRequests.compactMap { dict in
                    guard
                        let id = dict["id"] as? Int,
                        let dateString = dict["date"] as? String,
                        let date = formatter.date(from: dateString),
                        let senderDict = dict["sender"] as? [String: Any],
                        let senderId = senderDict["id"] as? Int,
                        let senderName = senderDict["name"] as? String,
                        let senderUsername = senderDict["username"] as? String
                    else {
                        print("❌ Failed to parse friend request:", dict)
                        return nil
                    }

                    let sender = PersonData(id: senderId, name: senderName, username: senderUsername)
                    return FriendRequest(id: id, date: date, sender: sender)
                }

                print("✅ Final FriendRequest objects:", requests)
                completion(requests, nil)

            case .failure(let error):
                print("❌ Network error:", error)
                completion([], .network)
            }
        }
    }

    func getSleepScoresForThisWeek(for username: String, completion: @escaping ([HealthMetric], APIErrorType?) -> Void) {
        AuthManager.shared.getFriendSleepScores(for: username) { result in
            switch result {
            case .success(let raw):
                let metrics = raw.compactMap { HealthMetric(from: $0) }
                completion(metrics.sorted(by: { $0.date < $1.date }), nil)
            case .failure(let error):
                print("❌ Failed to fetch scores:", error)
                completion([], .unknown)
            }
        }
    }


    func parseEventData(from dictArray: [[String: Any]]) -> [EventData] {
        var events: [EventData] = []

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for dict in dictArray {
            guard
                let id = dict["id"] as? Int,
                let typeRaw = dict["type"] as? String,
                let type = EventData.EventDataType(rawValue: typeRaw),
                let dateString = dict["date"] as? String,
                let date = formatter.date(from: dateString),
                let userDict = dict["user"] as? [String: Any],
                let user = PersonData(dict: userDict)
            else {
                print("❌ Skipping event due to missing or invalid fields:", dict)
                continue
            }

            let metadata = dict["metaData"] as? [String: Any]
            let event = EventData(id: id, user: user, metaData: metadata, type: type, date: date)

            if let reactionArray = dict["reactions"] as? [[String: Any]] {
                event.reactions = reactionArray.compactMap {
                    EventReaction(from: $0, event: event)
                }
            }

            events.append(event)
        }

        print("✅ Parsed \(events.count) events")
        return events
    }

    func getEventData(completion: @escaping ([EventData], APIErrorType?) -> Void) {
        AuthManager.shared.getFriendEvents { result in
            switch result {
            case .success(let rawData):
                let events = self.parseEventData(from: rawData)
                DispatchQueue.main.async {
                    completion(events, nil)
                }
            case .failure:
                DispatchQueue.main.async {
                    completion([], .unknown)
                }
            }
        }
    }

    func uploadSleepScore(value: Double, date: Date, completion: @escaping (Bool) -> Void) {
        AuthManager.shared.uploadSleepScore(value: value, date: date) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Sleep score uploaded")
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to upload sleep score:", error)
                    completion(false)
                }
            }
        }
    }

    func uploadEvent(metadata: [String: Any], type: EventData.EventDataType, completion: @escaping (Bool) -> Void) {
        AuthManager.shared.uploadEvent(metadata: metadata, type: type.rawValue) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to upload event:", error)
                    completion(false)
                }
            }
        }
    }

    func reactToEvent(event: EventData, reaction: String, completion: @escaping (EventReaction?) -> Void) {
        AuthManager.shared.reactToEvent(eventId: event.id, reaction: reaction) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let json):
                    guard let dict = json["reaction"] as? [String: Any] else {
                        print("❌ 'reaction' key missing in JSON:", json)
                        completion(nil)
                        return
                    }

                    if let parsed = EventReaction(from: dict, event: event) {
                        completion(parsed)
                    } else {
                        print("❌ Failed to parse EventReaction from dict:", dict)
                        completion(nil)
                    }

                case .failure(let error):
                    print("❌ Failed to react:", error)
                    completion(nil)
                }
            }
        }
    }

    func deleteReaction(id: Int, completion: @escaping (Bool) -> Void) {
        AuthManager.shared.deleteEventReaction(reactionId: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to delete reaction:", error)
                    completion(false)
                }
            }
        }
    }

    func deleteEvent(id: Int, completion: @escaping (Bool) -> Void) {
        AuthManager.shared.deleteEvent(eventId: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to delete event:", error)
                    completion(false)
                }
            }
        }
    }


    //Error handeling
    public func displayError(error: APIErrorType, on: UIViewController, retryAction: (() -> Void)? = nil) {
        guard AuthManager.shared.isLoggedIn else { return }

        AuthManager.shared.checkServerConnectivity { success in
            DispatchQueue.main.async {
                let title = success ? "\("Error".localized())" : "Issues with connectivity".localized()
                let description = success ? "Something went wrong.".localized() : "Try later when you have access to the internet.".localized()

                let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)

                if let action = retryAction, success {
                    alert.addAction(UIAlertAction(title: "Retry".localized(), style: .default, handler: { _ in
                        action()
                    }))
                }

                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

                on.present(alert, animated: true)
            }
        }
    }


    func getEvents(for user: PersonData, completion: @escaping ([EventData], APIErrorType?) -> Void) {
        AuthManager.shared.getEvents(for: user.id) { result in
            switch result {
            case .success(let rawData):
                let events = self.parseEventData(from: rawData)
                DispatchQueue.main.async {
                    completion(events, nil)
                }
            case .failure(let error):
                print("❌ Failed to fetch events for user \(user.username):", error)
                DispatchQueue.main.async {
                    completion([], .network)
                }
            }
        }
    }


    public func sendPoke(to user: PersonData, message: String, completion: @escaping (Bool) -> Void) {
        AuthManager.shared.sendPoke(toUserId: user.id, message: message) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Poke sent to \(user.username)")
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to send poke:", error)
                    completion(false)
                }
            }
        }
    }

}
