//
//  EtatView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import SwiftUI

struct EtatView: View {
    var title: String
    @Binding var isOn: Bool
    @ObservedObject var mqttManager: MQTTManager
    @State private var showAddSchedule = false
    @State private var showEditSchedule = false
    @State private var editingSchedule: LEDControlSchedule? = nil // Gérer la modification
    @State private var schedules: [LEDControlSchedule] = ScheduleManager.shared.loadSchedules()

    var body: some View {
        VStack {
            // Titre de la vue (Prise 1 ou Prise 2)
            Text(title)
                .font(.title)
                .padding(.top, 50)

            // Bouton principal pour allumer/éteindre la prise
            Button(action: {
                toggleLED()
            }) {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: 150))
                    .foregroundColor(isOn ? .blue : Color("GrayLight"))
                    .padding(50)
            }

            // Section des plages horaires avec le bouton pour ajouter une nouvelle plage
            HStack {
                Text("Horaire")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.8))
                Spacer()
                Button(action: {
                    showAddSchedule.toggle() // Ajouter une nouvelle plage
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)

            // Liste des plages horaires avec le toggle pour activer/désactiver
            List {
                ForEach($schedules) { $schedule in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(schedule.start) - \(schedule.end)")
                                .font(.subheadline)
                            Text("Action: \(schedule.action)")
                                .font(.subheadline)
                        }
                        Spacer()
                        Toggle(isOn: $schedule.isEnabled) {
                        }
                        .onChange(of: schedule.isEnabled) {
                            ScheduleManager.shared.saveSchedules(schedules)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .swipeActions {
                        Button("Modifier") {
                            editingSchedule = schedule // Plage horaire à modifier
                            showEditSchedule = true // Ouvrir EditScheduleView pour modification
                        }
                        .tint(.blue)

                        Button("Supprimer", role: .destructive) {
                            deleteSchedule(schedule: schedule)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())

            Spacer()
        }
        .sheet(isPresented: $showAddSchedule) {
            AddScheduleView(schedules: $schedules, selectedLED: title == "Prise 1" ? "LED1" : "LED2")
        }
        // Vue pour modifier une plage horaire existante
        .sheet(isPresented: $showEditSchedule) {
            if let editingSchedule = editingSchedule {
                EditScheduleView(schedules: $schedules, editingSchedule: editingSchedule)
            }
        }
        .onAppear {
            // Restaurer les plages horaires à partir de UserDefaults
            schedules = ScheduleManager.shared.loadSchedules()
            // Démarrer la surveillance des plages horaires
            ScheduleManager.shared.startScheduleExecution(mqttManager: mqttManager)
        }
        .onDisappear {
            // Sauvegarder les plages horaires lorsque la vue disparaît
            ScheduleManager.shared.saveSchedules(schedules)
        }
    }

    // Fonction pour basculer l'état de la prise (LED1 ou LED2)
    func toggleLED() {
        if title == "Prise 1" {
            mqttManager.isLED1On.toggle()
            if mqttManager.isLED1On {
                mqttManager.handleLight(action: "lumiere1_on")
                mqttManager.saveLEDState(key: "isLED1On", value: true)
            } else {
                mqttManager.handleLight(action: "lumiere1_off")
                mqttManager.saveLEDState(key: "isLED1On", value: false)
            }
        } else if title == "Prise 2" {
            mqttManager.isLED2On.toggle()
            if mqttManager.isLED2On {
                mqttManager.handleLight(action: "lumiere2_on")
                mqttManager.saveLEDState(key: "isLED2On", value: true)
            } else {
                mqttManager.handleLight(action: "lumiere2_off")
                mqttManager.saveLEDState(key: "isLED2On", value: false)
            }
        }
        isOn.toggle()
    }

    // Fonction pour supprimer une plage horaire
    func deleteSchedule(schedule: LEDControlSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules.remove(at: index)
            ScheduleManager.shared.saveSchedules(schedules) // Sauvegarder après suppression
        }
    }
}


// Preview pour EtatView
struct EtatView_Previews: PreviewProvider {
    static var previews: some View {
        let isOnBinding = Binding.constant(true) // Prise allumée pour le preview

        return NavigationView {
            EtatView(
                title: "Prise 1",
                isOn: isOnBinding, 
                mqttManager: MQTTManager.shared // Instance partagée de MQTTManager
            )
        }
        .previewLayout(.sizeThatFits) // Adapter la taille du preview à la vue
    }
}
