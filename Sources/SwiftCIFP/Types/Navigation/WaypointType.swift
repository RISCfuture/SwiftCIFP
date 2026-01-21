import Foundation

/// Waypoint type classification.
public enum WaypointType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Combined VHF/NDB navaid waypoint.
  case combinedNavaid = "C"

  /// NDB navaid.
  case ndb = "N"

  /// VHF navaid (VOR, VORTAC, etc.).
  case vhf = "V"

  /// RNAV waypoint (ground-based reference).
  case rnav = "R"

  /// Waypoint (satellite-derived).
  case waypoint = "W"

  /// Airport as waypoint.
  case airport = "A"

  /// Runway as waypoint.
  case runway = "G"

  /// Heliport as waypoint.
  case heliport = "H"

  /// ILS marker beacon.
  case marker = "M"

  /// Other type.
  case other = " "
}

/// Waypoint usage indicator for terminal waypoints.
public enum WaypointUsage: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Both RNAV and conventional procedures.
  case both = "B"

  /// High altitude.
  case high = "H"

  /// Low altitude.
  case low = "L"

  /// Terminal area only.
  case terminal = "T"

  /// RNAV procedures only.
  case rnav = "R"

  /// Unspecified.
  case unspecified = " "
}

/// Waypoint name format indicator.
public enum WaypointNameFormat: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Five-letter name format.
  case fiveLetter = "A"

  /// Five-letter name format (alternate).
  case fiveLetterAlt = "D"

  /// Coordinate-based name.
  case coordinate = "E"

  /// Airport/runway reference.
  case airportRunway = "F"

  /// Other format.
  case other = " "
}
