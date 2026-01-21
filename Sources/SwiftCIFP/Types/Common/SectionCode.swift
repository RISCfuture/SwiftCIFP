import Foundation

/// CIFP section codes identifying record types.
///
/// The section code appears in positions 5-6 of each record and determines
/// how the record should be parsed.
public enum SectionCode: String, Sendable, Codable, CaseIterable {
  /// Grid MORA (Minimum Off-Route Altitude) records.
  case gridMORA = "AS"

  /// VHF Navaid records (VOR, VORTAC, DME).
  case vhfNavaid = "D "

  /// NDB Navaid records.
  case ndbNavaid = "DB"

  /// Enroute waypoint records.
  case enrouteWaypoint = "EA"

  /// Airway records.
  case airway = "ER"

  /// Heliport reference records.
  case heliportReference = "HA"

  /// Heliport terminal waypoint records.
  case heliportWaypoint = "HC"

  /// Heliport SID (Standard Instrument Departure) records.
  case heliportSID = "HD"

  /// Heliport STAR (Standard Terminal Arrival Route) records.
  case heliportSTAR = "HE"

  /// Heliport approach procedure records.
  case heliportApproach = "HF"

  /// Heliport MSA records.
  case heliportMSA = "HS"

  /// Airport reference records.
  case airport = "PA"

  /// Terminal waypoint records.
  case terminalWaypoint = "PC"

  /// SID (Standard Instrument Departure) records.
  case sid = "PD"

  /// STAR (Standard Terminal Arrival Route) records.
  case star = "PE"

  /// Approach procedure records.
  case approach = "PF"

  /// Runway records.
  case runway = "PG"

  /// Localizer/Glide Slope records.
  case localizer = "PI"

  /// Terminal navaid records.
  case terminalNavaid = "PN"

  /// Path point records.
  case pathPoint = "PP"

  /// MSA (Minimum Sector Altitude) records.
  case msa = "PS"

  /// Controlled airspace records.
  case controlledAirspace = "UC"

  /// Restrictive (special use) airspace records.
  case restrictiveAirspace = "UR"

  /// Whether this section is airport-associated.
  public var isAirportAssociated: Bool {
    switch self {
      case .airport, .terminalWaypoint, .sid, .star, .approach,
        .runway, .localizer, .terminalNavaid, .pathPoint, .msa:
        true
      default:
        false
    }
  }

  /// Whether this section is heliport-associated.
  public var isHeliportAssociated: Bool {
    switch self {
      case .heliportReference, .heliportWaypoint, .heliportSID, .heliportSTAR,
        .heliportApproach, .heliportMSA:
        true
      default:
        false
    }
  }
}
