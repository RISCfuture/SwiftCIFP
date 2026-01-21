import Foundation

/// Runway surface type.
public enum RunwaySurface: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Hard surface (concrete, asphalt).
  case hard = "H"

  /// Soft surface (grass, dirt, gravel).
  case soft = "S"

  /// Water (seaplane base).
  case water = "W"

  /// Unknown surface type.
  case unknown = "U"
}

/// Airport public/military status.
public enum PublicMilitary: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Civil/public airport.
  case civil = "C"

  /// Military airport.
  case military = "M"

  /// Joint use (civil and military).
  case joint = "J"

  /// Private airport.
  case `private` = "P"
}

/// IFR capability indicator.
public enum IFRCapability: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// IFR capable.
  case ifr = "Y"

  /// VFR only.
  case vfr = "N"
}
