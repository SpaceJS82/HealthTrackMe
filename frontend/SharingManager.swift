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
    
    
    //Classes
    public class PersonData {
        var id: Int = 0
        var name: String = ""
        var username: String = ""
        
        var sleepScore: Double = 0.6
        var numberOfWorkout: Int = 1
        
        convenience init(id: Int, name: String, username: String) {
            self.init()
            self.id = id
            self.name = name
            self.username = username
        }
    }
    
    public class EventData {
        var id: Int = 0
        var user: PersonData?
        var metaData: [String : Any]?
        var type: EventDataType = .unknown
        var date: Date = .now
        var reactions: [EventReaction] = []
        
        public func loadReactions(completion: @escaping (APIErrorType?)->()) {
            SharingManager.shared.getPersonData { persons, error in
                self.reactions = [
                    EventReaction(id: 0, content: "👋", event: self, user: persons.first!),
                    EventReaction(id: 1, content: "👋", event: self, user: persons.first!),
                    EventReaction(id: 2, content: "👋", event: self, user: persons.first!),
                    EventReaction(id: 3, content: "👋", event: self, user: persons.first!),
                ]
                completion(nil)
            }
        }
        
        public enum EventDataType: String, Codable {
            case unknown = "unknown"
            case workout = "workout"
            case journalStat = "journal_stats"
            case healthAchievement = "health_achievement"
        }
        
        convenience init(id: Int, user: PersonData, metaData: [String : Any]?, type: EventDataType, date: Date) {
            self.init()
            self.id = id
            self.user = user
            if let metaData = metaData {
                self.metaData = metaData
            }
            self.type = type
            self.date = date
        }
    }
    
    public struct EventReaction {
        var id: Int
        var content: String
        var event: EventData
        var user: PersonData
    }

}
