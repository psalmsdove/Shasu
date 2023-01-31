//
//  ProfileView.swift
//  Shasu
//
//  Created by Ali Erdem Kökcik on 29.01.2023.
//

import Firebase
import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    // MARK: - Profile data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // MARK: - View properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    // MARK: - Body
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: - Refresh user data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // MARK: - Log Out
                        Button("Log out", action: logOutUser)
                        // MARK: - Delete account
                        Button("Delete account", role: .destructive, action: deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError){
            
        }
        .task {
            // MARK: - Initial fetch
            if myProfile != nil { return }
            await fetchUserData()
        }
    }
    // MARK: - Fetching user data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else { return }
        await MainActor.run(body: {
            myProfile = user
        })
    }
    // MARK: - Logging user out
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    // MARK: - Delete account
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                // Deleting profile image from the database
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Deleting firestore user document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Deleting auth account and settings log status to false
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch{
                await setError(error)
            }
        }
    }
    // MARK: - Settings error
    func setError(_ error: Error)async{
        // MARK: - Run UI on main thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
