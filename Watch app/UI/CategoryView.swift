//
//  CategoryView.swift
//  CitrusWatch Watch App
//
//  Created by Jaka Volaj on 4. 6. 25.
//

import SwiftUI
import WatchConnectivity

enum HeathCategory {
    case body
    case sleep
    case fitness
    case stress
}

struct CategoryView: View {
    
    var category: HeathCategory
    
    @State private var color: Color = .secondaryText
    @State private var value: Double = 0
    @State private var title: String = ""
    @State private var imageName: String = "exclamationmark.triangle.fill"
    
    @State private var bottomLabelMessage: String = "No data, tap for Info".localized()
    
    @State private var viewHasData: Bool = false
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                PercentageRing(ringWidth: 15, percent: value * 100, backgroundColor: .secondaryText.opacity(0.3), foregroundColor: color)
                
                // Icon in the center
                Image(systemName: imageName)
                    .font(.system(size: 40))
                    .foregroundColor(.title)
            }
}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            if self.viewHasData {
                if self.category != .stress {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: DetailsView(category: self.category)) {
                            Image(systemName: "chart.bar")
                                .foregroundStyle(Color.title)
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    Text(title)
                        .font(Font.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.title)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 0)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Text(self.bottomLabelMessage)
                    .padding(.top, 20)
                    .font(Font.system(size: 14))
                    .foregroundStyle(Color.secondaryText)
                    .padding(0)
            }
        }
        .containerBackground(self.color.gradient, for: .tabView)
        .alert(isPresented: self.$showAlert) {
            Alert(
                title: Text("iPhone, We Need You!"),
                message: Text("\n\("Your \(self.title) data is almost ready!\nJust open the app on your iPhone, then come back here to see everything!".localized())"),
                dismissButton: .default(Text("Got it".localized())) {
                    self.showAlert = false
                    self.reload()
                }
            )
        }
        
        //Refresh
        .onAppear {
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = PhoneConnectivity.shared
                session.activate()
            }
            
            while PhoneConnectivity.shared.connectivityEstablished == false {
                //Wait
            }
            
            DispatchQueue.main.async {
                self.reload()
            }
        }
        .onTapGesture {
            if !self.viewHasData {
                self.showAlert = true
            } else {
                reload()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
            reload()
        }
    }
    
    func reload() {
        if category == .body {
            
            self.title = "Wellbeing".localized()
            
            HealthData.shared.getBodyWatchScore(for: HealthData.shared.selectedDate) { score in
                DispatchQueue.main.async {
                    self.value = score
                    self.bottomLabelMessage = "\(Int(score * 100)) / 100"
                    if score == 0 {
                        self.color = .secondaryText
                        self.viewHasData = false
                        self.imageName = "exclamationmark.triangle.fill"
                        self.bottomLabelMessage = "No data, tap for Info".localized()
                    } else {
                        self.color = .customOrange
                        self.viewHasData = true
                        self.imageName = "leaf.fill"
                        self.bottomLabelMessage = "\(Int(self.value * 100)) / 100"
                    }
                }
            }
            
        } else if category == .sleep {
            
            self.title = "Sleep".localized()
            
            HealthData.shared.getSleepWatchScore(for: HealthData.shared.selectedDate) { score in
                DispatchQueue.main.async {
                    self.value = score
                    self.bottomLabelMessage = "\(Int(score * 100)) / 100"
                    if score == 0 {
                        self.color = .secondaryText
                        self.viewHasData = false
                        self.imageName = "exclamationmark.triangle.fill"
                        self.bottomLabelMessage = "No data, tap for Info".localized()
                    } else {
                        self.color = .customPurple
                        self.viewHasData = true
                        self.imageName = "moon.zzz.fill"
                        self.bottomLabelMessage = "\(Int(self.value * 100)) / 100"
                    }
                }
            }
            
        } else if category == .fitness {
            
            self.title = "Fitness".localized()
            
            HealthData.shared.getFitnessWatchScore(for: HealthData.shared.selectedDate) { score in
                DispatchQueue.main.async {
                    self.bottomLabelMessage = "\(Int(score * 100)) / 100"
                    self.value = score
                    if score == 0 {
                        self.color = .secondaryText
                        self.viewHasData = false
                        self.imageName = "exclamationmark.triangle.fill"
                        self.bottomLabelMessage = "No data, tap for Info".localized()
                    } else {
                        self.color = .customGreen
                        self.viewHasData = true
                        self.imageName = "figure.run"
                        self.bottomLabelMessage = "\(Int(self.value * 100)) / 100"
                    }
                }
            }
            
        } else if category == .stress {
            
            self.title = "Stress".localized()
            
            HealthData.shared.getStressWatchScore { score in
                DispatchQueue.main.async {
                    self.bottomLabelMessage = "\(Int(score * 100)) / 100"
                    self.value = score
                    if score == 0 {
                        self.color = .secondaryText
                        self.viewHasData = false
                        self.imageName = "exclamationmark.triangle.fill"
                        self.bottomLabelMessage = "No data, tap for Info".localized()
                    } else {
                        self.color = .customBlue
                        self.viewHasData = true
                        self.imageName = "figure.mind.and.body"
                        self.bottomLabelMessage = "\(Int(self.value * 100)) / 100"
                    }
                }
            }
            
        }
    }
}


struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        //CategoryView(category: .sleep)
    }
}