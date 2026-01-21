import Foundation

/// Waypoint description code position 1 - Airport/Heliport reference.
public enum WaypointDescPosition1: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Airport as waypoint.
  case airport = "A"

  /// Essential waypoint.
  case essential = "E"

  /// Off airway.
  case offAirway = "F"

  /// Runway as waypoint.
  case runway = "G"

  /// Heliport as waypoint.
  case heliport = "H"

  /// NDB navaid.
  case ndb = "N"

  /// Phantom waypoint.
  case phantom = "P"

  /// Non-essential reporting.
  case nonEssential = "R"

  /// Transition.
  case transition = "T"

  /// VHF navaid.
  case vhf = "V"
}

/// Waypoint description code position 2 - Waypoint location.
public enum WaypointDescPosition2: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Final approach.
  case finalApproach = "A"

  /// Initial/intermediate approach.
  case initialIntermediate = "B"

  /// Terminal.
  case terminal = "C"

  /// SID.
  case sid = "D"

  /// Enroute.
  case enroute = "E"

  /// Missed approach.
  case missedApproach = "M"

  /// Oceanic.
  case oceanic = "O"

  /// STAR.
  case star = "R"
}

/// Waypoint description code position 3 - Waypoint function.
public enum WaypointDescPosition3: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Arrival waypoint.
  case arrival = "A"

  /// RF leg center fix.
  case rfCenter = "B"

  /// Intermediate approach hold.
  case intermediateHold = "C"

  /// SID/STAR.
  case sidStar = "D"

  /// Procedure end.
  case procedureEnd = "E"

  /// Published hold.
  case publishedHold = "H"

  /// Final approach course fix.
  case finalApproachCourse = "I"

  /// FAF.
  case finalApproachFix = "K"

  /// MAP.
  case missedApproachPoint = "M"

  /// Path point fix.
  case pathPoint = "P"

  /// Course reversal.
  case courseReversal = "R"

  /// Step down fix.
  case stepDownFix = "S"
}

/// Waypoint description code position 4 - Navigation specification.
public enum WaypointDescPosition4: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// ATC compulsory reporting.
  case atcCompulsory = "A"

  /// Conditional reporting.
  case conditional = "C"

  /// End of route.
  case endOfRoute = "E"

  /// GPS required.
  case gpsRequired = "G"

  /// NDB required.
  case ndbRequired = "N"

  /// Continuous reporting.
  case continuous = "P"

  /// VOR required.
  case vorRequired = "V"
}

/// Waypoint description code (4 positions).
///
/// Each position in the 4-character code has specific meaning.
public struct WaypointDescriptionCode: Sendable, Codable, Equatable, Hashable {
  /// Position 1 - Airport/Heliport reference.
  public let position1: WaypointDescPosition1?

  /// Position 2 - Waypoint location.
  public let position2: WaypointDescPosition2?

  /// Position 3 - Waypoint function.
  public let position3: WaypointDescPosition3?

  /// Position 4 - Navigation specification.
  public let position4: WaypointDescPosition4?

  /// Whether this is a final approach fix (FAF).
  public var isFAF: Bool {
    position3 == .finalApproachFix
  }

  /// Whether this is a missed approach point (MAP).
  public var isMAP: Bool {
    position3 == .missedApproachPoint
  }

  /// Whether this is a step-down fix.
  public var isStepDown: Bool {
    position3 == .stepDownFix
  }

  /// Whether this is a flyover waypoint.
  public var isFlyover: Bool {
    position1 == .essential
  }

  /// Creates a waypoint description code.
  init(
    position1: WaypointDescPosition1?,
    position2: WaypointDescPosition2?,
    position3: WaypointDescPosition3?,
    position4: WaypointDescPosition4?
  ) {
    self.position1 = position1
    self.position2 = position2
    self.position3 = position3
    self.position4 = position4
  }
}
