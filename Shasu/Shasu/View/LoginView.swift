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

// MARK: - Register view
struct RegisterView: View{
    // MARK: - User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    // MARK: - View properties
    @Environment(\.dismiss) var dismiss // sheet will dismiss itself when clicked on the 'Sign in' button
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: - UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10){
            VStack(spacing: 10){
                Text("Let's register you to the Shasu!")
                    .font(.largeTitle.bold())
                    .hAlign(.leading)
                Text("Hello.")
                    .font(.title3)
                    .hAlign(.leading)
                // MARK: - For smaller screen optimization
                ViewThatFits{
                    ScrollView(.vertical, showsIndicators: false){
                        HelperView()
                    }
                    HelperView()
                }
                // MARK: - Register button
                HStack{
                    Text("Already have an account?")
                    Button("Sign in"){
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                }
                .vAlign(.bottom)
            }
            .vAlign(.top)
            .padding(15)
            .overlay(content:{
                LoadingView(show: $isLoading)
            })
            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            .onChange(of: photoItem) { newValue in
                // MARK: - Extracting uiimage from photoitem
                if let newValue {
                    Task {
                        do {
                            guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                            // MARK: - Update UI on main thread
                            await MainActor.run(body: {
                                userProfilePicData = imageData
                            })
                        } catch {}
                    }
                }
            }
            // MARK: - Displaying alert
            .alert(errorMessage, isPresented: $showError, actions: {})
        }
    }
    // MARK: - View Builder
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12){
            
            ZStack{
                if let userProfilePicData, let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 25)
            
            // MARK: - TextField and SecureField group
            Group{
                TextField("Username", text: $userName)
                    .border(1, .gray.opacity(0.5))
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .border(1, .gray.opacity(0.5))
                TextField("About You", text: $userBio, axis: .vertical)
                    .frame(minHeight: 100, alignment: .top)
                    .border(1, .gray.opacity(0.5))
                TextField("Bio link (optional)", text: $userBioLink)
                    .border(1, .gray.opacity(0.5))
            }
            Button(action: registerUser){
                // MARK: Login Button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top, 10)
        }
    }
    // MARK: - Register user function
    func registerUser(){
        isLoading = true
        Task{
            do{
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                let downloadURL = try await storageRef.downloadURL()
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil {
                        // MARK: - Print saved successfully
                        print("Saved successfully.")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            } catch {
                // MARK: - Deleting created account in case of failure
                try await Auth.auth().currentUser?.delete()
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

// MARK: - View Extensions For UI Building
extension View{
    
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignment: Alignment) -> some View{
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    func vAlign(_ alignment: Alignment) -> some View{
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    // MARK: - Custom Border
    func border(_ width: CGFloat, _ color: Color) -> some View {
        self.padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background{
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color, lineWidth: width)
            }
    }
    // MARK: - Custom Fill
    func fillView(_ color: Color) -> some View {
        self.padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background{
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(color)
            }
    }
}
