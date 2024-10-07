//
//  NotificationsManager.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 10/10/2024.
//

import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        // Créer un déclencheur immédiat
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Créer la requête
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // Ajouter la requête au centre de notifications
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'ajout de la notification: \(error.localizedDescription)")
            } else {
                print("Notification envoyée avec succès.")
            }
        }
    }
}
