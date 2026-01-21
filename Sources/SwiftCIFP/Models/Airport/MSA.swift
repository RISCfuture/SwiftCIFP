import Foundation

/// MSA (Minimum Sector Altitude) sector.
public struct MSASector: Sendable, Codable, Hashable {
  /// Sector bearing range (clockwise from lower to upper bound).
  public let sectorBearings: BearingRange

  /// Sector altitude in feet MSL.
  public let altitudeFt: Int

  /// Returns whether the given bearing falls within this sector.
  public func contains(bearing: Double) -> Bool {
    sectorBearings.contains(bearing)
  }
}

// MARK: - MSASector Measurement Extensions

extension MSASector {
  /// Sector altitude as a Measurement.
  public var altitude: Measurement<UnitLength> {
    .init(value: Double(altitudeFt), unit: .feet)
  }
}

/// MSA (Minimum Sector Altitude) record.
///
/// Provides minimum safe altitudes within a specified radius of a navigation fix.
public struct MSA: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// MSA center fix identifier.
  public let center: String

  /// MSA center ICAO region.
  public let centerICAO: String

  /// Multiple code indicator.
  public let multipleCode: String?

  /// MSA radius in nautical miles.
  public let radiusNM: Double

  /// Sectors with minimum altitudes.
  public let sectors: Set<MSASector>

  /// Reference system for bearings (magnetic or true north).
  public let bearingReference: BearingReference

  /// Creates an MSA record.
  init(
    airportId: String,
    icaoRegion: String,
    center: String,
    centerICAO: String,
    multipleCode: String?,
    radiusNM: Double,
    sectors: Set<MSASector>,
    bearingReference: BearingReference
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.center = center
    self.centerICAO = centerICAO
    self.multipleCode = multipleCode
    self.radiusNM = radiusNM
    self.sectors = sectors
    self.bearingReference = bearingReference
  }

  /// Get the minimum altitude for a given bearing.
  ///
  /// - Parameter bearing: Bearing in degrees (0-360).
  /// - Returns: The minimum sector altitude in feet, or nil if not found.
  public func altitudeFt(for bearing: Double) -> Int? {
    sectors.first { $0.contains(bearing: bearing) }?.altitudeFt
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, center, centerICAO
    case multipleCode, radiusNM, sectors, bearingReference
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - MSA Measurement Extensions

extension MSA {
  /// MSA radius as a Measurement.
  public var radius: Measurement<UnitLength> {
    .init(value: radiusNM, unit: .nauticalMiles)
  }

  /// Get the minimum altitude for a given bearing as a Measurement.
  ///
  /// - Parameter bearing: Bearing in degrees (0-360).
  /// - Returns: The minimum sector altitude, or nil if not found.
  public func altitude(for bearing: Double) -> Measurement<UnitLength>? {
    altitudeFt(for: bearing).map { .init(value: Double($0), unit: .feet) }
  }
}

// MARK: - Linked Properties

extension MSA {
  /// The center fix for this MSA.
  ///
  /// This property resolves the `center` identifier to the actual fix object
  /// when linked via `CIFPData`.
  public var centerFix: Fix? {
    get async {
      guard let data else { return nil }
      return await data.resolveFix(center, sectionCode: nil, airportId: airportId)
    }
  }

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
