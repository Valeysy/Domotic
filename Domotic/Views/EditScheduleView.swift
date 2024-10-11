//
//  EditScheduleView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 11/10/2024.
//

import SwiftUI

struct EditScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var schedules: [LEDControlSchedule]
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var action = "On"
    var editingSchedule: LEDControlSchedule
    
    // Initialiser les données existantes
    init(schedules: Binding<[LEDControlSchedule]>, editingSchedule: LEDControlSchedule) {
        self._schedules = schedules
        self.editingSchedule = editingSchedule

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        _startTime = State(initialValue: formatter.date(from: editingSchedule.start) ?? Date())
        _endTime = State(initialValue: formatter.date(from: editingSchedule.end) ?? Date())
        _action = State(initialValue: editingSchedule.action)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Modifier Plage Horaire")) {
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
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .navigationTitle("Modifier Plage Horaire")
            .navigationBarItems(
                leading: Button("Annuler") {
                    dismiss()
                },
                trailing: Button("Apply Changes") {
                    applyChanges()
                }
            )
        }
    }

    // Fonction pour appliquer les modifications
    private func applyChanges() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if let index = schedules.firstIndex(where: { $0.id == editingSchedule.id }) {
            schedules[index].start = formatter.string(from: startTime)
            schedules[index].end = formatter.string(from: endTime)
            schedules[index].action = action
        }

        ScheduleManager.shared.saveSchedules(schedules) // Sauvegarder après modification
        dismiss() // Fermer la vue
    }
}
