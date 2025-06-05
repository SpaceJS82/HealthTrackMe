//
//  ParameterObject.swift
//  CitrusWatch Watch App
//
//  Created by Luka Verč on 30. 9. 24.
//

import SwiftUI

struct ParameterObject: Identifiable {
    var id = UUID()
    
    let icon: Image?
    let title: String
    let description: String
}
