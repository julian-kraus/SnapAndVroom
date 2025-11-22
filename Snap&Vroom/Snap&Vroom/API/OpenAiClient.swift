//
//  OpenAiClient.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import UIKit

func classifyImageForCarPrefs(
    _ image: UIImage,
    bookingContext: String,
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
            "recommended_vehicle_id": ["type": "string"],
            "recommended_vehicle_reason": ["type": "string"],
            "recommended_protection_package_id": ["type": ["string", "null"]],
            "recommended_protection_reason": ["type": ["string", "null"]],
            "recommended_addons": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "addon_id": ["type": "string"],
                        "reason": ["type": "string"]
                    ],
                    "required": ["addon_id", "reason"],
                    "additionalProperties": false
                ]
            ],
            "overall_explanation": ["type": ["string", "null"]]
        ],
        "required": [
            "recommended_vehicle_id",
            "recommended_vehicle_reason",
            "recommended_protection_package_id",
            "recommended_protection_reason",
            "recommended_addons",
            "overall_explanation"
        ],
        "additionalProperties": false
    ]

    // 3) Prompt (with safety constraints)
    let prompt = """
    You work for a car rental company (similar to Sixt).

    Your task:
    - Based on the customer context and booking/inventory data, recommend:
      1) ONE specific vehicle (using its id),
      2) ONE protection package (using its id, or null if none is appropriate),
      3) ONE or more addons (each with its addon id) where they add clear value (aim for 2–3 when appropriate, but avoid spamming unnecessary addons),
    - For each of these (vehicle, protection package, each addon), explain briefly WHY you recommend it.
    - The vehicle you recommend should generally be more expensive or more feature-rich than the initial selected car, if such an option exists, while still reasonably fitting the user context.

    You will receive:
    - A high-level description of the user and their trip (derived from the app / image).
    - Booking context including the initial selected car.
    - A list of available vehicles, protection packages, and addons with their IDs and key attributes.

    Use only the IDs provided in the context when recommending a vehicle, protection package, or addon. Do not invent new IDs.

    Safety / fairness rules:
    - Use only visible, non-sensitive cues (e.g. luggage, group size, clothing style, environment like airport/beach/mountain).
    - Do NOT infer or mention race, ethnicity, nationality, religion, health, disability, sexual orientation, or wealth/socioeconomic status.
    - Do NOT guess exact ages; use general roles like "adults" and "children".
    - If something is unclear, make safe, neutral assumptions and avoid overfitting.

    Output design:
    - recommended_vehicle_id: the id of the vehicle you think is best for this user, preferring a more expensive/feature-rich car than the initial one when reasonable.
    - recommended_vehicle_reason: short explanation in friendly language that can be shown to the user.
    - recommended_protection_package_id: id of the chosen protection package, or null if the user clearly does not need one.
    - recommended_protection_reason: short explanation for your protection choice, suitable for the user.
    - recommended_addons: array of objects { addon_id, reason } where reason explains why that addon helps this user.
    - overall_explanation: short summary tying everything together that can be shown to the user.

    Booking and inventory context (vehicles, protection packages, addons, and initial selected car):
    \(bookingContext)

    Return ONLY valid JSON matching the provided schema. No extra commentary.
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
