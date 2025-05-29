//
//  SharingData.swift
//  Citrus
//
//  Created by Luka Verč on 15. 5. 25.
//

import UIKit
import HealthKit

extension SharingManager {

    public class PersonData {
        var id: Int = 0
        var name: String = ""
        var username: String = ""

        var sleepScore: Double? = nil
        var numberOfWorkout: Int = 0

        public var isMe: Bool {
            return self.username == AuthManager.shared.getStoredUsername()
        }

        // Standard initializer
        convenience init(id: Int, name: String, username: String) {
            self.init()
            self.id = id
            self.name = name
            self.username = username
        }

        // Robust dictionary-based initializer
        convenience init?(dict: [String: Any]) {
            guard
                let id = dict["id"] as? Int,
                let name = dict["name"] as? String,
                let username = dict["username"] as? String
            else {
                print("❌ Failed to parse required PersonData fields:", dict)
                return nil
            }

            self.init(id: id, name: name, username: username)

            // Accept sleepScore as Double or String
            if let sleep = dict["sleepScore"] as? Double {
                self.sleepScore = sleep
            } else if let sleepStr = dict["sleepScore"] as? String, let sleep = Double(sleepStr) {
                self.sleepScore = sleep
            }

            // Accept numberOfWorkout if present
            if let workouts = dict["numberOfWorkout"] as? Int {
                self.numberOfWorkout = workouts
            }
        }

        public struct SleepScoreDate {
            var date: Date
            var score: Double
        }
    }

    public class EventData {
        var id: Int = 0
        var user: PersonData?
        var metaData: [String : Any]?
        var type: EventDataType = .unknown
        var date: Date = .now
        var reactions: [EventReaction] = []

        public enum EventDataType: String, Codable {
            case unknown = "unknown"
            case workout = "workout"
            case journalStat = "journal_stats"
            case healthAchievement = "health_achievement"
        }

        public func getIcon() -> UIImage? {
            return SFSymbol(systemName: self.metaData?["icon"] as? String ?? "")
        }

        public func getMainText() -> String {
            if self.type == .workout {
                if let metric = self.metaData?["metric"] as? String {
                    return metric
                } else {
                    return "No data".localized()
                }
            } else if self.type == .healthAchievement {
                let healthType = self.metaData?["metricType"] as? String ?? "sleep"
                if healthType == "sleep" || healthType == "stress" {
                    if let metric = self.metaData?["score"] as? Double {
                        return "\(Int(metric * 100))/100"
                    } else {
                        return "No data".localized()
                    }
                } else {
                    let unit = self.metaData?["unit"] as? String ?? ""
                    if let value = self.metaData?["value"] as? Double {
                        if unit == "time" {
                            return value.toHoursMinutesString()
                        } else if unit == "double" {
                            return "\(value.rounded(toPlaces: 1))"
                        } else {
                            return "No unit".localized()
                        }
                    } else {
                        return "No data".localized()
                    }
                }
            } else {
                return ""
            }
        }

        public func getWorkout() -> HKWorkout? {
            if let workoutType = self.metaData?["workoutType"] as? Int,
               let isIndoor = self.metaData?["isIndoor"] as? Bool {
                let activityType = HKWorkoutActivityType(rawValue: UInt(workoutType)) ?? .barre

                let workout = HKWorkout(activityType: activityType,
                                        start: .now,
                                        end: .now,
                                        duration: 0,
                                        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 0),
                                        totalDistance: HKQuantity(unit: .mile(), doubleValue: 0),
                                        metadata: [
                                            HKMetadataKeyIndoorWorkout : isIndoor
                                        ])

                return workout
            } else {
                return nil
            }
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

        init?(from dict: [String: Any], event: EventData) {
            guard
                let id = dict["id"] as? Int,
                let content = dict["content"] as? String,
                let userDict = dict["user"] as? [String: Any],
                let user = PersonData(dict: userDict)
            else {
                return nil
            }

            self.id = id
            self.content = content
            self.event = event
            self.user = user
        }
    }

    public struct FriendRequest {
        var id: Int
        var date: Date
        var sender: PersonData
    }

    struct HealthMetric {
        let date: Date
        let value: Double
        let type: String
        let user: PersonData

        init?(from dict: [String: Any]) {
            guard
                let value = dict["value"] as? Double,
                let type = dict["type"] as? String,
                let dateStr = dict["date"] as? String,
                let userDict = dict["user"] as? [String: Any],
                let id = userDict["iduser"] as? Int,
                let name = userDict["name"] as? String,
                let username = userDict["username"] as? String
            else {
                return nil
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            guard let date = formatter.date(from: dateStr) else {
                return nil
            }

            self.value = value
            self.type = type
            self.date = date
            self.user = PersonData(id: id, name: name, username: username)
        }
    }

}
