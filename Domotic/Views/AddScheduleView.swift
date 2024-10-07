//
//  AddScheduleView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 09/10/2024.
//

import SwiftUI

// MARK: - Add Schedule View (Sheet)
struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var schedules: [Schedule]
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var action = "On"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ajouter une Plage horaire")) {
                    // Heure de début
                    HStack {
                        Text("Heure de début")
                        Spacer()
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    // Heure de fin
                    HStack {
                        Text("Heure de fin")
                        Spacer()
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    // Action (On/Off)
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
            .navigationTitle("Plage horaire")
            .navigationBarItems(
                leading: Button("Annuler") {
                    dismiss()
                },
                trailing: Button("Ajouter") {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    let newSchedule = Schedule(
                        start: formatter.string(from: startTime),
                        end: formatter.string(from: endTime),
                        action: action,
                        isEnabled: true
                    )
                    schedules.append(newSchedule)
                    ScheduleManager.shared.saveSchedules(schedules) // Sauvegarder après l'ajout
                    dismiss()
                }
            )
        }
    }
}


extension DateFormatter {
    static var shortTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// Enum pour les types de notifications
enum NotificationType: String, CaseIterable {
    case none = "None"
    case state = "État de la prise"
    case schedule = "Plage horaire"
    case both = "État + Plage horaire"

    var description: String {
        switch self {
        case .none:
            return "Aucune"
        case .state:
            return "État de la prise"
        case .schedule:
            return "Plage horaire"
        case .both:
            return "État et Plage horaire"
        }
    }
}

// Preview pour AddScheduleView
struct AddScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        AddScheduleView(schedules: .constant([])) // Exemple de titre pour la prise
            .previewLayout(.sizeThatFits) // Adapter la taille du preview à la vue
    }
}
