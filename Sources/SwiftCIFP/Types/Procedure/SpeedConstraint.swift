import Foundation

/// Speed limit description code.
enum SpeedLimitDescription: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// At speed.
  case at = "@"

  /// At or above speed.
  case atOrAbove = "+"

  /// At or below speed.
  case atOrBelow = "-"
}

/// Type-safe speed constraint for procedure legs.
///
/// Combines the speed limit description code with the speed value,
/// eliminating invalid states such as a speed constraint without a value.
public enum SpeedConstraint: Sendable, Codable, Equatable, Hashable {

  /// At the specified speed (@).
  case at(knots: Int)

  /// At or above the specified speed (+).
  case atOrAbove(knots: Int)

  /// At or below the specified speed (-).
  case atOrBelow(knots: Int)
}

// MARK: - Factory Method

extension SpeedConstraint {
  /// Creates a `SpeedConstraint` from parsed speed limit and description.
  ///
  /// - Parameters:
  ///   - speedKnots: The speed limit in knots.
  ///   - description: The speed limit description code.
  /// - Returns: A `SpeedConstraint` if both values are present, or `nil` otherwise.
  static func from(
    speedKnots: Int?,
    description: SpeedLimitDescription?
  ) -> SpeedConstraint? {
    guard let speedKnots, let description else { return nil }

    switch description {
      case .at:
        return .at(knots: speedKnots)
      case .atOrAbove:
        return .atOrAbove(knots: speedKnots)
      case .atOrBelow:
        return .atOrBelow(knots: speedKnots)
    }
  }
}

// MARK: - Helper Properties

extension SpeedConstraint {
  /// The speed value in knots.
  public var knots: Int {
    switch self {
      case .at(let knots),
        .atOrAbove(let knots),
        .atOrBelow(let knots):
        return knots
    }
  }

  /// The speed as a Measurement.
  public var speed: Measurement<UnitSpeed> {
    .init(value: Double(knots), unit: .knots)
  }

  /// The ARINC 424 description code character.
  public var descriptionCode: Character {
    switch self {
      case .at: return "@"
      case .atOrAbove: return "+"
      case .atOrBelow: return "-"
    }
  }
}

// MARK: - CustomStringConvertible

extension SpeedConstraint: CustomStringConvertible {
  public var description: String {
    switch self {
      case .at(let knots):
        return "at \(knots) kts"
      case .atOrAbove(let knots):
        return "at or above \(knots) kts"
      case .atOrBelow(let knots):
        return "at or below \(knots) kts"
    }
  }
}

// MARK: - Contains

extension SpeedConstraint {
  /// Returns whether the given speed in knots satisfies this constraint.
  public func contains(_ speedKnots: Int) -> Bool {
    switch self {
      case .at(let knots):
        return speedKnots == knots
      case .atOrAbove(let knots):
        return speedKnots >= knots
      case .atOrBelow(let knots):
        return speedKnots <= knots
    }
  }

  /// Returns whether the given speed measurement satisfies this constraint.
  public func contains(_ speed: Measurement<UnitSpeed>) -> Bool {
    contains(Int(speed.converted(to: .knots).value.rounded()))
  }
}
