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

  /// The altitude structure the waypoint is used in.
  public let usage: Usage

  /// Whether the waypoint is used on RNAV routes.
  public let isRNAV: Bool

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation at the waypoint location.
  public let magneticVariation: MagneticVariation

  /// Waypoint name/description.
  public let name: String
}

// MARK: - Usage

extension EnrouteWaypoint {
  /// The altitude structure an enroute waypoint is used in (ARINC 424 field 5.82,
  /// column 31).
  public enum Usage: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// High and low altitude.
    case highAndLowAltitude = "B"

    /// High altitude.
    case highAltitude = "H"

    /// Low altitude.
    case lowAltitude = "L"

    /// Terminal use only, published as a blank column.
    case terminalOnly = " "
  }
}

// MARK: - CustomStringConvertible

extension EnrouteWaypoint: CustomStringConvertible {
  public var description: String {
    identifier
  }
}
