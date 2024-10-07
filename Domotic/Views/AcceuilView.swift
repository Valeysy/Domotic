//
//  AcceuilView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import SwiftUI
import UserNotifications

struct AcceuilView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var mqttManager = MQTTManager.shared

    @State private var isBothLEDsOn: Bool = UserDefaults.standard.bool(forKey: "isBothLEDsOn")

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Prises")
                        .font(.title)

                    Spacer()

                    Text("🌡️ \(mqttManager.getTemperatureString())")
                        .font(.title3)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        // Prise 1
                        NavigationLink(destination: EtatView(title: "Prise 1", isOn: $mqttManager.isLED1On, mqttManager: mqttManager)) {
                            LedControlRow(
                                title: "Prise 1",
                                isOn: $mqttManager.isLED1On,
                                actionOn: {
                                    mqttManager.handleLight(action: "lumiere1_on")
                                    saveLEDState(key: "isLED1On", value: true)
                                },
                                actionOff: {
                                    mqttManager.handleLight(action: "lumiere1_off")
                                    saveLEDState(key: "isLED1On", value: false)
                                }
                            )
                            .frame(width: 370)
                        }

                        // Prise 2
                        NavigationLink(destination: EtatView(title: "Prise 2", isOn: $mqttManager.isLED2On, mqttManager: mqttManager)) {
                            LedControlRow(
                                title: "Prise 2",
                                isOn: $mqttManager.isLED2On,
                                actionOn: {
                                    mqttManager.handleLight(action: "lumiere2_on")
                                    saveLEDState(key: "isLED2On", value: true)
                                },
                                actionOff: {
                                    mqttManager.handleLight(action: "lumiere2_off")
                                    saveLEDState(key: "isLED2On", value: false)
                                }
                            )
                            .frame(width: 370)
                        }

                        // Prises 1/2
                        LedControlRowTwoButtons(
                            title: "Prises 1/2",
                            isOn: $isBothLEDsOn,
                            actionOn: {
                                mqttManager.handleLight(action: "lumiere1_on")
                                mqttManager.handleLight(action: "lumiere2_on")
                                mqttManager.isLED1On = true
                                mqttManager.isLED2On = true
                                saveLEDState(key: "isLED1On", value: true)
                                saveLEDState(key: "isLED2On", value: true)
                            },
                            actionOff: {
                                mqttManager.handleLight(action: "lumiere1_off")
                                mqttManager.handleLight(action: "lumiere2_off")
                                mqttManager.isLED1On = false
                                mqttManager.isLED2On = false
                                saveLEDState(key: "isLED1On", value: false)
                                saveLEDState(key: "isLED2On", value: false)
                            }
                        )
                        .frame(width: 370)
                    }
                    .padding()
                }
                .onAppear {
                    requestNotificationPermissions()
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                    UNUserNotificationCenter.current().setBadgeCount(0) { error in
                        if let error = error {
                            print("Erreur lors de la réinitialisation du badge: \(error.localizedDescription)")
                        }
                    }
                    
                    mqttManager.connect() // Connexion MQTT
                }

                Spacer()

                // Bouton Power en bas
                Button(action: {
                    toggleBothLEDs()
                }) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor((mqttManager.isLED1On && mqttManager.isLED2On) ? .blue : .gray.opacity(0.5))
                }
                .padding(.bottom, 50)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                withAnimation {
                    isAuthenticated = false
                    mqttManager.disconnect()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Déconnexion")
                }
                .foregroundColor(.red)
            })
        }
    }

    // Fonction pour envoyer des notifications locales
    func sendNotification(title: String, body: String) {
        // Création du contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default  // Son par défaut
        content.badge = NSNumber(value: 1)  // Met à jour le badge (pastille)

        // Affiche un log dans la console pour vérifier si la fonction est bien appelée
        print("Envoi d'une notification: \(title) - \(body)")

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
    
    func toggleBothLEDs() {
        if mqttManager.isLED1On && mqttManager.isLED2On {
            mqttManager.handleLight(action: "all_off")
            mqttManager.isLED1On = false
            mqttManager.isLED2On = false
            saveLEDState(key: "isLED1On", value: false)
            saveLEDState(key: "isLED2On", value: false)
        } else {
            mqttManager.handleLight(action: "all_on")
            mqttManager.isLED1On = true
            mqttManager.isLED2On = true
            saveLEDState(key: "isLED1On", value: true)
            saveLEDState(key: "isLED2On", value: true)
        }
        isBothLEDsOn = mqttManager.isLED1On && mqttManager.isLED2On
    }


// Le reste de votre code (LedControlRow, LedControlRowTwoButtons, etc.) reste inchangé



    
    // Function to save the LED state in UserDefaults
    func saveLEDState(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    // Demande d'autorisation pour les notifications
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Autorisation des notifications accordée")
            } else if let error = error {
                print("Erreur lors de la demande d'autorisation des notifications : \(error.localizedDescription)")
            } else {
                print("Autorisation des notifications refusée")
            }
        }
    }
}


// MARK: - LED Control Row Component
struct LedControlRow: View {
    var title: String
    @Binding var isOn: Bool
    var actionOn: () -> Void
    var actionOff: () -> Void
    
    var body: some View {
        HStack {
            // LED name and icon
            Label {
                Text(title)
                    .foregroundColor(.black)
                    .font(.title2)
            } icon: {
            }
            
            Spacer()
            
            // Power button
            Button(action: {
                if isOn {
                    actionOff()
                } else {
                    actionOn()
                }
                isOn.toggle() // Toggle the state of the LED
            }) {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isOn ? .blue : .gray.opacity(0.5))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

// MARK: - LED Control Row with Two Buttons
struct LedControlRowTwoButtons: View {
    var title: String
    @Binding var isOn: Bool
    var actionOn: () -> Void
    var actionOff: () -> Void

    var body: some View {
        HStack {
            // On Button
            Button(action: {
                actionOn()
                isOn = true
            }) {
                Text("On")
                    .font(.system(size: 18))
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(100)
            }
            .padding(.trailing, 8)

            // Off Button
            Button(action: {
                actionOff()
                isOn = false
            }) {
                Text("Off")
                    .font(.system(size: 18))
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(100)
            }
        }
    }
}

struct AcceuilView_Previews: PreviewProvider {
    static var previews: some View {
        // Désactiver la connexion MQTT lors de la preview pour éviter des problèmes
        AcceuilView(isAuthenticated: .constant(true))
    }
}


