//
//  LoginView.swift
//  Shasu
//
//  Created by Ali Erdem Kökcik on 29.01.2023.
//

import SwiftUI
import PhotosUI // Native swiftUI image picker
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    // MARK: - User Details
    @State var emailID: String = ""
    @State var password: String = ""
    // MARK: - View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: - User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10){
            Text("Let's sign you in to the Shasu!")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome back, User")
                .font(.title3)
                .hAlign(.leading)
            VStack(spacing: 12){
                // MARK: - TextField and SecureField group
                Group{
                    TextField("Email", text: $emailID)
                        .textContentType(.emailAddress)
                        .border(1, .gray.opacity(0.5))
                        .padding(.top, 25)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .border(1, .gray.opacity(0.5))
                }
                // MARK: - Reset Password
                Button("Reset password", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                Button(action: loginUser){
                    // MARK: Login Button
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)
            }
            // MARK: - Register button
            HStack{
                Text("Don't have an account?")
                Button("Register"){
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // MARK: - Register view via sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        // MARK: - Displaying alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    // MARK: - Login user function
    func loginUser(){
        isLoading = true
        Task{
            do {
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User found.")
                try await fetchUser()
            } catch {
               await setError(error)
            }
        }
    }
    // MARK: - If user exists, then fetching data from firestore
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        await MainActor.run(body: {
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    // MARK: - Reset password function
    func resetPassword() {
        Task{
            do {
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("A link to reset your password is sent to your e-mail.")
            } catch {
               await setError(error)
            }
        }
    }
    // MARK: - Displaying errors via alert
    func setError(_ error: Error) async {
        // MARK: - Update UI on main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

