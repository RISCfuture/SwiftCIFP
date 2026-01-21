import CoreLocation
import Foundation

/// NDB (Non-Directional Beacon) Navaid record.
///
/// NDBs are low-frequency radio beacons used for aircraft navigation.
public struct NDBNavaid: Sendable, Codable {
  /// The navaid identifier (typically 2-5 characters).
  public let identifier: String

  /// ICAO region code.
  public let icaoRegion: String

  /// NDB frequency in kHz (e.g., 356.0).
  public let frequencyKHz: Double

  /// NDB class (power/range category).
  public let ndbClass: NDBClass

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation at the NDB location.
  public let magneticVariation: MagneticVariation

  /// Facility name.
  public let name: String
}

// MARK: - CustomStringConvertible

extension NDBNavaid: CustomStringConvertible {
  public var description: String {
    "\(identifier) (NDB)"
  }
}

// MARK: - Measurement Extensions

extension NDBNavaid {
  /// NDB frequency as a Measurement.
  public var frequency: Measurement<UnitFrequency> {
    .init(value: frequencyKHz, unit: .kilohertz)
  }
}
