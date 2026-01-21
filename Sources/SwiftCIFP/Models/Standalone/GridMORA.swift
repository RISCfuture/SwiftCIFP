import CoreLocation
import Foundation

/// Grid MORA (Minimum Off-Route Altitude) record for a single 1°×1° grid square.
///
/// Grid MORAs provide minimum safe altitudes for 1°×1° latitude/longitude grid squares.
/// These are used for terrain and obstacle clearance when off established airways.
public struct GridMORA: Sendable, Codable {
  /// Latitude of the south edge in degrees.
  public let latitudeDeg: Int

  /// Longitude of the west edge in degrees.
  public let longitudeDeg: Int

  /// MORA value in feet.
  public let moraFt: Int
}

// MARK: - Identifiable, Equatable, Hashable

extension GridMORA: Identifiable, Equatable, Hashable {
  /// Unique identifier derived from coordinates (e.g., "N32W120").
  public var id: String {
    let latPrefix = latitudeDeg >= 0 ? "N" : "S"
    let lonPrefix = longitudeDeg >= 0 ? "E" : "W"
    return "\(latPrefix)\(abs(latitudeDeg))\(lonPrefix)\(abs(longitudeDeg))"
  }

  public static func == (lhs: GridMORA, rhs: GridMORA) -> Bool {
    lhs.latitudeDeg == rhs.latitudeDeg && lhs.longitudeDeg == rhs.longitudeDeg
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitudeDeg)
    hasher.combine(longitudeDeg)
  }
}

// MARK: - Measurement<UnitAngle> Convenience

extension GridMORA {
  /// Latitude of the south edge as a Measurement of angle.
  public var latitude: Measurement<UnitAngle> {
    .init(value: Double(latitudeDeg), unit: .degrees)
  }

  /// Longitude of the west edge as a Measurement of angle.
  public var longitude: Measurement<UnitAngle> {
    .init(value: Double(longitudeDeg), unit: .degrees)
  }
}

// MARK: - CLLocationCoordinate2D Convenience

extension GridMORA {
  /// The southwest corner of this grid square.
  public var southwestCorner: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: Double(latitudeDeg),
      longitude: Double(longitudeDeg)
    )
  }

  /// The northeast corner of this grid square.
  public var northeastCorner: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: Double(latitudeDeg + 1),
      longitude: Double(longitudeDeg + 1)
    )
  }

  /// The centroid of this grid square.
  public var centroid: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: Double(latitudeDeg) + 0.5,
      longitude: Double(longitudeDeg) + 0.5
    )
  }
}
