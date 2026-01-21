import Foundation

/// VHF Navaid facility type classification.
///
/// The navaid class field (ARINC 424 5.35) is a two-character code indicating the type:
/// - First character: V=VOR, blank=no VOR
/// - Second character: D=DME, T=TACAN, M=Military TACAN, I=ILS DME, N=non-collocated, blank=none
public enum NavaidClass: String, Sendable, Codable, CaseIterable {
  /// VOR only (no DME/TACAN).
  case vor = "V "

  /// DME only (no VOR).
  case dme = " D"

  /// TACAN only (no VOR).
  case tacan = " T"

  /// Military TACAN only (no VOR).
  case militaryTacan = " M"

  /// VOR with collocated TACAN (VORTAC).
  case vortac = "VT"

  /// VOR with collocated DME.
  case vorDME = "VD"

  /// VOR with Military TACAN.
  case vorMilitaryTacan = "VM"

  /// VOR with non-collocated DME.
  case vorNonCollocatedDME = "VN"

  /// Standalone ILS/DME (no VOR).
  case ilsDMEStandalone = " I"

  /// ILS/DME or LOC/DME (with VOR indication).
  case ilsDME = "ID"

  /// ILS with non-collocated DME.
  case ilsNonCollocatedDME = "IN"

  public var description: String {
    switch self {
      case .vor: "VOR"
      case .dme: "DME"
      case .tacan: "TACAN"
      case .militaryTacan: "Military TACAN"
      case .vortac: "VORTAC"
      case .vorDME: "VOR/DME"
      case .vorMilitaryTacan: "VOR/Military TACAN"
      case .vorNonCollocatedDME: "VOR (non-collocated DME)"
      case .ilsDMEStandalone: "ILS/DME"
      case .ilsDME: "ILS/DME"
      case .ilsNonCollocatedDME: "ILS (non-collocated DME)"
    }
  }

  /// Whether this navaid type includes DME capability.
  public var hasDME: Bool {
    switch self {
      case .dme, .vorDME, .ilsDME, .ilsDMEStandalone, .tacan, .militaryTacan, .vortac,
        .vorMilitaryTacan, .vorNonCollocatedDME, .ilsNonCollocatedDME:
        true
      case .vor:
        false
    }
  }

  /// Whether this navaid type includes VOR capability.
  public var hasVOR: Bool {
    switch self {
      case .vor, .vortac, .vorDME, .vorMilitaryTacan, .vorNonCollocatedDME:
        true
      case .dme, .tacan, .militaryTacan, .ilsDME, .ilsDMEStandalone, .ilsNonCollocatedDME:
        false
    }
  }

  /// Whether this navaid type includes TACAN capability.
  public var hasTACAN: Bool {
    switch self {
      case .tacan, .militaryTacan, .vortac, .vorMilitaryTacan:
        true
      case .vor, .dme, .vorDME, .vorNonCollocatedDME, .ilsDME, .ilsDMEStandalone,
        .ilsNonCollocatedDME:
        false
    }
  }

  /// Whether this is an ILS-associated DME.
  public var hasILS: Bool {
    switch self {
      case .ilsDME, .ilsDMEStandalone, .ilsNonCollocatedDME:
        true
      case .vor, .dme, .tacan, .militaryTacan, .vortac, .vorDME, .vorMilitaryTacan,
        .vorNonCollocatedDME:
        false
    }
  }
}

/// VHF Navaid altitude/usage class.
public enum NavaidUsageClass: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// High altitude (usable above 18,000 ft).
  case high = "H"

  /// Low altitude (usable up to 18,000 ft).
  case low = "L"

  /// Terminal (usable within terminal area only).
  case terminal = "T"

  /// Undefined/unspecified.
  case undefined = "U"

  /// Both high and low altitude.
  case both = "B"
}

/// DME service volume type.
public enum DMEType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Standard DME.
  case standard = "D"

  /// Precision DME (DME/P).
  case precision = "P"

  /// No DME.
  case none = " "
}
