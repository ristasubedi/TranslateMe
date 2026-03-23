//
//  TranslationService.swift
//  TranslateMe
//
//  Created by Rista Subedi on 3/23/26.
//

import Foundation

class TranslationService {
    func fetchTranslation(for text: String, targetLanguage: String, completion: @escaping (String?) -> Void) {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "en|\(targetLanguage)")
        ]
        
        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(decodedResponse.responseData.translatedText)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - API Data Models (The missing "Scope")
struct TranslationResponse: Codable {
    let responseData: ResponseData
}

struct ResponseData: Codable {
    let translatedText: String
}
