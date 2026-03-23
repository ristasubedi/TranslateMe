//
//  Translation.swift
//  TranslateMe
//
//  Created by Rista Subedi on 3/23/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Translation: Identifiable, Codable {
    @DocumentID var id: String?
    var originalText: String
    var translatedText: String
    var timestamp: Date
    var targetLanguage: String
}
