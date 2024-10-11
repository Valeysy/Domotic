//
//  LoginView.swift
//  Domotic
//
//  Created by Vladimir Nechaev on 07/10/2024.
//

import SwiftUI
import ColorfulX
import MetalKit

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            AnimatedGradientView(colors: [.blue, .cyan, .white],
            speed: 0.5,
            noise: 1,
            transitionSpeed: 15)
            .ignoresSafeArea(edges: .all)

            VStack {
                Spacer()

                Text("DOMOTIC")
                    .foregroundColor(.white)
                    .font(Font.custom("SF Pro", size: 45))
                    .fontWeight(.medium)
                    .padding(.bottom, 30)
                    .shadow(
                        color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 50
                      )

                if isLoading {
                    ProgressView()
                        .padding(.bottom, 30)
                        .tint(.white)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom, 30)
                } else {
                    Text("Veuillez saisir vos identifiants")
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                        .font(.title3)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 50
                          )
                }

                ZStack(alignment: .leading) {
                    if username.isEmpty {
                        Text("Utilisateur")
                            .foregroundColor(Color.white)
                            .padding(.leading, 15)
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.45), radius: 50)
                    }

                    TextField("", text: $username)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)


                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text("Mot de passe")
                            .foregroundColor(Color.white)
                            .padding(.leading, 15)
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.45), radius: 50)
                    }

                    SecureField("", text: $password)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)

                Button(action: {
                    UIApplication.shared.endEditing(true)
                    authenticateUser()
                }) {
                    Text("Se connecter")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(100)
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding(.horizontal, 25)

        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Login")
    }

    func authenticateUser() {
        errorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            if username == "Pi" && password == "pi" {
                withAnimation {
                    isAuthenticated = true
                    UserDefaults.standard.set(true, forKey: "isAuthenticated")
                }
            } else {
                errorMessage = "Nom d'utilisateur ou mot de passe incorrect."
            }
        }
    }
}


struct AnimatedGradientView: UIViewRepresentable {
    let colors: [UIColor]
    let speed: Double
    let noise: CGFloat
    let transitionSpeed: Double // Nouveau paramètre pour la vitesse de transition
    
    func makeUIView(context: Context) -> AnimatedMulticolorGradientView {
        let gradientView = AnimatedMulticolorGradientView()
        gradientView.setColors(colors, animated: true) // Active l'animation
        gradientView.speed = speed
        gradientView.noise = noise
        gradientView.transitionSpeed = transitionSpeed // Applique la vitesse de transition
        return gradientView
    }
    
    func updateUIView(_ uiView: AnimatedMulticolorGradientView, context: Context) {
        uiView.setColors(colors, animated: true)
        uiView.speed = speed
        uiView.noise = noise
        uiView.transitionSpeed = transitionSpeed // Met à jour la vitesse de transition
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isAuthenticated: .constant(false)) // Preview avec état déconnecté
    }
}
