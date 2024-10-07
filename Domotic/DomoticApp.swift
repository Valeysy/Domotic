//
//  DomoticApp.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import SwiftUI
import UserNotifications


@main
struct DomoticApp: App {
    init() {
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
            requestNotificationPermissions()
        }
    var body: some Scene {
        WindowGroup {
            AppNavigator()
        }
    }
    func requestNotificationPermissions() {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
              // Gérer la réponse de l'utilisateur
          }
      }
  }



struct AppNavigator: View {
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    @State private var showLogin = true
    @State private var showLoading = false
    
    var body: some View {
        ZStack {
            if isAuthenticated && !showLoading {
                AcceuilView(isAuthenticated: $isAuthenticated)
                    .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity)) // Transition améliorée
                    .animation(.easeInOut(duration: 0.3), value: isAuthenticated) //
            
            }
            if showLogin && !isAuthenticated {
                LoginView(isAuthenticated: $isAuthenticated)
                    .transition(.scale(scale: 0.8).combined(with: .opacity)) // Dézoom avec fade
                    .animation(.easeInOut(duration: 0.2), value: showLogin)
            }
        }
    }
}
