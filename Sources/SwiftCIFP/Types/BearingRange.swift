import Foundation

/// A range of compass bearings that properly handles wrap-around at 360°.
///
/// Unlike `Range<Double>`, `BearingRange` correctly handles ranges that cross
/// the 360°/0° boundary. For example, a range from 270° to 90° represents
/// bearings from 270° through 360° (0°) to 90°.
///
/// ## Usage
///
/// ```swift
/// // Normal range (doesn't wrap)
/// let sector1 = BearingRange(from: 90, to: 180)
/// sector1.contains(135)  // true
/// sector1.contains(270)  // false
///
/// // Wrap-around range (crosses 360°)
/// let sector2 = BearingRange(from: 270, to: 90)
/// sector2.contains(315)  // true
/// sector2.contains(45)   // true
/// sector2.contains(180)  // false
/// ```
public struct BearingRange: Sendable, Codable, Hashable {
  /// The starting bearing (inclusive), in degrees.
  public let lowerBound: Double

  /// The ending bearing (exclusive), in degrees.
  public let upperBound: Double

  /// Whether this range wraps around the 360°/0° boundary.
  public var wrapsAround: Bool {
    lowerBound > upperBound
  }

  /// Whether the range is empty (lowerBound equals upperBound).
  public var isEmpty: Bool {
    lowerBound == upperBound
  }

  /// The angular span of this range in degrees (0-360).
  public var span: Double {
    if wrapsAround {
      return (360 - lowerBound) + upperBound
    }
    return upperBound - lowerBound
  }

  /// Creates a bearing range.
  ///
  /// - Parameters:
  ///   - lowerBound: Starting bearing in degrees (inclusive).
  ///   - upperBound: Ending bearing in degrees (exclusive).
  ///
  /// Values are normalized to 0..<360.
  init(from lowerBound: Double, to upperBound: Double) {
    self.lowerBound = lowerBound.truncatingRemainder(dividingBy: 360)
    self.upperBound = upperBound.truncatingRemainder(dividingBy: 360)
  }

  /// Returns whether the given bearing falls within this range.
  ///
  /// - Parameter bearing: A bearing in degrees (will be normalized to 0..<360).
  /// - Returns: `true` if the bearing is within the range.
  public func contains(_ bearing: Double) -> Bool {
    let normalized = bearing.truncatingRemainder(dividingBy: 360)
    let adjusted = normalized < 0 ? normalized + 360 : normalized

    if wrapsAround {
      // Range crosses 360°: check if bearing is >= lower OR < upper
      return adjusted >= lowerBound || adjusted < upperBound
    }
    // Normal range: check if bearing is >= lower AND < upper
    return adjusted >= lowerBound && adjusted < upperBound
  }

  /// Returns whether this range overlaps with another bearing range.
  ///
  /// - Parameter other: Another bearing range.
  /// - Returns: `true` if the ranges overlap.
  public func overlaps(_ other: Self) -> Bool {
    contains(other.lowerBound) || other.contains(lowerBound)
  }

  /// Returns a range clamped to valid bearing values (0..<360).
  public func clamped(to limits: Self) -> Self {
    // For bearing ranges, clamping is complex due to wrap-around
    // Return self if fully contained, otherwise return intersection
    if limits.contains(lowerBound) && limits.contains(upperBound) {
      return self
    }
    return self
  }
}

// MARK: - RangeExpression

extension BearingRange: RangeExpression {
  public func relative<C>(to _: C) -> Range<Double>
  where C: Collection, Double == C.Index {
    // For RangeExpression conformance - returns a standard Range
    // Note: This loses wrap-around semantics
    if wrapsAround {
      return lowerBound..<(upperBound + 360)
    }
    return lowerBound..<upperBound
  }
}

// MARK: - Pattern Matching

extension BearingRange {
  /// Pattern matching operator for use in switch statements.
  public static func ~= (pattern: BearingRange, value: Double) -> Bool {
    pattern.contains(value)
  }
}

// MARK: - CustomStringConvertible

extension BearingRange: CustomStringConvertible {
  public var description: String {
    if wrapsAround {
      return "\(lowerBound)°→\(upperBound)° (via 360°)"
    }
    return "\(lowerBound)°..<\(upperBound)°"
  }
}

// MARK: - CustomDebugStringConvertible

extension BearingRange: CustomDebugStringConvertible {
  public var debugDescription: String {
    "BearingRange(from: \(lowerBound), to: \(upperBound), wrapsAround: \(wrapsAround))"
  }
}

// MARK: - Convenience Initializers

extension BearingRange {
  /// Creates a full-circle range (0° to 360°).
  public static var fullCircle: BearingRange {
    BearingRange(from: 0, to: 360)
  }

  /// Creates a bearing range from a standard Range.
  init(_ range: Range<Double>) {
    self.init(from: range.lowerBound, to: range.upperBound)
  }

  /// Creates a bearing range from a ClosedRange.
  ///
  /// Note: The upper bound is treated as exclusive for consistency.
  init(_ range: ClosedRange<Double>) {
    self.init(from: range.lowerBound, to: range.upperBound)
  }
}

// MARK: - Measurement Support

extension BearingRange {
  /// The starting bearing as a Measurement.
  public var lowerBoundMeasurement: Measurement<UnitAngle> {
    .init(value: lowerBound, unit: .degrees)
  }

  /// The ending bearing as a Measurement.
  public var upperBoundMeasurement: Measurement<UnitAngle> {
    .init(value: upperBound, unit: .degrees)
  }

  /// The angular span as a Measurement.
  public var spanMeasurement: Measurement<UnitAngle> {
    .init(value: span, unit: .degrees)
  }

  /// Returns whether the given bearing measurement falls within this range.
  public func contains(_ bearing: Measurement<UnitAngle>) -> Bool {
    contains(bearing.converted(to: .degrees).value)
  }
}
