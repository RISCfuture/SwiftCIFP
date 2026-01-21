import Foundation

/// Special use/restrictive airspace record.
///
/// Defines MOAs, restricted areas, prohibited areas, warning areas, etc.
public struct SpecialUseAirspace: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// ICAO region code.
  public let icaoRegion: String

  /// Restrictive airspace type (MOA, Restricted, etc.).
  public let restrictiveType: RestrictiveAirspaceType

  /// Airspace designation (e.g., "R-2508", "MOA BUCKHORN").
  public let designation: String

  /// Multiple code (for multi-segment areas).
  public let multipleCode: String?

  /// Airspace name.
  public let name: String

  /// Boundary segments.
  public let boundaries: [AirspaceBoundary]

  /// Lower altitude limit.
  public let lowerLimit: Altitude?

  /// Upper altitude limit.
  public let upperLimit: Altitude?

  /// Full designation including type prefix.
  public var fullDesignation: String {
    switch restrictiveType {
      case .restricted: "R-\(designation)"
      case .prohibited: "P-\(designation)"
      case .warning: "W-\(designation)"
      case .moa: "MOA \(designation)"
      case .alert: "A-\(designation)"
      case .caution: "C-\(designation)"
      case .danger: "D-\(designation)"
      case .tra: "TRA \(designation)"
      case .specialRules: "U-\(designation)"
    }
  }

  /// Creates a SpecialUseAirspace record.
  init(
    icaoRegion: String,
    restrictiveType: RestrictiveAirspaceType,
    designation: String,
    multipleCode: String?,
    name: String,
    boundaries: [AirspaceBoundary],
    lowerLimit: Altitude?,
    upperLimit: Altitude?
  ) {
    self.icaoRegion = icaoRegion
    self.restrictiveType = restrictiveType
    self.designation = designation
    self.multipleCode = multipleCode
    self.name = name
    self.boundaries = boundaries
    self.lowerLimit = lowerLimit
    self.upperLimit = upperLimit
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case icaoRegion, restrictiveType, designation, multipleCode
    case name, boundaries, lowerLimit, upperLimit
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - CustomStringConvertible

extension SpecialUseAirspace: CustomStringConvertible {
  public var description: String {
    var desc = fullDesignation
    if !name.isEmpty && name != designation {
      desc += " (\(name))"
    }
    return desc
  }
}

// MARK: - Linked Properties

extension SpecialUseAirspace {
  /// The center fix for this airspace, if it references a navaid or waypoint.
  ///
  /// This property attempts to resolve the designation as a fix identifier
  /// when linked via `CIFPData`.
  public var centerFix: Fix? {
    get async {
      guard let data else { return nil }
      return await data.resolveFix(designation, sectionCode: nil, airportId: nil)
    }
  }
}
