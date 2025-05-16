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
    public func getEventData(completion: @escaping ([EventData], APIErrorType?)->()) {
        let person = PersonData(id: 0, name: "Luka", username: "vercluka")

        completion([
            EventData(id: 0, user: person, metaData: [
                "icon" : "figure.run",
                "metric" : "214kcal",
                "workoutType" : 37,
                "isIndoor" : true,
            ], type: .workout, date: .now),
            EventData(id: 1, user: person, metaData: nil, type: .workout, date: .now),
            EventData(id: 2, user: person, metaData: nil, type: .workout, date: .now),
        ], nil)
    }

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

                    return PersonData(id: id, name: name, username: username)
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

    public func removeFriend(to username: String, completion: @escaping ((APIErrorType?) -> ())) {
        AuthManager.shared.getFriends { result in
            switch result {
            case .success(let friends):
                guard let friend = friends.first(where: { $0["username"] as? String == username }),
                      let id = friend["id"] as? Int else {
                    print("❌ Friend not found with username:", username)
                    completion(.userNotFound)
                    return
                }

                AuthManager.shared.removeFriend(withId: id, completion: completion)

            case .failure(let error):
                print("❌ Failed to get friends:", error)
                completion(.network)
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


    //Error handeling
    public func displayError(error: APIErrorType, on: UIViewController, retryAction: (()->())? = nil) {
        let alert = UIAlertController(title: "\("Error".localized()) \(error.rawValue)", message: "Something went wrong.".localized(), preferredStyle: .alert)

        if let action = retryAction {
            alert.addAction(UIAlertAction(title: "Retry".localized(), style: .default, handler: { _ in
                action()
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

        on.present(alert, animated: true)

    }

}
