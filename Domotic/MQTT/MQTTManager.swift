//
//  MQTTManager.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import Foundation
import CocoaMQTT
import Combine
import UserNotifications

class MQTTManager: NSObject, ObservableObject {
    static let shared = MQTTManager()
    private var hasSentTemperatureAlert = false
    private var mqttClient: CocoaMQTT!
    private let broker = "broker.id00l.eu"
    private let port: UInt16 = 14022
    private let username = "serveur-rpi"
    @Published var lastTemp: Double?
    @Published var isConnected: Bool = false
    @Published var isLED1On: Bool = UserDefaults.standard.bool(forKey: "isLED1On")
    @Published var isLED2On: Bool = UserDefaults.standard.bool(forKey: "isLED2On")
       
    
    override init() {
        super.init()
        setupMQTT()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    func saveLEDState(key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
            
    
    // MARK: - MQTT Setup
    private func setupMQTT() {
        let clientID = "iOSClient-\(UUID().uuidString)"
        mqttClient = CocoaMQTT(clientID: clientID, host: broker, port: port)
        mqttClient.username = username
        mqttClient.keepAlive = 60
        mqttClient.autoReconnect = true
        mqttClient.allowUntrustCACertificate = true
        mqttClient.didConnectAck = { [weak self] _, ack in
            self?.handleConnectAck(ack: ack)
        }
        
        mqttClient.didReceiveMessage = { [weak self] _, message, _ in
            self?.handleReceivedMessage(message: message)
        }
        
        mqttClient.didDisconnect = { [weak self] _, error in
            self?.handleDisconnect(error: error)
        }
        
        mqttClient.didSubscribeTopics = { mqttClient, response, topics in
            print("Subscribed to topics: \(topics)")
        }
        
        mqttClient.didUnsubscribeTopics = { _, topics in
            print("Unsubscribed from topics: \(topics)")
        }
    }

    func connect() {
        mqttClient.connect()
    }
    
    func disconnect() {
        mqttClient.disconnect()
    }
    
    // MARK: - MQTT Actions
    func publish(topic: String, message: String) {
        mqttClient.publish(topic, withString: message)
        print("Published message '\(message)' to topic '\(topic)'")
    }
    
    func subscribe(topic: String) {
        mqttClient.subscribe(topic)
        print("Subscribed to topic '\(topic)'")
    }
    
    func unsubscribe(topic: String) {
        mqttClient.unsubscribe(topic)
        print("Unsubscribed from topic '\(topic)'")
    }
    
    // MARK: - LED Control
    func handleLight(action: String) {
        let ledTopic1 = "sae301/led"
        let ledTopic2 = "sae301_2/led"
        
        switch action {
        case "lumiere1_on":
            publish(topic: ledTopic1, message: "LED_ON")
        case "lumiere1_off":
            publish(topic: ledTopic1, message: "LED_OFF")
        case "lumiere2_on":
            publish(topic: ledTopic2, message: "LED_ON")
        case "lumiere2_off":
            publish(topic: ledTopic2, message: "LED_OFF")
        case "all_on":
            publish(topic: ledTopic1, message: "LED_ON")
            publish(topic: ledTopic2, message: "LED_ON")
        case "all_off":
            publish(topic: ledTopic1, message: "LED_OFF")
            publish(topic: ledTopic2, message: "LED_OFF")
        default:
            print("Unknown action: \(action)")
        }
    }
    
    // MARK: - Handle Connection Acknowledgement
    private func handleConnectAck(ack: CocoaMQTTConnAck) {
        if ack == .accept {
            print("Connexion au broker réussie :)")
            isConnected = true
            subscribe(topic: "sae301/led")
            subscribe(topic: "sae301_2/led")
            subscribe(topic: "sae301/temperature")
            subscribe(topic: "sae301/alert")
        } else {
            print("Erreur de connexion: \(ack)")
            isConnected = false
        }
    }
    
    
    // MARK: - Handle MQTT Messages
        private func handleReceivedMessage(message: CocoaMQTTMessage) {
            let payload = message.string ?? ""
            print("\(username): \(message.topic): \(payload)")
            
            DispatchQueue.main.async {
                if message.topic == "sae301/temperature" {
                        if let tempValue = Double(payload) {
                            DispatchQueue.main.async {
                                self.lastTemp = tempValue
                            }
                        } else {
                            print("Impossible de parser la température : \(payload)")
                        }
                    }
                if message.topic == "sae301/led" {
                    if payload == "LED_ON" {
                        self.isLED1On = true
                        self.sendNotification(title: "Prise 1", body: "La prise 1 est allumée.")
                    } else if payload == "LED_OFF" {
                        self.isLED1On = false
                        self.sendNotification(title: "Prise 1", body: "La prise 1 est éteinte.")
                    }
                } else if message.topic == "sae301_2/led" {
                    if payload == "LED_ON" {
                        self.isLED2On = true
                        self.sendNotification(title: "Prise 2", body: "La prise 2 est allumée.")
                    } else if payload == "LED_OFF" {
                        self.isLED2On = false
                        self.sendNotification(title: "Prise 2", body: "La prise 2 est éteinte.")
                    }
                } else if message.topic == "sae301/alert" {
                    // Gestion des alertes depuis l'ESP (alertes de température)
                    if payload == "temperature_high" {
                        self.sendTemperatureAlert()
                    }
                }
                
                // Sauvegarder l'état des LEDs
                UserDefaults.standard.set(self.isLED1On, forKey: "isLED1On")
                UserDefaults.standard.set(self.isLED2On, forKey: "isLED2On")
            }
        }
    
    // MARK: - Send Notification
       private func sendNotification(title: String, body: String) {
           let content = UNMutableNotificationContent()
           content.title = title
           content.body = body
           content.sound = UNNotificationSound.default

           let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
           UNUserNotificationCenter.current().add(request) { error in
               if let error = error {
                   print("Erreur lors de l'ajout de la notification: \(error.localizedDescription)")
               }
           }
       }
    
    func giveFeedback(message: String, feedbackTopic: String) {
        publish(topic: feedbackTopic, message: message)
    }
    
    // MARK: - Récupérer la température sous forme de String
    func getTemperatureString() -> String {
        if let temp = lastTemp {
            return String(format: "%.2f°C", temp)
        } else {
            return "Indisponible"
        }
    }

    
    // MARK: - Envoi des notifications de température
    private func sendTemperatureAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Alerte de Température !"
        content.body = "La température dépasse le seuil défini."
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'ajout de la notification : \(error.localizedDescription)")
            } else {
                print("Notification programmée.")
            }
        }
    }
    
    // Gestion de la déconnexion
    private func handleDisconnect(error: Error?) {
        if let error = error {
            print("Déconnexion avec erreur: \(error.localizedDescription)")
        } else {
            print("Déconnexion réussie")
        }
        isConnected = false
    }
}
