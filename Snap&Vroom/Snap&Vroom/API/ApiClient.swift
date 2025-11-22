//
//  Untitled.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//
import Foundation

// MARK: - API Client

final class SixtAPIClient {
    private let baseURL = URL(string: "https://hackatum25.sixt.io")!
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    enum APIError: Error {
        case invalidURL
        case httpError(statusCode: Int, data: Data?)
        case decodingError(Error)
    }
    
    // MARK: - Helpers
    
    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        print("[API] Request → \(method) \(url.absoluteString)")
        
        return request
    }
    
    private func sendRequest<T: Decodable>(
        _ request: URLRequest,
        decodeTo type: T.Type
    ) async throws -> T {
        print("[API] Sending request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
            print("[API] Request body: \(json)")
        }
        let (data, response) = try await session.data(for: request)
        print("[API] Response received: \(response)")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            print("[API] HTTP Error \(httpResponse.statusCode)")
            print("[API] Response body:", String(data: data, encoding: .utf8) ?? "<no body>")
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            let decoder = JSONDecoder()
            // If you later change createdAt / date to Date, you can enable:
            // decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(T.self, from: data)
            print("[API] Decoded \(T.self) successfully")
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Create Booking

/// Shape of the body for creating a booking.
/// Adjust fields to whatever your backend expects.
struct CreateBookingRequest: Encodable {
    let pickupStation: String?
    let dropoffStation: String?
    let pickupDateTime: String?
    let dropoffDateTime: String?
    let bookedCategory: String?
}

extension SixtAPIClient {
    
    /// POST /api/booking
    func createBooking(_ requestBody: CreateBookingRequest) async throws -> Booking {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestBody)
        
        let request = try makeRequest(
            path: "/api/booking",
            method: "POST",
            body: bodyData
        )
        
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}

// MARK: - Assign Addon

extension SixtAPIClient {
    
    /// POST /api/booking/<BOOKING_ID>/addons/<ADDON_ID>/amount/<AMOUNT>
    /// Assumes API returns the updated Booking.
    func assignAddon(
        bookingId: String,
        addonId: String,
        amount: Int
    ) async throws -> Booking {
        let path = "/api/booking/\(bookingId)/addons/\(addonId)/amount/\(amount)"
        let request = try makeRequest(path: path, method: "POST")
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}

// MARK: - Get Booking

extension SixtAPIClient {
    
    /// GET /api/booking/<BOOKING_ID>
    func getBooking(id bookingId: String) async throws -> Booking {
        let path = "/api/booking/\(bookingId)"
        let request = try makeRequest(path: path, method: "GET")
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}

// MARK: - Vehicles for Selection

extension SixtAPIClient {
    
    /// GET /api/booking/<BOOKING_ID>/vehicles
    func getAvailableVehicles(for bookingId: String) async throws -> VehicleDealsResponse {
        let path = "/api/booking/\(bookingId)/vehicles"
        let request = try makeRequest(path: path, method: "GET")
        return try await sendRequest(request, decodeTo: VehicleDealsResponse.self)
    }
}

// MARK: - Protection Packages

extension SixtAPIClient {
    
    /// GET /api/booking/<BOOKING_ID>/protections
    func getProtectionPackages(for bookingId: String) async throws -> ProtectionPackagesResponse {
        let path = "/api/booking/\(bookingId)/protections"
        let request = try makeRequest(path: path, method: "GET")
        return try await sendRequest(request, decodeTo: ProtectionPackagesResponse.self)
    }
}

// MARK: - Addons

extension SixtAPIClient {
    
    /// GET /api/booking/<BOOKING_ID>/addons
    func getAddons(for bookingId: String) async throws -> AddonsResponse {
        let path = "/api/booking/\(bookingId)/addons"
        let request = try makeRequest(path: path, method: "GET")
        return try await sendRequest(request, decodeTo: AddonsResponse.self)
    }
}

// MARK: - Assign Vehicle

extension SixtAPIClient {
    
    /// POST /api/booking/<BOOKING_ID>/vehicles/<VEHICLE_ID>
    /// Assumes API returns the updated Booking.
    func assignVehicle(
        bookingId: String,
        vehicleId: String
    ) async throws -> Booking {
        let path = "/api/booking/\(bookingId)/vehicles/\(vehicleId)"
        let request = try makeRequest(path: path, method: "POST")
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}

// MARK: - Assign Protection Package

extension SixtAPIClient {
    
    /// POST /api/booking/<BOOKING_ID>/protections/<PACKAGE_ID>
    /// Assumes API returns the updated Booking.
    func assignProtectionPackage(
        bookingId: String,
        packageId: String
    ) async throws -> Booking {
        let path = "/api/booking/\(bookingId)/protections/\(packageId)"
        let request = try makeRequest(path: path, method: "POST")
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}

// MARK: - Complete Booking

extension SixtAPIClient {
    
    /// POST /api/booking/<BOOKING_ID>/complete
    /// Assumes API returns the completed Booking.
    func completeBooking(bookingId: String) async throws -> Booking {
        let path = "/api/booking/\(bookingId)/complete"
        let request = try makeRequest(path: path, method: "POST")
        return try await sendRequest(request, decodeTo: Booking.self)
    }
}
