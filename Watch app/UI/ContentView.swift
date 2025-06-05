//
//  ContentView.swift
//  CitrusWatch Watch App
//
//  Created by Jaka Volaj on 3. 6. 25.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    
    let wellbeingTab = CategoryView(category: .body)
    let sleepTab = CategoryView(category: .sleep)
    let fitnessTab = CategoryView(category: .fitness)
    let stressTab = CategoryView(category: .stress)
    
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedIndex) {
                wellbeingTab
                    .tag(0)
                
                sleepTab
                    .tag(1)
                
                fitnessTab
                    .tag(2)
                stressTab
                    .tag(3)
                
                VStack {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 50))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.title)
                        .padding(.bottom, 10)
                    
                    Text("More insights available on the iPhone app.".localized())
                        .font(.system(size: 17))
                        .foregroundStyle(.title)
                        .multilineTextAlignment(.center)
                }
                .tag(4)
            }
            .tabViewStyle(.verticalPage)
            .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onOpenURL { url in
                self.handleDeepLink(url)
            }
        }
    }
    
    
    private func handleDeepLink(_ url: URL) {
        // Map the deep link path to the corresponding tab index
        if let tabIndex = deepLinkTabIndex(from: url) {
            selectedIndex = tabIndex
        }
    }
    
    private func deepLinkTabIndex(from url: URL) -> Int? {
        // Check the host or path of the URL to determine the tab
        switch url.host {
        case "Wellbeing":
            return 0 // Tab 0 (Wellbeing)
        case "Sleep":
            return 1 // Tab 1 (Sleep)
        case "Fitness":
            return 2 // Tab 2 (Fitness)
        case "Stress":
            return 3 // Tab 3 (Stress)
        default:
            return nil
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}