import Foundation

/// Airspace classification.
public enum AirspaceClass: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Class A airspace.
  case classA = "A"

  /// Class B airspace.
  case classB = "B"

  /// Class C airspace.
  case classC = "C"

  /// Class D airspace.
  case classD = "D"

  /// Class E airspace.
  case classE = "E"

  /// Class G airspace (uncontrolled).
  case classG = "G"

  /// Human-readable name.
  var name: String {
    switch self {
      case .classA: "Class A"
      case .classB: "Class B"
      case .classC: "Class C"
      case .classD: "Class D"
      case .classE: "Class E"
      case .classG: "Class G"
    }
  }
}

/// Restrictive/special use airspace type.
public enum RestrictiveAirspaceType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Alert area.
  case alert = "A"

  /// Caution area.
  case caution = "C"

  /// Danger area.
  case danger = "D"

  /// Military Operations Area (MOA).
  case moa = "M"

  /// Prohibited area.
  case prohibited = "P"

  /// Restricted area.
  case restricted = "R"

  /// Temporary Reserved Airspace (TRA).
  case tra = "T"

  /// Special rules area (SFRA).
  case specialRules = "U"

  /// Warning area.
  case warning = "W"

  public var description: String {
    switch self {
      case .alert: "Alert"
      case .caution: "Caution"
      case .danger: "Danger"
      case .moa: "MOA"
      case .prohibited: "Prohibited"
      case .restricted: "Restricted"
      case .tra: "TRA"
      case .specialRules: "SFRA"
      case .warning: "Warning"
    }
  }
}

/// Boundary definition type.
public enum BoundaryVia: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Circle.
  case circle = "C"

  /// Great circle route.
  case greatCircle = "G"

  /// Rhumb line.
  case rhumbLine = "R"

  /// Arc, clockwise.
  case arcClockwise = "L"

  /// Arc, counter-clockwise.
  case arcCounterClockwise = "A"

  /// End of description.
  case end = "E"

  /// Return to origin.
  case returnToOrigin = "H"
}
