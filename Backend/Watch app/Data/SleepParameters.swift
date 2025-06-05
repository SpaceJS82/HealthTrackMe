//
//  SleepParameters.swift
//  CitrusWatch Watch App
//
//  Created by Luka Verč on 30. 9. 24.
//

import SwiftUI

extension HealthData {
    func getSleepParameters(completion: @escaping ([ParameterObject])->()) {
        let dispatchGroup = DispatchGroup()

        // Variables to hold results
        var sleepDuration: String = ""
        var restorativeSleepDuration: String = ""
        var avgHeartRate: Double = 0.0
        var temperature: Double = 0.0
        var hrv: Double = 0.0
        var oxygenSaturation: Double = 0.0
        var respiratoryRate: Double = 0.0

        // Selected date
        let selectedDate = HealthData.shared.selectedDate

        // Fetch sleep duration
        dispatchGroup.enter()
        self.getSleepDuration(for: selectedDate) { result in
            sleepDuration = result.toHoursMinutesString()
            dispatchGroup.leave()
        }
        
        // Fetch restorative sleep duration
        dispatchGroup.enter()
        self.getRestorativeSleepDuration(for: selectedDate) { result in
            restorativeSleepDuration = result.toHoursMinutesString()
            dispatchGroup.leave()
        }

        // Fetch average heart rate
        dispatchGroup.enter()
        self.getSleepingHeartRate(on: selectedDate) { result in
            avgHeartRate = result
            dispatchGroup.leave()
        }

        // Fetch temperature
        dispatchGroup.enter()
        self.getSleepingTemperature(on: selectedDate) { result in
            temperature = result.rounded(toPlaces: 1)
            dispatchGroup.leave()
        }

        // Fetch HRV
        dispatchGroup.enter()
        self.getSleepingHRV(on: selectedDate) { result in
            hrv = result
            dispatchGroup.leave()
        }

        // Fetch oxygen saturation
        dispatchGroup.enter()
        self.getSleepingOxygenSaturation(on: selectedDate) { result in
            oxygenSaturation = result
            dispatchGroup.leave()
        }

        // Fetch respiratory rate
        dispatchGroup.enter()
        self.getSleepingRespitoryRate(on: selectedDate) { result in
            respiratoryRate = result.rounded(toPlaces: 1)
            dispatchGroup.leave()
        }

        // When all async tasks complete, execute the completion handler
        dispatchGroup.notify(queue: .main) {
            let parameters = [
                ParameterObject(icon: Image(systemName: "clock.fill"), title: "Sleep Duration".localized(), description: sleepDuration),
                ParameterObject(icon: Image(systemName: "zzz"), title: "Restorative Sleep".localized(), description: restorativeSleepDuration),
                ParameterObject(icon: Image(systemName: "heart.fill"), title: "Heart Rate".localized(), description: String(Int(avgHeartRate)) + " BPM"),
                ParameterObject(icon: Image(systemName: "thermometer.medium"), title: "Wrist Temperature".localized(), description: String(temperature)),
                ParameterObject(icon: Image(systemName: "chart.xyaxis.line"), title: "Heart Rate Variability".localized(), description: String(Double(Int(hrv)))),
                ParameterObject(icon: Image(systemName: "bubbles.and.sparkles.fill"), title: "Oxygen Saturation".localized(), description: String((oxygenSaturation * 100).rounded(toPlaces: 1))),
                ParameterObject(icon: Image(systemName: "lungs.fill"), title: "Respiratory Rate".localized(), description: String(respiratoryRate) + " br/min")
            ]
            
            completion(parameters)
        }
    }
}
