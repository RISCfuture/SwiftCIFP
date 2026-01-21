import CoreLocation
import Foundation

/// Heliport terminal waypoint.
public struct HeliportWaypoint: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent heliport ICAO identifier.
  let parentId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Waypoint identifier.
  public let identifier: String

  /// Geographic coordinate.
  public let coordinate: Coordinate

  /// Magnetic variation.
  public let magneticVariation: MagneticVariation?

  /// Waypoint name.
  public let name: String?

  /// Creates a HeliportWaypoint record.
  init(
    parentId: String,
    icaoRegion: String,
    identifier: String,
    coordinate: Coordinate,
    magneticVariation: MagneticVariation?,
    name: String?
  ) {
    self.parentId = parentId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.coordinate = coordinate
    self.magneticVariation = magneticVariation
    self.name = name
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case parentId, icaoRegion, identifier, coordinate
    case magneticVariation, name
    // Note: 'data' is excluded
  }
}

// MARK: - HeliportWaypoint Identifiable, Equatable, Hashable

extension HeliportWaypoint: Identifiable, Equatable, Hashable {
  public var id: String { "\(parentId)-\(identifier)" }

  public static func == (lhs: HeliportWaypoint, rhs: HeliportWaypoint) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - HeliportWaypoint Linked Properties

extension HeliportWaypoint {
  /// The parent heliport.
  ///
  /// This property resolves the `parentId` to the actual `Heliport` object
  /// when linked via `CIFPData`.
  public var heliport: Heliport? {
    get async {
      guard let data else { return nil }
      return await data.heliport(parentId)
    }
  }
}
