//
//  EtatView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import SwiftUI
import UserNotifications // Importer UserNotifications

struct EtatView: View {
    var title: String
    @Binding var isOn: Bool
    @ObservedObject var mqttManager: MQTTManager
    @State private var showAddSchedule = false
    @State private var schedules: [Schedule] = ScheduleManager.shared.loadSchedules() 


    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .padding(.top, 50)

            // Bouton Power qui envoie la même commande que le bouton sur AcceuilView
            Button(action: {
                if title == "Prise 1" {
                    toggleLED1()
                } else if title == "Prise 2" {
                    toggleLED2()
                }
            }) {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: 150))
                    .foregroundColor(isOn ? .blue : .gray.opacity(0.5))
                    .padding(50)
            }

            // Section des horaires
            HStack {
                Text("Horaire")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                Button(action: {
                    showAddSchedule.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)

            // Liste des plages horaires
            List {
                ForEach(schedules) { schedule in
                    HStack {
                        Text("\(schedule.start) - \(schedule.end)")
                        Text(schedule.action)
                        Spacer()
                        Toggle(isOn: $schedules[getScheduleIndex(schedule)].isEnabled) {
                            Text("")
                        }
                        .labelsHidden()
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                }
                .onDelete(perform: deleteSchedule)
            }
            .listStyle(PlainListStyle())

            Spacer()
        }
        .sheet(isPresented: $showAddSchedule) {
            AddScheduleView(schedules: $schedules)
        }
        .onAppear {
            // Restaurer l'état à partir de UserDefaults
            if title == "Prise 1" {
                isOn = mqttManager.isLED1On
            } else if title == "Prise 2" {
                isOn = mqttManager.isLED2On
            }
            // Configurer le délégué des notifications
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        }
        .onDisappear {
            // Sauvegarder les plages horaires à la fermeture
            ScheduleManager.shared.saveSchedules(schedules)
        }
    }

    // Fonction pour basculer l'état de Prise 1 et envoyer la commande correspondante
    func toggleLED1() {
        if mqttManager.isLED1On {
            mqttManager.handleLight(action: "lumiere1_off")
            mqttManager.saveLEDState(key: "isLED1On", value: false)
            sendNotification(title: "Prise 1 éteinte", body: "La prise 1 est éteinte.")
        } else {
            mqttManager.handleLight(action: "lumiere1_on")
            mqttManager.saveLEDState(key: "isLED1On", value: true)
            sendNotification(title: "Prise 1 allumée", body: "La prise 1 est allumée.")
        }
        mqttManager.isLED1On.toggle()
        isOn = mqttManager.isLED1On
    }

    // Fonction pour basculer l'état de Prise 2 et envoyer la commande correspondante
    func toggleLED2() {
        if mqttManager.isLED2On {
            mqttManager.handleLight(action: "lumiere2_off")
            mqttManager.saveLEDState(key: "isLED2On", value: false)
            sendNotification(title: "Prise 2 éteinte", body: "La prise 2 est éteinte.")
        } else {
            mqttManager.handleLight(action: "lumiere2_on")
            mqttManager.saveLEDState(key: "isLED2On", value: true)
            sendNotification(title: "Prise 2 allumée", body: "La prise 2 est allumée.")
        }
        mqttManager.isLED2On.toggle()
        isOn = mqttManager.isLED2On
    }

    // Fonction pour envoyer des notifications locales
    func sendNotification(title: String, body: String) {
        // Création du contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default  // Son par défaut
        content.badge = NSNumber(value: 1)  // Met à jour le badge (pastille)

        // Création d'un déclencheur immédiat pour afficher la notification sans délai
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Crée une requête avec un identifiant unique
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // Ajoute la notification à la file d'attente des notifications
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'ajout de la notification: \(error.localizedDescription)")
            } else {
                print("Notification envoyée avec succès.")
            }
        }
    }

    // Trouver l'index du planning dans le tableau
    func getScheduleIndex(_ schedule: Schedule) -> Int {
        return schedules.firstIndex(where: { $0.id == schedule.id }) ?? 0
    }

    // Supprimer une plage horaire
    func deleteSchedule(at offsets: IndexSet) {
        schedules.remove(atOffsets: offsets)
        ScheduleManager.shared.saveSchedules(schedules)
    }
}

// MARK: - Définition du délégué des notifications

class ScheduleManager {
    static let shared = ScheduleManager()
    let userDefaultsKey = "schedules"

    // Sauvegarder les plages horaires
    func saveSchedules(_ schedules: [Schedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Erreur lors de l'encodage des plages horaires : \(error)")
        }
    }

    // Récupérer les plages horaires
    func loadSchedules() -> [Schedule] {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let schedules = try JSONDecoder().decode([Schedule].self, from: data)
                return schedules
            } catch {
                print("Erreur lors du décodage des plages horaires : \(error)")
            }
        }
        return [] // Retourne un tableau vide si aucune plage horaire n'est enregistrée
    }
}

// Modèle de données pour une plage horaire
struct Schedule: Identifiable, Codable {
    var id = UUID()
    var start: String
    var end: String
    var action: String // On ou Off
    var isEnabled: Bool = false
}

// Preview pour EtatView
struct EtatView_Previews: PreviewProvider {
    static var previews: some View {
        let isOnBinding = Binding.constant(true) // Prise allumée dans ce cas

        return NavigationView {
            EtatView(
                title: "Prise 1", // Exemple de titre pour la prise
                isOn: isOnBinding, // Binding constant pour l'état de la prise
                mqttManager: MQTTManager.shared // Instance partagée de MQTTManager
            )
        }
        .previewLayout(.sizeThatFits) // Adapter la taille du preview à la vue
    }
}
