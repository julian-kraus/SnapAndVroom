//
//  OpenAiClient.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import UIKit

func classifyImageForCarPrefs(
    _ image: UIImage,
    completion: @escaping (Result<CarPreferencePrediction, Error>) -> Void
) {
    // 1) Encode image as base64 data URL
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NSError(domain: "Encoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get JPEG data from image"])))
        return
    }
    let base64 = imageData.base64EncodedString()
    let dataUrl = "data:image/jpeg;base64,\(base64)"

    // 2) Build the JSON schema
    let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "trip_type": ["type": "string"],
            "car_category": ["type": "string"],
            "addons": [
                "type": "array",
                "items": ["type": "string"]
            ],
            "protection_package": ["type": "string"],
            "music_vibe": ["type": ["string", "null"]],
            "people_summary": ["type": ["string", "null"]]
        ],
        "required": ["trip_type", "car_category", "addons", "protection_package", "music_vibe", "people_summary"],
        "additionalProperties": false
    ]

    // 3) Prompt (with safety constraints)
    let prompt = """
    You work for a car rental company (similar to Sixt).

    Look at the image and, based ONLY on non-sensitive visual context
    (clothing style, luggage, equipment like skis/surfboard, apparent group size,
    kids vs adults, and environment like airport/beach/city/mountains), estimate:

    - trip_type: one of "business", "vacation", "family", "party", "one-way",
      or a short custom text.
    - car_category: e.g. "economy", "compact", "suv", "premium", "luxury", "van", "ev".
    - addons: array of useful extras like "child_seat", "ski_rack", "gps",
      "extra_driver", "wifi", "winter_tires", "premium_sound".
    - protection_package: e.g. "basic", "standard", or "full".
    - music_vibe: rough guess like "pop", "rock", "electronic", "classical",
      "hiphop", "mixed", or "unknown".
    - people_summary: short neutral description of the people
      (e.g. "Two adults with carry-on suitcases", "Family with two small children and ski gear").

    Rules:
    - Do NOT infer or mention race, ethnicity, nationality, religion, health,
      disability, sexual orientation, or wealth/socioeconomic status.
    - Do NOT guess exact ages, just general roles like "adults" or "children".
    - If something is unclear, choose safe generic values like "unknown",
      an empty list, or set the corresponding field to null or an empty string,
      but never omit fields.
    - Always include every field defined in the schema.
    - Return ONLY valid JSON matching the provided schema. No extra text.
    """

    // 4) Build the request body
    let body: [String: Any] = [
        "model": "gpt-4.1-mini",
        "input": [[
            "role": "user",
            "content": [
                [
                    "type": "input_text",
                    "text": prompt
                ],
                [
                    "type": "input_image",
                    "image_url": dataUrl,
                    "detail": "high"
                ]
            ]
        ]],
        "text": [
            "format": [
                "type": "json_schema",
                "name": "CarPreferencePrediction",
                "schema": schema,
                "strict": true
            ]
        ]
    ]

    // 5) Create URLRequest
    guard let url = URL(string: "https://api.openai.com/v1/responses") else {
        completion(.failure(NSError(domain: "URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(AppConfig.bookingAPIKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }

    // 6) Call the API
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Networking error
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
            return
        }

        // Debug: print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("RAW RESPONSE STRING:\n", rawString)
        }

        // Debug: attempt to decode as generic JSON and detect OpenAI error structure
        do {
            let generic = try JSONSerialization.jsonObject(with: data, options: [])
            print("PARSED GENERIC JSON:\n", generic)

            if let dict = generic as? [String: Any],
               let errorDict = dict["error"] as? [String: Any],
               let message = errorDict["message"] as? String {
                print("OPENAI ERROR MESSAGE:", message)
                let err = NSError(
                    domain: "OpenAI",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
                completion(.failure(err))
                return
            }
        } catch {
            print("FAILED TO PARSE GENERIC JSON:", error)
        }

        do {
            // Parse top-level JSON
            guard
                let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let outputArray = root["output"] as? [[String: Any]],
                let firstMessage = outputArray.first,
                let contentArray = firstMessage["content"] as? [[String: Any]],
                let firstContent = contentArray.first,
                let jsonText = firstContent["text"] as? String
            else {
                completion(.failure(OpenAIParsingError.missingPrediction))
                return
            }

            // The model returned JSON as a string in `text` – decode that into our struct
            guard let jsonData = jsonText.data(using: .utf8) else {
                completion(.failure(NSError(domain: "OpenAI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert text to data"])))
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let prediction = try decoder.decode(CarPreferencePrediction.self, from: jsonData)
            completion(.success(prediction))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}
