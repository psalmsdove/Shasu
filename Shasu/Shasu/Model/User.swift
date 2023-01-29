//
//  User.swift
//  Shasu
//
//  Created by Ali Erdem Kökcik on 29.01.2023.
//

import FirebaseFirestoreSwift
import SwiftUI

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey{
        case id
        case username
        case userBio
        case userBioLink
        case userUID
        case userEmail
        case userProfileURL
    }
}

