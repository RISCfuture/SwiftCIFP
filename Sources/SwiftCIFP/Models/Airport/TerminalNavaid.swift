import CoreLocation
import Foundation

/// Terminal Navaid record.
///
/// Navigation aids associated with a specific airport terminal area.
public struct TerminalNavaid: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Navaid identifier.
  public let identifier: String

  /// Navaid ICAO region (may differ from airport).
  public let navaidICAO: String

  /// Navaid frequency in kHz. Terminal navaids are NDBs operating in the LF/MF band.
  public let frequencyKHz: Double?

  /// Navaid class/type.
  public let navaidClass: NDBClass

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation at navaid.
  public let magneticVariation: MagneticVariation

  /// Navaid name.
  public let name: String

  /// Creates a Terminal Navaid record.
  init(
    airportId: String,
    icaoRegion: String,
    identifier: String,
    navaidICAO: String,
    frequencyKHz: Double?,
    navaidClass: NDBClass,
    coordinate: Coordinate,
    magneticVariation: MagneticVariation,
    name: String
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.navaidICAO = navaidICAO
    self.frequencyKHz = frequencyKHz
    self.navaidClass = navaidClass
    self.coordinate = coordinate
    self.magneticVariation = magneticVariation
    self.name = name
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, identifier, navaidICAO
    case frequencyKHz, navaidClass, coordinate
    case magneticVariation, name
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Measurement Extensions

extension TerminalNavaid {
  /// Navaid frequency as a Measurement in kHz.
  public var frequency: Measurement<UnitFrequency>? {
    frequencyKHz.map { .init(value: $0, unit: .kilohertz) }
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension TerminalNavaid: Identifiable, Equatable, Hashable {
  public var id: String { "\(airportId)-\(identifier)" }

  public static func == (lhs: TerminalNavaid, rhs: TerminalNavaid) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Linked Properties

extension TerminalNavaid {
  /// The parent airport.
  ///
  /// This property resolves the `airportId` to the actual `Airport` object
  /// when linked via `CIFPData`.
  public var airport: Airport? {
    get async {
      guard let data else { return nil }
      return await data.airport(airportId)
    }
  }
}
