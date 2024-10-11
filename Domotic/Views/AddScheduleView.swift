//
//  AddScheduleView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 09/10/2024.
//

import SwiftUI

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var schedules: [LEDControlSchedule]
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var action = "On"
    var selectedLED: String
    var editingSchedule: LEDControlSchedule? = nil // Plage horaire à modifier
    
    // Initialiseur personnalisé
    init(schedules: Binding<[LEDControlSchedule]>, selectedLED: String, editingSchedule: LEDControlSchedule? = nil) {
        self._schedules = schedules
        self.selectedLED = selectedLED
        if let editingSchedule = editingSchedule {
            // Pré-remplir les données si une plage est à modifier
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            _startTime = State(initialValue: formatter.date(from: editingSchedule.start) ?? Date())
            _endTime = State(initialValue: formatter.date(from: editingSchedule.end) ?? Date())
            _action = State(initialValue: editingSchedule.action)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("\(selectedLED)") // Corrigé : Utilisation de l'interpolation de la variable
                    Spacer()
                }
                Section {
                    
                    // Sélection de l'heure de début
                    HStack {
                        Text("Heure de début")
                        Spacer()
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    // Sélection de l'heure de fin
                    HStack {
                        Text("Heure de fin")
                        Spacer()
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    // Action à effectuer (On/Off)
                    HStack {
                        Text("Action")
                        Spacer()
                        Picker("", selection: $action) {
                            Text("On").tag("On")
                            Text("Off").tag("Off")
                        }
                    }
                }
            }
            .navigationTitle(editingSchedule == nil ? "Plage Horaire" : "Modifier Plage Horaire")
            
            .navigationBarItems(
                leading: Button("Annuler") {
                    dismiss()
                },
                trailing: Button(editingSchedule == nil ? "Ajouter" : "Sauvegarder") {
                    saveSchedule()
                }
            )
        }
    }
    
    // Fonction pour ajouter ou modifier une plage horaire
    private func saveSchedule() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let editingSchedule = editingSchedule {
            // Modifier la plage existante
            if let index = schedules.firstIndex(where: { $0.id == editingSchedule.id }) {
                schedules[index].start = formatter.string(from: startTime)
                schedules[index].end = formatter.string(from: endTime)
                schedules[index].action = action
            }
        } else {
            // Ajouter une nouvelle plage
            let newSchedule = LEDControlSchedule(
                start: formatter.string(from: startTime),
                end: formatter.string(from: endTime),
                action: action,
                led: selectedLED,
                isEnabled: true
            )
            schedules.append(newSchedule)
        }
        
        ScheduleManager.shared.saveSchedules(schedules) // Sauvegarder après ajout ou modification
        dismiss() // Fermer la vue
    }
}

// Preview pour AddScheduleView
struct AddScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        AddScheduleView(schedules: .constant([]), selectedLED: "LED1")
            .previewLayout(.sizeThatFits)
    }
}
