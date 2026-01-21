import Foundation

/// Turn direction for procedure legs.
public enum TurnDirection: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Left turn.
  case left = "L"

  /// Right turn.
  case right = "R"

  /// Either direction (pilot's choice).
  case either = "E"
}
