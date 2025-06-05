//
//  FitnessParameters.swift
//  CitrusWatch Watch App
//
//  Created by Luka Verč on 30. 9. 24.
//

import SwiftUI

extension HealthData {
    func getFitnessParameters(completion: @escaping ([ParameterObject])->()) {
        self.getCaloriesBurned(for: HealthData.shared.selectedDate) { calories in
            self.getExerciseMinutes(for: HealthData.shared.selectedDate) { exercise in
                self.getLatestAverageHeartRate(for: HealthData.shared.selectedDate) { avgHeartRate in
                    self.getSteps(for: HealthData.shared.selectedDate) { steps in
                        self.getLatestRestingHeartRate(for: HealthData.shared.selectedDate) { restingHeartRate in
                            self.getLatestHRV(for: HealthData.shared.selectedDate) { hrv in
                                completion([
                                    ParameterObject(icon: Image("flame.fill"), title: "Energy Burned".localized(), description:String((Int(calories))) + " kcal"),
                                    ParameterObject(icon: Image("figure.run"), title: "Exercise".localized(), description: "\(Int(exercise)) min"),
                                    ParameterObject(icon: Image(systemName: "heart.fill"), title: "Average Heart Rate".localized(), description: String(Int(avgHeartRate))),
                                    ParameterObject(icon: Image(systemName: "arrow.down.heart.fill"), title: "Resting Heart Rate".localized(), description: String(Int(restingHeartRate))),
                                    ParameterObject(icon: Image(systemName: "shoeprints.fill"), title: "Steps".localized(), description: String(Int(steps))),
                                    ParameterObject(icon: Image(systemName: "chart.xyaxis.line"), title: "Heart Rate Variability".localized(), description: String(hrv.rounded(toPlaces: 1)))
                                ])
                            }
                        }
                    }
                }
            }
        }
    }
}
