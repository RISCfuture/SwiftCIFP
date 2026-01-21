import Foundation

/// A resolved navigation fix that can be any of the fix types in CIFP data.
///
/// Use this type when resolving fix references in procedures and airways.
/// The fix's actual type can be determined by pattern matching on the enum cases.
///
/// ## Example
///
/// ```swift
/// if let fix = await procedureLeg.fix {
///     switch fix {
///     case .vhfNavaid(let nav):
///         print("VOR: \(nav.name) at \(nav.frequencyMHz) MHz")
///     case .ndbNavaid(let nav):
///         print("NDB: \(nav.name) at \(nav.frequencyKHz) kHz")
///     case .enrouteWaypoint(let wp):
///         print("Waypoint: \(wp.identifier)")
///     case .terminalWaypoint(let wp):
///         print("Terminal waypoint: \(wp.identifier)")
///     }
/// }
/// ```
public enum Fix: Sendable {
  /// A VHF navaid (VOR, VORTAC, DME).
  case vhfNavaid(VHFNavaid)

  /// An NDB (Non-Directional Beacon).
  case ndbNavaid(NDBNavaid)

  /// An enroute waypoint.
  case enrouteWaypoint(EnrouteWaypoint)

  /// A terminal area waypoint.
  case terminalWaypoint(TerminalWaypoint)

  /// The identifier of the fix.
  public var identifier: String {
    switch self {
      case .vhfNavaid(let nav): return nav.identifier
      case .ndbNavaid(let nav): return nav.identifier
      case .enrouteWaypoint(let wp): return wp.identifier
      case .terminalWaypoint(let wp): return wp.identifier
    }
  }

  /// The coordinate of the fix.
  public var coordinate: Coordinate? {
    switch self {
      case .vhfNavaid(let nav): return nav.coordinate
      case .ndbNavaid(let nav): return nav.coordinate
      case .enrouteWaypoint(let wp): return wp.coordinate
      case .terminalWaypoint(let wp): return wp.coordinate
    }
  }

  /// The ICAO region code of the fix.
  public var icaoRegion: String {
    switch self {
      case .vhfNavaid(let nav): return nav.icaoRegion
      case .ndbNavaid(let nav): return nav.icaoRegion
      case .enrouteWaypoint(let wp): return wp.icaoRegion
      case .terminalWaypoint(let wp): return wp.icaoRegion
    }
  }

  /// The name of the fix, if available.
  public var name: String? {
    switch self {
      case .vhfNavaid(let nav): return nav.name
      case .ndbNavaid(let nav): return nav.name
      case .enrouteWaypoint(let wp): return wp.name
      case .terminalWaypoint(let wp): return wp.name
    }
  }
}

// MARK: - CustomStringConvertible

extension Fix: CustomStringConvertible {
  public var description: String {
    switch self {
      case .vhfNavaid: "\(identifier) (VOR)"
      case .ndbNavaid: "\(identifier) (NDB)"
      case .enrouteWaypoint: "\(identifier) (WPT)"
      case .terminalWaypoint: "\(identifier) (WPT)"
    }
  }
}

/// A resolved navaid (VHF or NDB).
///
/// Use this type when resolving navaid references, such as recommended navaids
/// in procedure legs.
public enum Navaid: Sendable {
  /// A VHF navaid (VOR, VORTAC, DME).
  case vhf(VHFNavaid)

  /// An NDB (Non-Directional Beacon).
  case ndb(NDBNavaid)

  /// The identifier of the navaid.
  public var identifier: String {
    switch self {
      case .vhf(let nav): return nav.identifier
      case .ndb(let nav): return nav.identifier
    }
  }

  /// The coordinate of the navaid.
  public var coordinate: Coordinate? {
    switch self {
      case .vhf(let nav): return nav.coordinate
      case .ndb(let nav): return nav.coordinate
    }
  }

  /// The ICAO region code of the navaid.
  public var icaoRegion: String {
    switch self {
      case .vhf(let nav): return nav.icaoRegion
      case .ndb(let nav): return nav.icaoRegion
    }
  }

  /// The name of the navaid.
  public var name: String {
    switch self {
      case .vhf(let nav): return nav.name
      case .ndb(let nav): return nav.name
    }
  }
}

// MARK: - CustomStringConvertible

extension Navaid: CustomStringConvertible {
  public var description: String {
    switch self {
      case .vhf: "\(identifier) (VOR)"
      case .ndb: "\(identifier) (NDB)"
    }
  }
}
