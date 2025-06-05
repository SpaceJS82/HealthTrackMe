//
//  DetailsView.swift
//  CitrusWatch Watch App
//
//  Created by Klemen Novak on 22. 9. 24.
//

import SwiftUI
import Charts // Ensure this is imported for charting

struct SleepData: Identifiable {
    let id = UUID()
    let date: Date
    let quality: Double
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView(category: .sleep)
    }
}

struct DetailsView: View {
    
    var category: HeathCategory
    
    @State private var parametersTitle: String = ""
    @State private var parameters: [ParameterObject] = []
    
    @State private var chartData: [SleepData] = []
    @State private var title: String = ""

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    if chartData.isEmpty {
                        ProgressView("\("Wait".localized())...") // Loading indicator while fetching data
                            .padding()
                    } else {
                        Chart {
                            // Line connecting the points, in green
                            ForEach(chartData) { dataPoint in
                                LineMark(
                                    x: .value("Date", formattedDate(date: dataPoint.date)),
                                    y: .value("Quality", dataPoint.quality)
                                )
                                .foregroundStyle(.secondaryText)
                            }
                            
                            // Dots representing each data point
                            ForEach(chartData) { dataPoint in
                                PointMark(
                                    x: .value("Date", formattedDate(date: dataPoint.date)),
                                    y: .value("Quality", dataPoint.quality)
                                )
                                .foregroundStyle(isToday(date: dataPoint.date) ? .customBlue : .title)
                            }
                        }
                        .chartYScale(domain: yAxisDomain())
                        .padding(.top, 16)
                        .padding([.leading, .trailing], 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(parametersTitle)
                            .font(Font.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.secondaryText)
                            .padding([.leading, .trailing], 10)
                        ForEach(parameters) { parameter in
                            ZStack(alignment: .leading) {
                                Color.secondaryBackground
                                    .cornerRadius(20)
                                    .foregroundStyle(Color.title)
                                HStack {
                                    (parameter.icon ?? Image(""))
                                        .padding(.trailing, 5)
                                        .font(Font.system(size: 17, weight: .semibold, design: .rounded))
                                    VStack(alignment: .leading) {
                                        Text(parameter.title.capitalized)
                                            .font(Font.system(size: 14, weight: .regular, design: .default))
                                            .foregroundStyle(Color.secondaryText)
                                        Text(parameter.description)
                                            .font(Font.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.title)
                                    }
                                }
                                .padding(10)
                            }
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                        }
                        
                        Text("More insights available on the iPhone app.".localized())
                            .font(.system(size: 17))
                            .foregroundStyle(.title)
                            .multilineTextAlignment(.leading)
                            .padding([.leading, .trailing], 10)
                    }
                    .padding(.top, 15)
                }
            }
            .onAppear {
                self.refresh()
            }
            .onTapGesture {
                self.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                self.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(title)
                        .font(Font.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.title)
                        .frame(alignment: .topTrailing)
                }
            }
            .background(Color.background)
        }
    }
    
    func refresh() {
        self.fetchChartData()
        if self.category == .sleep {
            self.parametersTitle = "Last night".localized()
            HealthData.shared.getSleepParameters { result in
                self.parameters = result
            }
        } else if self.category == .fitness {
            self.parametersTitle = "Today".localized()
            HealthData.shared.getFitnessParameters { result in
                self.parameters = result
            }
        } else {
            self.parametersTitle = ""
            self.parameters = []
        }
    }

    // Calculate the domain for the y-axis with a 10% margin
    func yAxisDomain() -> ClosedRange<Double> {
        guard let minQuality = chartData.map({ $0.quality }).min(),
              let maxQuality = chartData.map({ $0.quality }).max() else {
            return 0...1 // Default range if data is missing
        }

        // Calculate a 10% margin on the top and bottom
        let margin = (maxQuality - minQuality) * 0.1
        return (minQuality - margin)...(maxQuality + margin)
    }

    // Get the last 10 days, including today
    func pastTenDays() -> [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: Date())
        }
    }

    // Fetch sleep data for the past 10 days
    func fetchChartData() {
        
        if self.category == .body {
            self.title = "Wellbeing".localized()
        } else if self.category == .sleep {
            self.title = "Sleep Quality".localized()
        } else if self.category == .fitness {
            self.title = "Fitness Score".localized()
        }
        
        let dates = pastTenDays()
        for date in dates {
            if category == .body {
                // Fetch wellbeing data
                HealthData.shared.getBodyWatchScore(for: date) { score in
                    let dataPoint = SleepData(date: date, quality: score * 100)
                    chartData.append(dataPoint)
                    chartData.sort { $0.date < $1.date }
                }
            } else if category == .sleep {
                // Fetch sleep data
                HealthData.shared.getSleepWatchScore(for: date) { quality in
                    DispatchQueue.main.async {
                        let dataPoint = SleepData(date: date, quality: quality * 100)
                        chartData.append(dataPoint)
                        chartData.sort { $0.date < $1.date }
                    }
                }
            } else if category == .fitness {
                // Fetch fitness data
                HealthData.shared.getFitnessWatchScore(for: date) { score in
                    DispatchQueue.main.async {
                        let dataPoint = SleepData(date: date, quality: score * 100)
                        chartData.append(dataPoint)
                        chartData.sort { $0.date < $1.date }
                    }
                }
            }
        }
    }

    // Check if the given date is today's date
    func isToday(date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }

    // Format date as needed (e.g., "Sep 15")
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Day format
        return formatter.string(from: date)
    }
}