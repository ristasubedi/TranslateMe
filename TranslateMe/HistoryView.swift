//
//  HistoryView.swift
//  TranslateMe
//
//  Created by Rista Subedi on 3/23/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct HistoryView: View {
    @FirestoreQuery(collectionPath: "translations") var history: [Translation]
    let db = Firestore.firestore()

    var body: some View {
        List {
            if history.isEmpty {
                Text("No saved translations yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(history) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.originalText).font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text(item.translatedText)
                                .foregroundColor(.blue)
                            
                            if transliterate(item.translatedText).lowercased() != item.translatedText.lowercased() {
                                Text("(\(transliterate(item.translatedText)))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        }
                    }
                }
                .onDelete(perform: deleteHistoryItem)
            }
        }
        .navigationTitle("Saved History")
        .toolbar {
            Button("Clear All") {
                deleteAllHistory()
            }
        }
    }

    func deleteHistoryItem(at offsets: IndexSet) {
        offsets.forEach { index in
            if let id = history[index].id {
                db.collection("translations").document(id).delete()
            }
        }
    }

    func deleteAllHistory() {
        for item in history {
            if let id = item.id {
                db.collection("translations").document(id).delete()
            }
        }
    }
}

func transliterate(_ text: String) -> String {
    let mutableString = NSMutableString(string: text)
    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
    return mutableString as String
}
