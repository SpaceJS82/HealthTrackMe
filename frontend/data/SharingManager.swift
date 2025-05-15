//
//  SharingManager.swift
//  Citrus
//
//  Created by Luka Verč on 14. 5. 25.
//

import UIKit

public enum APIErrorType: Int {
    case notFound = 404
    case internalServerError = 1
    case unknown = 300
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

    public func getPersonData(completion: @escaping ([PersonData], APIErrorType?)->()) {
        completion([
            PersonData(id: 0, name: "Luka", username: "luka"),
            PersonData(id: 1, name: "Jaka", username: "jaka"),
            PersonData(id: 2, name: "Klemen", username: "klemen"),
        ], nil)
    }


    //Friends managment
    public func sendFriendRequest(to username: String, completion: @escaping ((APIErrorType?)->())) {

    }

    public func answerFriendRequest(to username: String, approve: Bool, completion: @escaping ((APIErrorType?)->())) {
        completion(nil)
    }

    public func removeFriend(to username: String, completion: @escaping ((APIErrorType?)->())) {

    }

    public func getFriendRequests(completion: @escaping (([FriendRequest], APIErrorType?)->())) {

        let person1 = PersonData(id: 0, name: "Klemen", username: "klemen")
        let person2 = PersonData(id: 1, name: "Jaka", username: "jaka")

        completion([
            FriendRequest(id: 0, date: .now, sender: person1),
            FriendRequest(id: 1, date: .now, sender: person2),
        ], nil)
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
