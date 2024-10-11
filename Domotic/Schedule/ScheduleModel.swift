//
//  LEDControlSchedule.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 10/10/2024.
//

import Foundation

struct LEDControlSchedule: Identifiable, Codable {
    var id = UUID()
    var start: String
    var end: String
    var action: String // On ou Off
    var led: String    // LED associée (LED1, LED2, ou ALL)
    var isEnabled: Bool // Plage activée ou désactivée
}
