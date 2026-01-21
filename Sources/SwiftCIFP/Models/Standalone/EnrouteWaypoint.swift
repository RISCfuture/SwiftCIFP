import CoreLocation
import Foundation

/// Enroute Waypoint record.
///
/// Waypoints are named geographic positions used for navigation,
/// particularly for RNAV and GPS procedures.
public struct EnrouteWaypoint: Sendable, Codable {
  /// The waypoint identifier (typically 5 characters).
  public let identifier: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Waypoint type.
  public let waypointType: WaypointType

  /// Waypoint usage class.
  public let usageClass: WaypointUsage?

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation at the waypoint location.
  public let magneticVariation: MagneticVariation

  /// Waypoint name/description.
  public let name: String
}

// MARK: - CustomStringConvertible

extension EnrouteWaypoint: CustomStringConvertible {
  public var description: String {
    identifier
  }
}
