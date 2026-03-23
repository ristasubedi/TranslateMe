//
//  ContentView.swift
//  TranslateMe
//
//  Created by Rista Subedi on 3/23/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ContentView: View {
    let languages = [
        "Spanish": "es",
        "French": "fr",
        "German": "de",
        "Italian": "it",
        "Japanese": "ja",
        "Hindi": "hi"
    ]

    @State private var selectedLanguage = "es"
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isTranslating = false
    @State private var lastTranslatedInput: String = ""
    
    @FirestoreQuery(collectionPath: "translations") var history: [Translation]
    
    let service = TranslationService()
    let db = Firestore.firestore()
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Translate from English")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.leading, 5)
                        
                        TextField("Type something...", text: $inputText)
                            .font(.body)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Target Language")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                        

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(languages.keys.sorted(), id: \.self) { key in
                                    let code = languages[key] ?? "es"
                                    let isSelected = selectedLanguage == code
                                    
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            selectedLanguage = code
                                        }
                                    }) {
                                        Text(key)
                                            .font(.subheadline)
                                            .fontWeight(isSelected ? .bold : .medium)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(isSelected ? Color.blue : Color(.systemBackground))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 5)
                        }
                    }

                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 12) {
                            if translatedText.isEmpty {
                                // Placeholder state
                                VStack(spacing: 12) {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue.opacity(0.2))
                                    Text("Translation will appear here...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .frame(height: 140)
                            } else {
                                VStack(spacing: 10) {
                                    Text(lastTranslatedInput)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue.opacity(0.5))

                                    Text(translatedText)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    let soundsLike = transliterate(translatedText)
                                    if soundsLike.lowercased() != translatedText.lowercased() {
                                        Text(soundsLike)
                                            .font(.title3)
                                            .italic()
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Button(action: {
                                        UIPasteboard.general.string = translatedText
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 5)
                                }
                                .padding(.vertical, 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 200)
                        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)

                        if !translatedText.isEmpty {
                            Button(action: {
                                withAnimation {
                                    translatedText = ""
                                    lastTranslatedInput = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray.opacity(0.4))
                                    .padding(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                    Button(action: translateAndSave) {
                        HStack {
                            if isTranslating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                Text("Translate to \(languages.first(where: { $0.value == selectedLanguage })?.key ?? "")")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(inputText.isEmpty || isTranslating)
                    .padding(.horizontal)

                    NavigationLink(destination: HistoryView()) {
                        Label("View Saved Translations", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                }
                .padding(.top, 20)
            }
            .navigationTitle("TranslateMe")
            .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
        }
    }

    
    func transliterate(_ text: String) -> String {
        let mutableString = NSMutableString(string: text)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return mutableString as String
    }

    func translateAndSave() {
        let textToTranslate = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToTranslate.isEmpty else { return }

        isTranslating = true

        service.fetchTranslation(for: textToTranslate, targetLanguage: selectedLanguage) { result in
            DispatchQueue.main.async {
                self.isTranslating = false
                
                if let result = result {
                    self.lastTranslatedInput = textToTranslate
                    self.translatedText = result
                    
                    let newTranslation = Translation(
                        originalText: textToTranslate,
                        translatedText: result,
                        timestamp: Date(),
                        targetLanguage: selectedLanguage
                    )
                    
                    try? db.collection("translations").addDocument(from: newTranslation)
                    
                    self.inputText = ""
                }
            }
        }
    }
    
    func deleteHistoryItem(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = history[index]
            if let id = item.id {
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
