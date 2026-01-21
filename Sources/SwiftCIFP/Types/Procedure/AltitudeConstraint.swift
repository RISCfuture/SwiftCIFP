import Foundation

/// Type-safe altitude constraint for procedure legs.
///
/// Combines the altitude description code with the appropriate altitude value(s),
/// eliminating invalid states such as a `between` constraint with only one altitude.
public enum AltitudeConstraint: Sendable, Codable, Equatable, Hashable {

  // MARK: - Single Altitude Cases

  /// At or above the specified altitude (+).
  case atOrAbove(Altitude)

  /// At or below the specified altitude (-).
  case atOrBelow(Altitude)

  /// At the specified altitude (@).
  case at(Altitude)

  /// Glide slope intercept altitude for ILS (G).
  case glideSlopeIntercept(Altitude)

  /// Glide path intercept altitude for RNAV (H).
  case glidePathIntercept(Altitude)

  // MARK: - Two Altitude Cases

  /// Between lower and upper altitudes (B).
  case between(lower: Altitude, upper: Altitude)

  /// At or above lower to at or below upper (I).
  case atOrAboveToAtOrBelow(lower: Altitude, upper: Altitude)

  /// At or above lower to at upper (J).
  case atOrAboveToAt(lower: Altitude, upper: Altitude)

  /// At lower to at or below upper (V).
  case atToAtOrBelow(lower: Altitude, upper: Altitude)

  /// At lower to at or above upper (X).
  case atToAtOrAbove(lower: Altitude, upper: Altitude)

  /// At or below lower to at or above upper (Y).
  case atOrBelowToAtOrAbove(lower: Altitude, upper: Altitude)
}

// MARK: - Factory Method

extension AltitudeConstraint {
  /// Creates an `AltitudeConstraint` from parsed altitude description and values.
  ///
  /// - Parameters:
  ///   - description: The altitude description code.
  ///   - altitude1: The first altitude value.
  ///   - altitude2: The second altitude value (for two-altitude constraints).
  /// - Returns: An `AltitudeConstraint` if valid, or `nil` if the combination is invalid.
  static func from(
    description: AltitudeDescription,
    altitude1: Altitude?,
    altitude2: Altitude?
  ) -> AltitudeConstraint? {
    switch description {
      case .atOrAbove:
        guard let altitude1 else { return nil }
        return .atOrAbove(altitude1)

      case .atOrBelow:
        guard let altitude1 else { return nil }
        return .atOrBelow(altitude1)

      case .at:
        guard let altitude1 else { return nil }
        return .at(altitude1)

      case .glideSlopeIntercept:
        guard let altitude1 else { return nil }
        return .glideSlopeIntercept(altitude1)

      case .glidePathIntercept:
        guard let altitude1 else { return nil }
        return .glidePathIntercept(altitude1)

      case .between:
        guard let altitude1, let altitude2 else { return nil }
        return .between(lower: altitude1, upper: altitude2)

      case .atOrAboveToAtOrBelow:
        guard let altitude1, let altitude2 else { return nil }
        return .atOrAboveToAtOrBelow(lower: altitude1, upper: altitude2)

      case .atOrAboveToAt:
        guard let altitude1, let altitude2 else { return nil }
        return .atOrAboveToAt(lower: altitude1, upper: altitude2)

      case .atToAtOrBelow:
        guard let altitude1, let altitude2 else { return nil }
        return .atToAtOrBelow(lower: altitude1, upper: altitude2)

      case .atToAtOrAbove:
        guard let altitude1, let altitude2 else { return nil }
        return .atToAtOrAbove(lower: altitude1, upper: altitude2)

      case .atOrBelowToAtOrAbove:
        guard let altitude1, let altitude2 else { return nil }
        return .atOrBelowToAtOrAbove(lower: altitude1, upper: altitude2)
    }
  }
}

// MARK: - Helper Properties

extension AltitudeConstraint {
  /// The ARINC 424 description code character.
  public var descriptionCode: Character {
    switch self {
      case .atOrAbove: return "+"
      case .atOrBelow: return "-"
      case .at: return "@"
      case .glideSlopeIntercept: return "G"
      case .glidePathIntercept: return "H"
      case .between: return "B"
      case .atOrAboveToAtOrBelow: return "I"
      case .atOrAboveToAt: return "J"
      case .atToAtOrBelow: return "V"
      case .atToAtOrAbove: return "X"
      case .atOrBelowToAtOrAbove: return "Y"
    }
  }
}

// MARK: - CustomStringConvertible

extension AltitudeConstraint: CustomStringConvertible {
  public var description: String {
    switch self {
      case .atOrAbove(let alt):
        return "at or above \(alt)"
      case .atOrBelow(let alt):
        return "at or below \(alt)"
      case .at(let alt):
        return "at \(alt)"
      case .glideSlopeIntercept(let alt):
        return "glide slope intercept at \(alt)"
      case .glidePathIntercept(let alt):
        return "glide path intercept at \(alt)"
      case let .between(lower, upper):
        return "between \(lower) and \(upper)"
      case let .atOrAboveToAtOrBelow(lower, upper):
        return "at or above \(lower) to at or below \(upper)"
      case let .atOrAboveToAt(lower, upper):
        return "at or above \(lower) to at \(upper)"
      case let .atToAtOrBelow(lower, upper):
        return "at \(lower) to at or below \(upper)"
      case let .atToAtOrAbove(lower, upper):
        return "at \(lower) to at or above \(upper)"
      case let .atOrBelowToAtOrAbove(lower, upper):
        return "at or below \(lower) to at or above \(upper)"
    }
  }
}

// MARK: - Codable

extension AltitudeConstraint {
  // swiftlint:disable:next missing_docs
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(ConstraintType.self, forKey: .type)

    switch type {
      case .atOrAbove:
        let alt = try container.decode(Altitude.self, forKey: .altitude)
        self = .atOrAbove(alt)
      case .atOrBelow:
        let alt = try container.decode(Altitude.self, forKey: .altitude)
        self = .atOrBelow(alt)
      case .at:
        let alt = try container.decode(Altitude.self, forKey: .altitude)
        self = .at(alt)
      case .glideSlopeIntercept:
        let alt = try container.decode(Altitude.self, forKey: .altitude)
        self = .glideSlopeIntercept(alt)
      case .glidePathIntercept:
        let alt = try container.decode(Altitude.self, forKey: .altitude)
        self = .glidePathIntercept(alt)
      case .between:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .between(lower: lower, upper: upper)
      case .atOrAboveToAtOrBelow:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .atOrAboveToAtOrBelow(lower: lower, upper: upper)
      case .atOrAboveToAt:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .atOrAboveToAt(lower: lower, upper: upper)
      case .atToAtOrBelow:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .atToAtOrBelow(lower: lower, upper: upper)
      case .atToAtOrAbove:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .atToAtOrAbove(lower: lower, upper: upper)
      case .atOrBelowToAtOrAbove:
        let lower = try container.decode(Altitude.self, forKey: .lower)
        let upper = try container.decode(Altitude.self, forKey: .upper)
        self = .atOrBelowToAtOrAbove(lower: lower, upper: upper)
    }
  }

  // swiftlint:disable:next missing_docs
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .atOrAbove(let alt):
        try container.encode(ConstraintType.atOrAbove, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case .atOrBelow(let alt):
        try container.encode(ConstraintType.atOrBelow, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case .at(let alt):
        try container.encode(ConstraintType.at, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case .glideSlopeIntercept(let alt):
        try container.encode(ConstraintType.glideSlopeIntercept, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case .glidePathIntercept(let alt):
        try container.encode(ConstraintType.glidePathIntercept, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case let .between(lower, upper):
        try container.encode(ConstraintType.between, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atOrAboveToAtOrBelow(lower, upper):
        try container.encode(ConstraintType.atOrAboveToAtOrBelow, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atOrAboveToAt(lower, upper):
        try container.encode(ConstraintType.atOrAboveToAt, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atToAtOrBelow(lower, upper):
        try container.encode(ConstraintType.atToAtOrBelow, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atToAtOrAbove(lower, upper):
        try container.encode(ConstraintType.atToAtOrAbove, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atOrBelowToAtOrAbove(lower, upper):
        try container.encode(ConstraintType.atOrBelowToAtOrAbove, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case type
    case altitude
    case lower
    case upper
  }

  // swiftlint:disable raw_value_for_camel_cased_codable_enum
  private enum ConstraintType: String, Codable {
    case atOrAbove
    case atOrBelow
    case at
    case glideSlopeIntercept
    case glidePathIntercept
    case between
    case atOrAboveToAtOrBelow
    case atOrAboveToAt
    case atToAtOrBelow
    case atToAtOrAbove
    case atOrBelowToAtOrAbove
  }
  // swiftlint:enable raw_value_for_camel_cased_codable_enum
}
