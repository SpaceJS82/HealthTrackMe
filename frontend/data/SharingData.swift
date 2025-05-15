//
//  SharingData.swift
//  Citrus
//
//  Created by Luka Verč on 15. 5. 25.
//

import UIKit

extension SharingManager {
    
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
    
    public struct FriendRequest {
        var id: Int
        var date: Date
        var sender: PersonData
    }
    
}
