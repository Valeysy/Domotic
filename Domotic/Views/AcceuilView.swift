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
    @State private var showMenu = false  
    @State private var isBothLEDsOn: Bool = UserDefaults.standard.bool(forKey: "isBothLEDsOn")

    var body: some View {
        
        NavigationView {
            VStack {
                // Haut de l'écran avec température et prise
                HStack {
                    Text("Prises")
                        .font(.title)

                    Spacer()

                    Text("🌡️ \(mqttManager.getTemperatureString())")
                        .font(.title3)
                }
                .padding()

                // Liste des contrôles de prises
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
                            .frame(width: 360)
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
                            .frame(width: 360)
                        }
                    }
                }
                .onAppear {
                    requestNotificationPermissions()
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                    UNUserNotificationCenter.current().setBadgeCount(0) { error in
                        if let error = error {
                            print("Erreur lors de la réinitialisation du badge: \(error.localizedDescription)")
                        }
                    }
                    ScheduleManager.shared.startScheduleExecution(mqttManager: mqttManager)
                    mqttManager.connect() // Connexion MQTT
                }

                Spacer()

                Button(action: {
                    toggleBothLEDs()
                }) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor((mqttManager.isLED1On && mqttManager.isLED2On) ? .blue : Color("GrayLight"))
                }
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 100))
                .contextMenu {
                    Button("Allumer") {
                        mqttManager.handleLight(action: "all_on")
                    }
                    Button("Éteindre") {
                        mqttManager.handleLight(action: "all_off")
                    }
                }
                .onLongPressGesture {
                    // Haptic feedback lors de la pression longue
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showMenu.toggle()
                }
                ForEach(0..<5) { _ in
                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                withAnimation(.easeInOut) {
                    isAuthenticated = false
                    mqttManager.disconnect()
                    UserDefaults.standard.set(false, forKey: "isAuthenticated")
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

    func saveLEDState(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
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
                    .foregroundColor(isOn ? .blue : Color("GrayLight"))
            }
        }
        .padding()
        .background(
             LinearGradient(gradient: Gradient(colors: [Color(red: 0.89, green: 0.92, blue: 1), Color(red: 0.94, green: 0.95, blue: 1)]), startPoint: .leading, endPoint: .trailing)
           )
        .cornerRadius(15)
    }
}

struct AcceuilView_Previews: PreviewProvider {
    static var previews: some View {
        // Désactiver la connexion MQTT lors de la preview pour éviter des problèmes
        AcceuilView(isAuthenticated: .constant(true))
    }
}


