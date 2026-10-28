public import Foundation

/// A course or bearing, and the north it is measured from.
///
/// ARINC 424 publishes magnetic values in tenths of a degree and true values in whole degrees
/// followed by "T" (fields 5.26, 5.28, 5.47, and 5.58).
public struct Course: Sendable, Codable, Equatable, Hashable {
  /// The course in degrees.
  public let degrees: Double

  /// Whether the course is magnetic or true.
  public let reference: BearingReference

  /// The course as a Measurement.
  public var angle: Measurement<UnitAngle> {
    .init(value: degrees, unit: .degrees)
  }
}
