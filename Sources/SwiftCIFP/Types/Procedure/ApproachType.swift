import Foundation

/// Approach type: the navigation an approach's final approach route is flown with.
public enum ApproachType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Localizer back course.
  case localizerBackcourse = "B"

  /// VOR/DME approach.
  case vorDME = "D"

  /// Flight management system (FMS) approach.
  case fms = "F"

  /// IGS (Interim GPS approach).
  case igs = "G"

  /// RNP/RNAV (AR) approach.
  case rnpAR = "H"

  /// ILS approach.
  case ils = "I"

  /// GLS/GBAS approach.
  case gls = "J"

  /// Localizer only.
  case localizerOnly = "L"

  /// MLS approach.
  case mls = "M"

  /// NDB approach.
  case ndb = "N"

  /// GPS approach.
  case gps = "P"

  /// NDB/DME approach.
  case ndbDME = "Q"

  /// RNAV approach.
  case rnav = "R"

  /// VOR approach with TACAN.
  case vorTAC = "S"

  /// TACAN approach.
  case tacan = "T"

  /// SDF approach.
  case sdf = "U"

  /// VOR approach.
  case vor = "V"

  /// MLS Type A.
  case mlsTypeA = "W"

  /// LDA approach.
  case lda = "X"

  /// MLS Type B/C.
  case mlsTypeBC = "Y"

  public var description: String {
    switch self {
      case .localizerBackcourse: "LOC BC"
      case .vorDME: "VOR/DME"
      case .fms: "FMS"
      case .igs: "IGS"
      case .rnpAR: "RNP AR"
      case .ils: "ILS"
      case .gls: "GLS"
      case .localizerOnly: "LOC"
      case .mls: "MLS"
      case .ndb: "NDB"
      case .gps: "GPS"
      case .ndbDME: "NDB/DME"
      case .rnav: "RNAV"
      case .vorTAC: "VOR/TAC"
      case .tacan: "TACAN"
      case .sdf: "SDF"
      case .vor: "VOR"
      case .mlsTypeA: "MLS-A"
      case .lda: "LDA"
      case .mlsTypeBC: "MLS-BC"
    }
  }
}
