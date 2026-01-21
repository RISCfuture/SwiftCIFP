import CoreLocation
import Foundation

/// Heliport MSA record.
public struct HeliportMSA: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent heliport ICAO identifier.
  let parentId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// MSA center fix identifier.
  public let center: String

  /// MSA radius in nautical miles.
  public let radiusNM: Double?

  /// Sectors with minimum altitudes.
  public let sectors: Set<MSASector>

  /// Creates a HeliportMSA record.
  init(
    parentId: String,
    icaoRegion: String,
    center: String,
    radiusNM: Double?,
    sectors: Set<MSASector>
  ) {
    self.parentId = parentId
    self.icaoRegion = icaoRegion
    self.center = center
    self.radiusNM = radiusNM
    self.sectors = sectors
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case parentId, icaoRegion, center, radiusNM, sectors
    // Note: 'data' is excluded
  }
}

// MARK: - HeliportMSA Measurement Extensions

extension HeliportMSA {
  /// MSA radius as a Measurement.
  public var radius: Measurement<UnitLength>? {
    radiusNM.map { .init(value: $0, unit: .nauticalMiles) }
  }
}

// MARK: - HeliportMSA Linked Properties

extension HeliportMSA {
  /// The parent heliport.
  ///
  /// This property resolves the `parentId` to the actual `Heliport` object
  /// when linked via `CIFPData`.
  public var heliport: Heliport? {
    get async {
      guard let data else { return nil }
      return await data.heliport(parentId)
    }
  }
}
