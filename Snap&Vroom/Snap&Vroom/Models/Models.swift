//
//  Models.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//
import Foundation

// MARK: - Common Types

/// Simple money type used for things like vehicleCost, deductibleAmount, etc.
struct Money: Codable {
    let currency: String
    let value: Double
}

/// A single price component (e.g. "+ 9.45 /day", "60.85 in total")
struct PriceComponent: Codable {
    let currency: String
    let amount: Double
    let prefix: String?
    let suffix: String?
}

/// Generic pricing block with optional list/total price.
/// Used for vehicle pricing, protection package pricing, addon pricing, etc.
struct GenericPrice: Codable {
    let discountPercentage: Double
    let displayPrice: PriceComponent
    let listPrice: PriceComponent?
    let totalPrice: PriceComponent?
}

/// Local representation of selected addons on a booking
struct BookingAddon: Identifiable, Hashable {
    let id: String        // addonId
    let title: String
    var amount: Int
}

// MARK: - VEHICLE / BOOKING SIDE

// Root of your original booking JSON
struct Booking: Codable {
    let bookedCategory: String?
    let protectionPackages: [ProtectionPackage]?
    let createdAt: String?
    let selectedVehicle: SelectedVehicle?
    let status: String?
    let id: String
    var addons: [BookingAddon] = []

    enum CodingKeys: String, CodingKey {
        case bookedCategory
        case protectionPackages
        case createdAt
        case selectedVehicle
        case status
        case id
    }

    init(from decoder: Decoder) throws {
        // DEBUG: print full booking JSON
        if let debugJson = try? JSONSerialization.jsonObject(with: decoder.singleValueContainer().decode(Data.self)),
           let pretty = try? JSONSerialization.data(withJSONObject: debugJson, options: .prettyPrinted),
           let jsonString = String(data: pretty, encoding: .utf8) {
            print("[Booking DEBUG] Raw JSON:\n\(jsonString)")
        } else {
            print("[Booking DEBUG] Unable to print raw JSON (decoder not single-value)")
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        bookedCategory = try? container.decode(String.self, forKey: .bookedCategory)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        selectedVehicle = try? container.decode(SelectedVehicle.self, forKey: .selectedVehicle)
        status = try? container.decode(String.self, forKey: .status)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""

        // Try decoding protectionPackages as array
        if let arrayValue = try? container.decode([ProtectionPackage].self, forKey: .protectionPackages) {
            protectionPackages = arrayValue
        }
        // Try decoding as a single dictionary → wrap in array
        else if let dictValue = try? container.decode(ProtectionPackage.self, forKey: .protectionPackages) {
            protectionPackages = [dictValue]
        }
        // Otherwise set to nil
        else {
            protectionPackages = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(bookedCategory, forKey: .bookedCategory)
        try container.encodeIfPresent(protectionPackages, forKey: .protectionPackages)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(selectedVehicle, forKey: .selectedVehicle)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encode(id, forKey: .id)
    }
}

// This is used both for the selectedVehicle and for items in "deals"
struct SelectedVehicle: Codable {
    let vehicle: Vehicle
    let pricing: GenericPrice?
    let dealInfo: String?
    let tags: [String]?
    let priceTag: String?    // only present in some deals
}

struct Vehicle: Codable {
    let id: String
    let brand: String?
    let model: String?
    let acrissCode: String?
    let images: [URL]?
    let bagsCount: Int?
    let passengersCount: Int?
    let groupType: String?
    let tyreType: String?
    let transmissionType: String?
    let fuelType: String?
    let isNewCar: Bool?
    let isRecommended: Bool?
    let isMoreLuxury: Bool?
    let isExcitingDiscount: Bool?
    let attributes: [VehicleAttribute]?
    let vehicleStatus: String?
    let vehicleCost: Money?
    let upsellReasons: [String]?
}

struct VehicleAttribute: Codable {
    let key: String
    let title: String?
    let value: String?
    let attributeType: String?
    let iconUrl: URL?    // optional: some upsell attributes have no iconUrl
}

// MARK: - PROTECTION PACKAGES

/// Wrapper for the protectionPackages JSON you posted
struct ProtectionPackagesResponse: Codable {
    let protectionPackages: [ProtectionPackage]?
}

struct ProtectionPackage: Codable {
    let id: String
    let name: String?
    let description: String?              // only present on the "I don’t need protection" entry
    let deductibleAmount: Money?
    let ratingStars: Int?
    let isPreviouslySelected: Bool?
    let isSelected: Bool?
    let isDeductibleAvailable: Bool?
    let includes: [ProtectionFeature]?
    let excludes: [ProtectionFeature]?
    let price: GenericPrice?
    let isNudge: Bool?
}

struct ProtectionFeature: Codable {
    let id: String
    let title: String?
    let description: String?
    let tags: [String]?
}

// MARK: - ADDONS

/// Wrapper for the addons JSON
struct AddonsResponse: Codable {
    let addons: [AddonCategory]?
}

struct AddonCategory: Codable {
    let id: Int
    let name: String?
    let options: [AddonOption]?
}

struct AddonOption: Codable {
    let chargeDetail: AddonChargeDetail?
    let additionalInfo: AddonAdditionalInfo?
}

struct AddonChargeDetail: Codable {
    let id: String
    let title: String?
    let description: String?
    let iconUrl: URL?
    let tags: [String]?
}

struct AddonAdditionalInfo: Codable {
    let price: GenericPrice?
    let isPreviouslySelected: Bool?
    let isSelected: Bool?
    let isEnabled: Bool?
    let selectionStrategy: AddonSelectionStrategy?
    let isNudge: Bool?
}

struct AddonSelectionStrategy: Codable {
    let isMultiSelectionAllowed: Bool?
    let maxSelectionLimit: Int?
    let currentSelection: Int?
}

// MARK: - VEHICLE DEALS LIST (reservationId + deals + filters + quickFilters...)

/// Wrapper for the big JSON that contains reservationId, deals, filters, etc.
struct VehicleDealsResponse: Codable {
    let reservationId: String?
    let deals: [SelectedVehicle]              // reuses SelectedVehicle
    let totalVehicles: Int?
    let reservationBlockDateTime: ReservationBlockDateTime?
    let filter: VehicleFilter?
    let quickFilters: [QuickFilter]?
    let terminalList: [Terminal]?
    let isBundleSelected: Bool?
}

struct ReservationBlockDateTime: Codable {
    let date: String?        // keep as ISO string: "2025-11-21T09:47:04+01:00"
    let timeZone: String?
}

struct VehicleFilter: Codable {
    let brands: [String]?
    let transmissionTypes: [String]?
    let fuelTypes: [String]?
}

struct QuickFilter: Codable {
    let key: String?
    let title: String?
    let selectType: String?
}

/// Terminal objects are currently unknown; this implementation safely ignores any fields.
struct Terminal: Codable {
    init(from decoder: Decoder) throws { }
    func encode(to encoder: Encoder) throws { }
}


struct RecommendedAddon: Codable, Hashable {
    let addonId: String
    let reason: String
}

struct CarPreferencePrediction: Codable {
    let recommendedVehicleId: String
    let recommendedVehicleReason: String
    let recommendedProtectionPackageId: String?
    let recommendedProtectionReason: String?
    let recommendedAddons: [RecommendedAddon]
    let overallExplanation: String?

    func toString() -> String {
        var parts: [String] = []
        parts.append("Recommended vehicle id: \(recommendedVehicleId)")
        parts.append("Vehicle reason: \(recommendedVehicleReason)")
        if let protectionId = recommendedProtectionPackageId {
            parts.append("Protection package id: \(protectionId)")
        } else {
            parts.append("Protection package id: none")
        }
        if let protectionReason = recommendedProtectionReason {
            parts.append("Protection reason: \(protectionReason)")
        }
        if recommendedAddons.isEmpty {
            parts.append("Addons: none")
        } else {
            let addonLines = recommendedAddons.map { "- \($0.addonId): \($0.reason)" }
            parts.append("Addons:\n" + addonLines.joined(separator: "\n"))
        }
        if let summary = overallExplanation {
            parts.append("Overall explanation: \(summary)")
        }
        return parts.joined(separator: "\n")
    }
}

struct OpenAIResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let json: CarPreferencePrediction?
        }
        let content: [Content]
    }

    let output: [Output]
}

enum OpenAIParsingError: Error {
    case missingPrediction
}
