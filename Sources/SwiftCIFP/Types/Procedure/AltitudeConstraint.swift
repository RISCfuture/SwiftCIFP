import Foundation

/// Type-safe altitude constraint for procedure legs (ARINC 424 field 5.29).
///
/// Combines the altitude description code with the appropriate altitude value(s),
/// eliminating invalid states such as a `between` constraint with only one altitude.
///
/// In final approach coding a fix can carry two altitudes: the procedure altitude, which is
/// the crossing restriction at the fix, and a second altitude on the glide slope or coded
/// vertical path. The cases that carry both name the procedure altitude first.
public enum AltitudeConstraint: Sendable, Codable, Equatable, Hashable {

  // MARK: - Single Altitude Cases

  /// At or above the specified altitude (+).
  case atOrAbove(Altitude)

  /// At or below the specified altitude (-).
  case atOrBelow(Altitude)

  /// At the specified altitude (@ or blank).
  case at(Altitude)

  /// At or above the specified altitude, as a conditional altitude termination on a SID
  /// leg (C).
  case conditionalAtOrAbove(Altitude)

  // MARK: - Two Altitude Cases

  /// At or above the lower altitude and at or below the upper altitude (B).
  case between(lower: Altitude, upper: Altitude)

  /// At the procedure altitude, with the glide slope altitude at the FAF (G).
  case atWithGlideSlope(Altitude, glideSlope: Altitude)

  /// At or above the procedure altitude, with the glide slope altitude at the FAF (H).
  case atOrAboveWithGlideSlope(Altitude, glideSlope: Altitude)

  /// At the procedure altitude, with the glide slope intercept altitude at the FACF (I).
  case atWithGlideSlopeIntercept(Altitude, intercept: Altitude)

  /// At or above the procedure altitude, with the glide slope intercept altitude at the
  /// FACF (J).
  case atOrAboveWithGlideSlopeIntercept(Altitude, intercept: Altitude)

  /// At or above the procedure altitude, with the altitude on the coded vertical path at a
  /// step-down fix (V).
  case atOrAboveWithVerticalPath(Altitude, verticalPath: Altitude)

  /// At the procedure altitude, with the altitude on the coded vertical path at a step-down
  /// fix (X).
  case atWithVerticalPath(Altitude, verticalPath: Altitude)

  /// At or below the procedure altitude, with the altitude on the coded vertical path at a
  /// step-down fix (Y).
  case atOrBelowWithVerticalPath(Altitude, verticalPath: Altitude)
}

// MARK: - Factory Method

extension AltitudeConstraint {
  /// Creates an `AltitudeConstraint` from parsed altitude description and values.
  ///
  /// A description that pairs a procedure altitude with a glide slope or vertical path
  /// altitude yields the procedure altitude's restriction alone when the second altitude
  /// is blank.
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
        return altitude1.map(Self.atOrAbove)
      case .atOrBelow:
        return altitude1.map(Self.atOrBelow)
      case .at:
        return altitude1.map(Self.at)
      case .conditionalAtOrAbove:
        return altitude2.map(Self.conditionalAtOrAbove)
      case .between:
        guard let altitude1, let altitude2 else { return nil }
        return .between(lower: altitude2, upper: altitude1)
      case .atWithGlideSlope:
        return procedureAltitude(altitude1, altitude2, Self.atWithGlideSlope, else: Self.at)
      case .atOrAboveWithGlideSlope:
        return procedureAltitude(
          altitude1,
          altitude2,
          Self.atOrAboveWithGlideSlope,
          else: Self.atOrAbove
        )
      case .atWithGlideSlopeIntercept:
        return procedureAltitude(
          altitude1,
          altitude2,
          Self.atWithGlideSlopeIntercept,
          else: Self.at
        )
      case .atOrAboveWithGlideSlopeIntercept:
        return procedureAltitude(
          altitude1,
          altitude2,
          Self.atOrAboveWithGlideSlopeIntercept,
          else: Self.atOrAbove
        )
      case .atOrAboveWithVerticalPath:
        return procedureAltitude(
          altitude1,
          altitude2,
          Self.atOrAboveWithVerticalPath,
          else: Self.atOrAbove
        )
      case .atWithVerticalPath:
        return procedureAltitude(altitude1, altitude2, Self.atWithVerticalPath, else: Self.at)
      case .atOrBelowWithVerticalPath:
        return procedureAltitude(
          altitude1,
          altitude2,
          Self.atOrBelowWithVerticalPath,
          else: Self.atOrBelow
        )
    }
  }

  private static func procedureAltitude(
    _ procedure: Altitude?,
    _ second: Altitude?,
    _ paired: (Altitude, Altitude) -> Self,
    else alone: (Altitude) -> Self
  ) -> Self? {
    guard let procedure else { return nil }
    return second.map { paired(procedure, $0) } ?? alone(procedure)
  }
}

// MARK: - Helper Properties

extension AltitudeConstraint {
  /// The ARINC 424 description code character.
  public var descriptionCode: Character {
    switch self {
      case .atOrAbove: "+"
      case .atOrBelow: "-"
      case .at: "@"
      case .conditionalAtOrAbove: "C"
      case .between: "B"
      case .atWithGlideSlope: "G"
      case .atOrAboveWithGlideSlope: "H"
      case .atWithGlideSlopeIntercept: "I"
      case .atOrAboveWithGlideSlopeIntercept: "J"
      case .atOrAboveWithVerticalPath: "V"
      case .atWithVerticalPath: "X"
      case .atOrBelowWithVerticalPath: "Y"
    }
  }
}

// MARK: - CustomStringConvertible

extension AltitudeConstraint: CustomStringConvertible {
  public var description: String {
    switch self {
      case .atOrAbove(let alt):
        "at or above \(alt)"
      case .atOrBelow(let alt):
        "at or below \(alt)"
      case .at(let alt):
        "at \(alt)"
      case .conditionalAtOrAbove(let alt):
        "conditionally at or above \(alt)"
      case let .between(lower, upper):
        "between \(lower) and \(upper)"
      case let .atWithGlideSlope(alt, glideSlope):
        "at \(alt), glide slope \(glideSlope)"
      case let .atOrAboveWithGlideSlope(alt, glideSlope):
        "at or above \(alt), glide slope \(glideSlope)"
      case let .atWithGlideSlopeIntercept(alt, intercept):
        "at \(alt), glide slope intercept \(intercept)"
      case let .atOrAboveWithGlideSlopeIntercept(alt, intercept):
        "at or above \(alt), glide slope intercept \(intercept)"
      case let .atOrAboveWithVerticalPath(alt, verticalPath):
        "at or above \(alt), vertical path \(verticalPath)"
      case let .atWithVerticalPath(alt, verticalPath):
        "at \(alt), vertical path \(verticalPath)"
      case let .atOrBelowWithVerticalPath(alt, verticalPath):
        "at or below \(alt), vertical path \(verticalPath)"
    }
  }
}

// MARK: - Codable

extension AltitudeConstraint {
  // swiftlint:disable:next missing_docs
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(ConstraintType.self, forKey: .type)

    func altitude(_ key: CodingKeys = .altitude) throws -> Altitude {
      try container.decode(Altitude.self, forKey: key)
    }

    switch type {
      case .atOrAbove:
        self = .atOrAbove(try altitude())
      case .atOrBelow:
        self = .atOrBelow(try altitude())
      case .at:
        self = .at(try altitude())
      case .conditionalAtOrAbove:
        self = .conditionalAtOrAbove(try altitude())
      case .between:
        self = .between(lower: try altitude(.lower), upper: try altitude(.upper))
      case .atWithGlideSlope:
        self = .atWithGlideSlope(try altitude(), glideSlope: try altitude(.glideSlope))
      case .atOrAboveWithGlideSlope:
        self = .atOrAboveWithGlideSlope(try altitude(), glideSlope: try altitude(.glideSlope))
      case .atWithGlideSlopeIntercept:
        self = .atWithGlideSlopeIntercept(try altitude(), intercept: try altitude(.intercept))
      case .atOrAboveWithGlideSlopeIntercept:
        self = .atOrAboveWithGlideSlopeIntercept(
          try altitude(),
          intercept: try altitude(.intercept)
        )
      case .atOrAboveWithVerticalPath:
        self = .atOrAboveWithVerticalPath(try altitude(), verticalPath: try altitude(.verticalPath))
      case .atWithVerticalPath:
        self = .atWithVerticalPath(try altitude(), verticalPath: try altitude(.verticalPath))
      case .atOrBelowWithVerticalPath:
        self = .atOrBelowWithVerticalPath(try altitude(), verticalPath: try altitude(.verticalPath))
    }
  }

  // swiftlint:disable:next missing_docs
  public func encode(to encoder: any Encoder) throws {
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
      case .conditionalAtOrAbove(let alt):
        try container.encode(ConstraintType.conditionalAtOrAbove, forKey: .type)
        try container.encode(alt, forKey: .altitude)
      case let .between(lower, upper):
        try container.encode(ConstraintType.between, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
      case let .atWithGlideSlope(alt, glideSlope):
        try container.encode(ConstraintType.atWithGlideSlope, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(glideSlope, forKey: .glideSlope)
      case let .atOrAboveWithGlideSlope(alt, glideSlope):
        try container.encode(ConstraintType.atOrAboveWithGlideSlope, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(glideSlope, forKey: .glideSlope)
      case let .atWithGlideSlopeIntercept(alt, intercept):
        try container.encode(ConstraintType.atWithGlideSlopeIntercept, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(intercept, forKey: .intercept)
      case let .atOrAboveWithGlideSlopeIntercept(alt, intercept):
        try container.encode(ConstraintType.atOrAboveWithGlideSlopeIntercept, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(intercept, forKey: .intercept)
      case let .atOrAboveWithVerticalPath(alt, verticalPath):
        try container.encode(ConstraintType.atOrAboveWithVerticalPath, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(verticalPath, forKey: .verticalPath)
      case let .atWithVerticalPath(alt, verticalPath):
        try container.encode(ConstraintType.atWithVerticalPath, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(verticalPath, forKey: .verticalPath)
      case let .atOrBelowWithVerticalPath(alt, verticalPath):
        try container.encode(ConstraintType.atOrBelowWithVerticalPath, forKey: .type)
        try container.encode(alt, forKey: .altitude)
        try container.encode(verticalPath, forKey: .verticalPath)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case type
    case altitude
    case lower
    case upper
    case glideSlope
    case intercept
    case verticalPath
  }

  // swiftlint:disable raw_value_for_camel_cased_codable_enum
  private enum ConstraintType: String, Codable {
    case atOrAbove
    case atOrBelow
    case at
    case conditionalAtOrAbove
    case between
    case atWithGlideSlope
    case atOrAboveWithGlideSlope
    case atWithGlideSlopeIntercept
    case atOrAboveWithGlideSlopeIntercept
    case atOrAboveWithVerticalPath
    case atWithVerticalPath
    case atOrBelowWithVerticalPath
  }
  // swiftlint:enable raw_value_for_camel_cased_codable_enum
}
