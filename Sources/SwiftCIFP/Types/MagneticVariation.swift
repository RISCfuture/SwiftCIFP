public import Foundation

/// Represents magnetic variation (declination) at a location.
///
/// Magnetic variation is the angle between magnetic north and true north.
/// East variation is positive, west variation is negative.
public struct MagneticVariation: Sendable, Codable, Equatable, Hashable {
  /// Direction of variation (east or west).
  public let direction: Direction

  /// Magnitude of variation in degrees (always positive).
  public let degrees: Double

  /// The signed value of magnetic variation.
  ///
  /// East is positive, west is negative.
  public var signedValue: Double {
    switch direction {
      case .east, .trueNorth: degrees
      case .west: -degrees
    }
  }

  /// Creates a magnetic variation.
  ///
  /// - Parameters:
  ///   - direction: East or west.
  ///   - degrees: Magnitude in degrees.
  init(direction: Direction, degrees: Double) {
    self.direction = direction
    self.degrees = degrees
  }
}

// MARK: - Measurement Extension

extension MagneticVariation {
  /// The magnetic variation as a signed Measurement of angle.
  ///
  /// East is positive, west is negative.
  public var measurement: Measurement<UnitAngle> {
    .init(value: signedValue, unit: .degrees)
  }
}

// MARK: - CustomStringConvertible

extension MagneticVariation: CustomStringConvertible {
  public var description: String {
    unsafe String(format: "%.1f°%@", degrees, String(direction.rawValue))
  }
}

// MARK: - Direction

extension MagneticVariation {
  /// Direction of magnetic variation.
  public enum Direction: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// East magnetic variation (positive).
    case east = "E"

    /// West magnetic variation (negative).
    case west = "W"

    /// Oriented to true north rather than magnetic north, where magnetic variation is
    /// unreliable.
    case trueNorth = "T"
  }
}
