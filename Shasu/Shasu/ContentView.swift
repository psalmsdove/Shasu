//
//  ContentView.swift
//  Shasu
//
//  Created by Ali Erdem Kökcik on 29.01.2023.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        // MARK: - Redirecting based on log status
        if logStatus{
            Text("Main View")
        } else {
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
