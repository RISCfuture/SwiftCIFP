import CoreLocation
import Foundation

/// Heliport reference record.
public struct Heliport: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Heliport identifier (ICAO code or FAA-assigned identifier).
  public let id: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Elevation in feet MSL.
  public let elevationFt: Int

  /// Magnetic variation.
  public let magneticVariation: MagneticVariation?

  /// Heliport name.
  public let name: String

  // MARK: - Child Collections (populated during linking)

  /// Waypoints at this heliport.
  public internal(set) var waypoints: [HeliportWaypoint] = []

  /// Approach procedures at this heliport.
  public internal(set) var approaches: [HeliportApproach] = []

  /// MSA records at this heliport.
  public internal(set) var msaRecords: [HeliportMSA] = []

  /// Creates a Heliport record.
  init(
    id: String,
    icaoRegion: String,
    coordinate: Coordinate,
    elevationFt: Int,
    magneticVariation: MagneticVariation?,
    name: String
  ) {
    self.id = id
    self.icaoRegion = icaoRegion
    self.coordinate = coordinate
    self.elevationFt = elevationFt
    self.magneticVariation = magneticVariation
    self.name = name
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case id, icaoRegion, coordinate, elevationFt
    case magneticVariation, name
    case waypoints, approaches, msaRecords
    // Note: 'data' is excluded
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension Heliport: Identifiable, Equatable, Hashable {
  public static func == (lhs: Heliport, rhs: Heliport) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Measurement Extensions

extension Heliport {
  /// Heliport elevation as a Measurement.
  public var elevation: Measurement<UnitLength> {
    .init(value: Double(elevationFt), unit: .feet)
  }
}
