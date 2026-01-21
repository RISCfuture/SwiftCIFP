import CoreLocation
import Foundation

/// A geographic coordinate with latitude and longitude in decimal degrees.
///
/// CIFP uses the HDDDMMSSSS format for coordinates:
/// - H: Hemisphere (N/S for latitude, E/W for longitude)
/// - DDD: Degrees (2 digits for latitude, 3 for longitude)
/// - MM: Minutes
/// - SSSS: Seconds × 100 (hundredths of seconds)
///
/// Example: `N40382374` = 40° 38' 23.74" N
public struct Coordinate: Sendable, Codable, Equatable, Hashable {
  /// Latitude in decimal degrees. Positive for north, negative for south.
  public let latitudeDeg: Double

  /// Longitude in decimal degrees. Positive for east, negative for west.
  public let longitudeDeg: Double
}

// MARK: - Measurement Extensions

extension Coordinate {
  /// Latitude as a Measurement of angle.
  public var latitude: Measurement<UnitAngle> {
    .init(value: latitudeDeg, unit: .degrees)
  }

  /// Longitude as a Measurement of angle.
  public var longitude: Measurement<UnitAngle> {
    .init(value: longitudeDeg, unit: .degrees)
  }
}

// MARK: - CoreLocation Extension

extension Coordinate {
  /// CoreLocation coordinate representation.
  public var coreLocation: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitudeDeg, longitude: longitudeDeg)
  }

  /// Creates a Coordinate from a CoreLocation coordinate.
  init(_ coordinate: CLLocationCoordinate2D) {
    self.latitudeDeg = coordinate.latitude
    self.longitudeDeg = coordinate.longitude
  }
}

// MARK: - CustomStringConvertible

extension Coordinate: CustomStringConvertible {
  public var description: String {
    let latDir = latitudeDeg >= 0 ? "N" : "S"
    let lonDir = longitudeDeg >= 0 ? "E" : "W"
    return String(format: "%.6f°%@, %.6f°%@", abs(latitudeDeg), latDir, abs(longitudeDeg), lonDir)
  }
}
