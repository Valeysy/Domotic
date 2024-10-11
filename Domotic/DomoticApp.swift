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
            AppNavigator() // Lancer la navigation dans AppNavigator
            .preferredColorScheme(.light)
        }
    }

    // Demander les autorisations de notification
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Gérer la réponse de l'utilisateur si besoin
        }
    }
}


struct AppNavigator: View {
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated") // Vérifier l'état de connexion sauvegardé

    var body: some View {
        ZStack {
            if isAuthenticated {
                AcceuilView(isAuthenticated: $isAuthenticated)
                    .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity)) // Transition fluide vers l'Accueil
                    .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
                    .transition(.scale(scale: 0.8).combined(with: .opacity)) // Animation fluide vers le Login
                    .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
            }
        }
        .onAppear {
            isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated") // Mettre à jour l'état à l'apparition
        }
    }
}


