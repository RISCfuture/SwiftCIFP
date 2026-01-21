import Foundation

/// Controlled airspace record.
///
/// Defines Class B, C, D, and E controlled airspace boundaries.
public struct ControlledAirspace: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// ICAO region code.
  public let icaoRegion: String

  /// Airspace center identifier (airport or fix).
  public let airspaceCenter: String

  /// Airspace classification (B, C, D, E).
  public let airspaceClass: AirspaceClass?

  /// Multiple code (for overlapping airspaces).
  public let multipleCode: String?

  /// Airspace name.
  public let name: String

  /// Boundary segments.
  public let boundaries: [AirspaceBoundary]

  /// Lower altitude limit.
  public let lowerLimit: Altitude?

  /// Upper altitude limit.
  public let upperLimit: Altitude?

  /// Creates a ControlledAirspace record.
  init(
    icaoRegion: String,
    airspaceCenter: String,
    airspaceClass: AirspaceClass?,
    multipleCode: String?,
    name: String,
    boundaries: [AirspaceBoundary],
    lowerLimit: Altitude?,
    upperLimit: Altitude?
  ) {
    self.icaoRegion = icaoRegion
    self.airspaceCenter = airspaceCenter
    self.airspaceClass = airspaceClass
    self.multipleCode = multipleCode
    self.name = name
    self.boundaries = boundaries
    self.lowerLimit = lowerLimit
    self.upperLimit = upperLimit
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case icaoRegion, airspaceCenter, airspaceClass, multipleCode
    case name, boundaries, lowerLimit, upperLimit
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - CustomStringConvertible

extension ControlledAirspace: CustomStringConvertible {
  public var description: String {
    var desc = name
    if let airspaceClass {
      desc += " (\(airspaceClass.name))"
    }
    return desc
  }
}

// MARK: - Linked Properties

extension ControlledAirspace {
  /// The center fix or airport for this airspace.
  ///
  /// This property resolves the `airspaceCenter` identifier to the actual
  /// fix object when linked via `CIFPData`.
  public var centerFix: Fix? {
    get async {
      guard let data else { return nil }
      return await data.resolveFix(airspaceCenter, sectionCode: nil, airportId: nil)
    }
  }

  /// If the center is an airport, returns the airport.
  ///
  /// This property resolves the `airspaceCenter` identifier to the actual
  /// `Airport` object when linked via `CIFPData`.
  public var centerAirport: Airport? {
    get async {
      guard let data else { return nil }
      return await data.airport(airspaceCenter)
    }
  }
}
