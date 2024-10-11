//
//  ScheduleManager.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 10/10/2024.
//

import Foundation
import SwiftUI
import Combine

class ScheduleManager {
    static let shared = ScheduleManager()
    let userDefaultsKey = "schedules"
    private var timer: Timer?
    private var currentLEDState: [String: Bool] = ["LED1": false, "LED2": false]
    private var led1StateChanged = false
    private var led2StateChanged = false

    // Sauvegarder les plages horaires
    func saveSchedules(_ schedules: [LEDControlSchedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Erreur lors de l'encodage des plages horaires : \(error)")
        }
    }

    // Récupérer les plages horaires
    func loadSchedules() -> [LEDControlSchedule] {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let schedules = try JSONDecoder().decode([LEDControlSchedule].self, from: data)
                return schedules
            } catch {
                print("Erreur lors du décodage des plages horaires : \(error)")
            }
        }
        return []
    }

    // Lancer le processus de surveillance des plages horaires à l'heure exacte
    func startScheduleExecution(mqttManager: MQTTManager) {
        // Annuler l'ancien timer s'il existe
        timer?.invalidate()

        // Calculer combien de secondes il reste avant la minute suivante
        let now = Date()
        let calendar = Calendar.current
        let secondsToNextMinute = 60 - calendar.component(.second, from: now)

        // Démarrer un nouveau timer qui s'exécute à chaque début de minute
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secondsToNextMinute)) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                self.executeSchedules(mqttManager: mqttManager)
            }
            RunLoop.current.add(self.timer!, forMode: .common)
            self.executeSchedules(mqttManager: mqttManager) // Exécuter immédiatement pour la première vérification
        }
    }

    // Exécuter les actions des plages horaires
    private func executeSchedules(mqttManager: MQTTManager) {
        let schedules = loadSchedules()
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let currentTimeString = formatter.string(from: now)
        print("Heure actuelle : \(currentTimeString)")

        for schedule in schedules where schedule.isEnabled {  // Vérification du champ isEnabled
            guard let startTime = formatter.date(from: schedule.start),
                  let endTime = formatter.date(from: schedule.end) else {
                continue
            }

            // Si on est à l'heure de début et que l'action n'a pas encore été exécutée
            if currentTimeString == schedule.start {
                if schedule.led == "LED1" && !led1StateChanged {
                    handleLightAction(mqttManager: mqttManager, led: "LED1", action: schedule.action)
                    led1StateChanged = true
                    sendNotification(title: "Début de la plage horaire", body: "Plage horaire de \(schedule.start) à \(schedule.end), Action \(schedule.action)")
                } else if schedule.led == "LED2" && !led2StateChanged {
                    handleLightAction(mqttManager: mqttManager, led: "LED2", action: schedule.action)
                    led2StateChanged = true
                    sendNotification(title: "Début de la plage horaire", body: "Plage horaire de \(schedule.start) à \(schedule.end), Action \(schedule.action)")
                } else if schedule.led == "ALL" {
                    if !led1StateChanged { handleLightAction(mqttManager: mqttManager, led: "LED1", action: schedule.action) }
                    if !led2StateChanged { handleLightAction(mqttManager: mqttManager, led: "LED2", action: schedule.action) }
                    led1StateChanged = true
                    led2StateChanged = true
                    sendNotification(title: "Début de la plage horaire", body: "Plage horaire de \(schedule.start) à \(schedule.end), Action \(schedule.action)")
                }
            }

            // Si on est à l'heure de fin et qu'il faut remettre l'état à OFF
            if currentTimeString == schedule.end {
                if schedule.led == "LED1" && led1StateChanged {
                    mqttManager.publish(topic: "sae301/led", message: "LED_OFF")
                    led1StateChanged = false
                    sendNotification(title: "Fin de la plage horaire", body: "Fin de la plage horaire de \(schedule.start) à \(schedule.end), remis à l'état initial.")
                } else if schedule.led == "LED2" && led2StateChanged {
                    mqttManager.publish(topic: "sae301_2/led", message: "LED_OFF")
                    led2StateChanged = false
                    sendNotification(title: "Fin de la plage horaire", body: "Fin de la plage horaire de \(schedule.start) à \(schedule.end), remis à l'état initial.")
                } else if schedule.led == "ALL" {
                    if led1StateChanged { mqttManager.publish(topic: "sae301/led", message: "LED_OFF") }
                    if led2StateChanged { mqttManager.publish(topic: "sae301_2/led", message: "LED_OFF") }
                    led1StateChanged = false
                    led2StateChanged = false
                    sendNotification(title: "Fin de la plage horaire", body: "Fin de la plage horaire de \(schedule.start) à \(schedule.end), remis à l'état initial.")
                }
            }
        }
    }

    // Fonction pour gérer l'action de la lumière
    private func handleLightAction(mqttManager: MQTTManager, led: String, action: String) {
        let topic = led == "LED1" ? "sae301/led" : "sae301_2/led"
        let message = action == "On" ? "LED_ON" : "LED_OFF"
        mqttManager.publish(topic: topic, message: message)
    }

    // Notification pour le début et la fin des plages horaires
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'ajout de la notification: \(error.localizedDescription)")
            }
        }
    }
}
