import CoreLocation
import Foundation

/// Terminal Waypoint record.
///
/// Waypoints defined within a terminal area, typically used in
/// SID, STAR, and approach procedures.
public struct TerminalWaypoint: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Waypoint identifier.
  public let identifier: String

  /// Waypoint ICAO region (may differ from airport).
  public let waypointICAO: String

  /// Waypoint type.
  public let waypointType: WaypointType?

  /// Waypoint usage.
  public let waypointUsage: WaypointUsage?

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation at waypoint.
  public let magneticVariation: MagneticVariation

  /// Waypoint name/description.
  public let name: String

  /// Creates a Terminal Waypoint record.
  init(
    airportId: String,
    icaoRegion: String,
    identifier: String,
    waypointICAO: String,
    waypointType: WaypointType?,
    waypointUsage: WaypointUsage?,
    coordinate: Coordinate,
    magneticVariation: MagneticVariation,
    name: String
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.waypointICAO = waypointICAO
    self.waypointType = waypointType
    self.waypointUsage = waypointUsage
    self.coordinate = coordinate
    self.magneticVariation = magneticVariation
    self.name = name
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, identifier, waypointICAO
    case waypointType, waypointUsage, coordinate
    case magneticVariation, name
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension TerminalWaypoint: Identifiable, Equatable, Hashable {
  public var id: String { "\(airportId)-\(identifier)" }

  public static func == (lhs: TerminalWaypoint, rhs: TerminalWaypoint) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Linked Properties

extension TerminalWaypoint {
  /// The parent airport.
  ///
  /// This property resolves the `airportId` to the actual `Airport` object
  /// when linked via `CIFPData`.
  public var airport: Airport? {
    get async {
      guard let data else { return nil }
      return await data.airport(airportId)
    }
  }
}
