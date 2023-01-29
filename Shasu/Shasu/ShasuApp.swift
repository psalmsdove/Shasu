//
//  ShasuApp.swift
//  Shasu
//
//  Created by Ali Erdem Kökcik on 29.01.2023.
//

import SwiftUI
import Firebase

@main
struct ShasuApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
