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
