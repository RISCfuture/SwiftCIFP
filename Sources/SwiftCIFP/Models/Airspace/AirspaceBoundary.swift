import Foundation

/// A segment of an airspace boundary.
public struct AirspaceBoundary: Sendable, Codable, Equatable, Hashable {
  /// Sequence number of this boundary segment.
  public let sequenceNumber: Int

  /// Boundary definition type.
  public let boundaryVia: BoundaryVia?

  /// Coordinate of the boundary point.
  public let coordinate: Coordinate?

  /// Arc origin coordinate (for arc boundaries).
  public let arcOrigin: Coordinate?

  /// Arc bearing from origin in degrees.
  public let arcBearingDeg: Double?

  /// Arc distance/radius in nautical miles.
  public let arcDistanceNM: Double?
}

// MARK: - Measurement Extensions

extension AirspaceBoundary {
  /// Arc bearing as a Measurement.
  public var arcBearing: Measurement<UnitAngle>? {
    arcBearingDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Arc distance/radius as a Measurement.
  public var arcDistance: Measurement<UnitLength>? {
    arcDistanceNM.map { .init(value: $0, unit: .nauticalMiles) }
  }
}

// MARK: - Comparable

extension AirspaceBoundary: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.sequenceNumber < rhs.sequenceNumber
  }
}
