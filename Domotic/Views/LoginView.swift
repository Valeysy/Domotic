import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false  // Pour afficher le loader
    @State private var errorMessage: String? = nil  // Message d'erreur
    @State private var offset: CGFloat = 0  // Gérer l'offset avec le clavier

    var body: some View {
        VStack {
            Spacer()
            
            Text("Domotic")
                .font(.largeTitle)
                .padding(.bottom, 40)
            
            TextField("Utilisateur", text: $username)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.bottom, 20)

            SecureField("Mot de passe", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.bottom, 30)

            if isLoading {
                ProgressView()
                    .padding(.bottom, 30)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 30)
            }

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
                    .cornerRadius(10)
            }
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .offset(y: -offset)  // Déplacer la vue en fonction du clavier
        .onAppear {
            // Observer l'apparition du clavier
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation {
                        self.offset = keyboardSize.height / 2
                    }
                }
            }

            // Observer la disparition du clavier
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    self.offset = 0
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)  // Nettoyer les observateurs
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isAuthenticated: .constant(false)) // Preview avec état déconnecté
    }
}
