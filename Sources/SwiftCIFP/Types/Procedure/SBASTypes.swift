import Foundation

/// SBAS approach service level.
///
/// Indicates the level of SBAS (Satellite-Based Augmentation System) service
/// available for an approach procedure.
public enum SBASServiceLevel: String, Sendable, Codable, CaseIterable {
  /// Localizer Performance with Vertical guidance (LPV).
  case lpv = "ALPV"
  /// Localizer Performance (lateral only).
  case lp = "ALP"
  /// Localizer Performance with Vertical guidance version 200 (LPV200).
  case lpv200 = "ALPV200"

  /// Creates an SBASServiceLevel from the raw string value.
  ///
  /// - Parameter string: The trimmed string from the CIFP record.
  public init?(string: String) {
    // Try exact match first
    if let match = Self(rawValue: string) {
      self = match
      return
    }
    // Handle variations with extra spacing or partial matches
    let trimmed = string.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty {
      return nil
    }
    if let match = Self(rawValue: trimmed) {
      self = match
      return
    }
    return nil
  }
}

/// Required Navigation Performance specification for approach procedures.
///
/// Specifies the navigation performance requirements for the approach.
public enum RequiredNavPerformance: String, Sendable, Codable, CaseIterable {
  /// Area Navigation with Vertical Navigation capability.
  case areaNavWithVNAV = "ALNAV/VNAV"
  /// Area Navigation only.
  case areaNAV = "ALNAV"
  /// RNP 0.3 approach.
  case rnp03 = "RNP 0.3"
  /// RNP approach (general).
  case rnpApproach = "RNP APCH"

  /// Creates a RequiredNavPerformance from the raw string value.
  ///
  /// - Parameter string: The trimmed string from the CIFP record.
  public init?(string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty {
      return nil
    }
    if let match = Self(rawValue: trimmed) {
      self = match
      return
    }
    return nil
  }
}

/// Lateral navigation capability for approach procedures.
///
/// Indicates the lateral navigation capability required for the approach.
public enum LateralNavCapability: String, Sendable, Codable, CaseIterable {
  /// Area Navigation capability.
  case areaNAV = "ALNAV"
  /// LNAV capability.
  case lnav = "LNAV"

  /// Creates a LateralNavCapability from the raw string value.
  ///
  /// - Parameter string: The trimmed string from the CIFP record.
  public init?(string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty {
      return nil
    }
    if let match = Self(rawValue: trimmed) {
      self = match
      return
    }
    return nil
  }
}
