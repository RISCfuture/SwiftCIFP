import Foundation

/// Reference system for bearings and courses.
public enum BearingReference: String, Sendable, Codable, Equatable, Hashable {
  /// Bearings referenced to magnetic north.
  case magnetic = "M"

  /// Bearings referenced to true north.
  case trueNorth = "T"
}
