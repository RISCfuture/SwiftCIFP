import Foundation

/// Approach type/route type qualifier.
public enum ApproachType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Approach transition.
  case transition = "A"

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

  /// Missed approach.
  case missedApproach = "Z"

  public var description: String {
    switch self {
      case .transition: "Transition"
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
      case .missedApproach: "Missed Approach"
    }
  }
}

/// SID route type (departure procedure).
public enum SIDRouteType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Engine out SID.
  case engineOut = "0"

  /// SID runway transition.
  case runwayTransition = "1"

  /// SID or SID common route.
  case commonRoute = "2"

  /// SID enroute transition.
  case enrouteTransition = "3"

  /// RNAV SID runway transition.
  case rnavRunwayTransition = "4"

  /// RNAV SID or common route.
  case rnavCommonRoute = "5"

  /// RNAV SID enroute transition.
  case rnavEnrouteTransition = "6"

  /// FMS SID runway transition.
  case fmsRunwayTransition = "F"

  /// FMS SID or common route.
  case fmsCommonRoute = "M"

  /// FMS SID enroute transition.
  case fmsEnrouteTransition = "S"

  /// Vector SID.
  case vector = "T"

  /// Vector SID enroute transition.
  case vectorEnrouteTransition = "V"
}

/// STAR route type (arrival procedure).
public enum STARRouteType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// STAR enroute transition.
  case enrouteTransition = "1"

  /// STAR or common route.
  case commonRoute = "2"

  /// STAR runway transition.
  case runwayTransition = "3"

  /// RNAV STAR enroute transition.
  case rnavEnrouteTransition = "4"

  /// RNAV STAR or common route.
  case rnavCommonRoute = "5"

  /// RNAV STAR runway transition.
  case rnavRunwayTransition = "6"

  /// Profile descent enroute transition.
  case profileDescentEnrouteTransition = "7"

  /// Profile descent common route.
  case profileDescentCommonRoute = "8"

  /// Profile descent runway transition.
  case profileDescentRunwayTransition = "9"

  /// FMS STAR enroute transition.
  case fmsEnrouteTransition = "F"

  /// FMS STAR or common route.
  case fmsCommonRoute = "M"

  /// FMS STAR runway transition.
  case fmsRunwayTransition = "S"
}

/// Approach route type qualifier.
public enum ApproachRouteType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Approach transition.
  case transition = "A"

  /// Primary missed approach.
  case primaryMissed = "B"

  /// Secondary missed approach.
  case secondaryMissed = "E"

  /// Final approach.
  case finalApproach = "F"

  /// Circle to land.
  case circleToLand = "C"

  /// Straight in.
  case straightIn = "S"

  /// Approach with procedure turn.
  case procedureTurn = "P"

  /// DME arc.
  case dmeArc = "D"

  /// Hold in lieu of procedure turn.
  case holdInLieu = "H"

  /// Vectors.
  case vectors = "V"

  /// No procedure turn.
  case noProcedureTurn = "N"

  /// Initial approach fix.
  case initialApproachFix = "I"
}
