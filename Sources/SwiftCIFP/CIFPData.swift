import CoreLocation
import Foundation

/// Central data container actor that enables model linking.
///
/// `CIFPData` holds all CIFP collections and establishes weak references
/// back to itself in each model, enabling async computed properties that
/// resolve relationships between models.
///
/// ## Creating CIFPData
///
/// Create a `CIFPData` instance from a parsed `CIFP`:
///
/// ```swift
/// let cifp = try await CIFP(url: fileURL)
/// let data = await cifp.linked()
/// ```
///
/// ## Accessing Related Models
///
/// With linked data, models can resolve their relationships:
///
/// ```swift
/// // Runway can now resolve its localizer
/// if let localizer = await runway.localizer {
///     print("Localizer frequency: \(localizer.frequency)")
/// }
///
/// // Procedure legs can resolve their fixes
/// for leg in approach.legs {
///     if let fix = await leg.fix {
///         print("Fix: \(fix.identifier)")
///     }
/// }
/// ```
public actor CIFPData {

  // MARK: - Metadata

  /// The file header information.
  public let header: Header

  /// The AIRAC cycle of this data.
  public let cycle: Cycle

  // MARK: - Standalone Records

  /// Grid MORA records.
  public private(set) var gridMORAs: [GridMORA]

  /// VHF Navaids keyed by identifier.
  public private(set) var vhfNavaids: [String: VHFNavaid]

  /// NDB Navaids keyed by identifier.
  public private(set) var ndbNavaids: [String: NDBNavaid]

  /// Enroute waypoints keyed by identifier.
  public private(set) var enrouteWaypoints: [String: EnrouteWaypoint]

  /// Airways keyed by identifier.
  public private(set) var airways: [String: Airway]

  // MARK: - Airport-Associated Records

  /// Airports keyed by identifier (ICAO code or FAA LID).
  /// Access child records (runways, procedures, etc.) through each Airport's properties.
  /// See ``Airport`` for details on identifier types.
  public private(set) var airports: [String: Airport]

  // MARK: - Airspace

  /// Controlled airspace records.
  public private(set) var controlledAirspaces: [ControlledAirspace]

  /// Special use airspace records.
  public private(set) var specialUseAirspaces: [SpecialUseAirspace]

  // MARK: - Heliport

  /// Heliports keyed by identifier.
  /// Access child records (waypoints, approaches, etc.) through each Heliport's properties.
  public private(set) var heliports: [String: Heliport]

  // MARK: - Internal Storage (for fix resolution)

  /// Terminal waypoints for cross-airport fix resolution.
  private var _terminalWaypoints: [TerminalWaypoint] = []

  /// Total number of all records.
  public var totalRecordCount: Int {
    gridMORAs.count + vhfNavaids.count + ndbNavaids.count + enrouteWaypoints.count + airways.count
      + airports.values.reduce(airports.count) { (count: Int, airport) in
        count + airport.runways.count + airport.terminalWaypoints.count
          + airport.terminalNavaids.count + airport.localizers.count
          + airport.pathPoints.count + airport.msaRecords.count
          + airport.sids.count + airport.stars.count + airport.approaches.count
      }
      + controlledAirspaces.count + specialUseAirspaces.count
      + heliports.values.reduce(heliports.count) { (count: Int, heliport) in
        count + heliport.waypoints.count + heliport.approaches.count + heliport.msaRecords.count
      }
  }

  // MARK: - Initialization

  /// Creates a CIFPData actor from a parsed CIFP, establishing all model links.
  ///
  /// - Parameter cifp: The parsed CIFP data to link.
  public init(from cifp: CIFP) async {
    // Copy metadata
    self.header = cifp.header
    self.cycle = cifp.cycle

    // Copy standalone records
    self.gridMORAs = cifp.gridMORAs
    self.vhfNavaids = cifp.vhfNavaids
    self.ndbNavaids = cifp.ndbNavaids
    self.enrouteWaypoints = cifp.enrouteWaypoints
    self.airways = cifp.airways

    // Copy parent models (children already folded in during build)
    self.airports = cifp.airports
    self.heliports = cifp.heliports

    // Copy airspace records
    self.controlledAirspaces = cifp.controlledAirspaces
    self.specialUseAirspaces = cifp.specialUseAirspaces

    // Keep internal terminal waypoints for fix resolution
    self._terminalWaypoints = cifp.terminalWaypoints

    // Establish all model links for fix resolution
    establishAllLinks()
  }

  /// Creates a CIFPData actor with minimal data for testing fix resolution.
  ///
  /// This initializer is primarily intended for unit testing the fix resolution logic
  /// without needing to parse a full CIFP file.
  ///
  /// - Parameters:
  ///   - vhfNavaids: VHF navaids to include.
  ///   - ndbNavaids: NDB navaids to include.
  ///   - enrouteWaypoints: Enroute waypoints to include.
  ///   - terminalWaypoints: Terminal waypoints to include.
  public init(
    vhfNavaids: [String: VHFNavaid] = [:],
    ndbNavaids: [String: NDBNavaid] = [:],
    enrouteWaypoints: [String: EnrouteWaypoint] = [:],
    terminalWaypoints: [TerminalWaypoint] = []
  ) {
    self.header = Header(
      fileName: "TEST",
      volumeSet: "",
      versionNumber: "001",
      fileType: .production,
      recordCount: 0,
      cycleId: "",
      creationDateComponents: nil,
      dataSupplier: "TEST",
      descriptiveText: []
    )
    self.cycle = .current
    self.gridMORAs = []
    self.vhfNavaids = vhfNavaids
    self.ndbNavaids = ndbNavaids
    self.enrouteWaypoints = enrouteWaypoints
    self.airways = [:]
    self.airports = [:]
    self.controlledAirspaces = []
    self.specialUseAirspaces = []
    self.heliports = [:]
    self._terminalWaypoints = terminalWaypoints
  }

  // MARK: - Link Establishment

  private func establishAllLinks() {
    let findFix = makeFindFix()
    let findNavaid = makeFindNavaid()

    // Link airports and their children
    linkAirportsWithChildren(findFix: findFix, findNavaid: findNavaid)

    // Link airspace records
    linkControlledAirspaces()
    linkSpecialUseAirspaces()

    // Link airway models with closure injection
    linkAirways(findFix: findFix)

    // Link heliports and their children
    linkHeliportsWithChildren(findFix: findFix, findNavaid: findNavaid)

    // Link internal terminal waypoints for fix resolution
    for i in _terminalWaypoints.indices {
      _terminalWaypoints[i].data = self
    }
  }

  private func linkAirportsWithChildren(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  ) {
    for key in airports.keys {
      // Link the airport itself
      airports[key]?.data = self

      // Link runways
      for i in airports[key]?.runways.indices ?? (0..<0) {
        airports[key]?.runways[i].data = self
      }

      // Link terminal waypoints
      for i in airports[key]?.terminalWaypoints.indices ?? (0..<0) {
        airports[key]?.terminalWaypoints[i].data = self
      }

      // Link localizers
      for i in airports[key]?.localizers.indices ?? (0..<0) {
        airports[key]?.localizers[i].data = self
      }

      // Link MSA records
      for i in airports[key]?.msaRecords.indices ?? (0..<0) {
        airports[key]?.msaRecords[i].data = self
      }

      // Link terminal navaids
      for i in airports[key]?.terminalNavaids.indices ?? (0..<0) {
        airports[key]?.terminalNavaids[i].data = self
      }

      // Link path points
      for i in airports[key]?.pathPoints.indices ?? (0..<0) {
        airports[key]?.pathPoints[i].data = self
      }

      // Link SIDs with closure injection
      for i in airports[key]?.sids.indices ?? (0..<0) {
        airports[key]?.sids[i].data = self
        airports[key]?.sids[i].injectLegResolvers(findFix: findFix, findNavaid: findNavaid)
      }

      // Link STARs with closure injection
      for i in airports[key]?.stars.indices ?? (0..<0) {
        airports[key]?.stars[i].data = self
        airports[key]?.stars[i].injectLegResolvers(findFix: findFix, findNavaid: findNavaid)
      }

      // Link approaches with closure injection
      for i in airports[key]?.approaches.indices ?? (0..<0) {
        airports[key]?.approaches[i].data = self
        airports[key]?.approaches[i].injectLegResolvers(findFix: findFix, findNavaid: findNavaid)
      }
    }
  }

  private func linkControlledAirspaces() {
    for i in controlledAirspaces.indices {
      controlledAirspaces[i].data = self
    }
  }

  private func linkSpecialUseAirspaces() {
    for i in specialUseAirspaces.indices {
      specialUseAirspaces[i].data = self
    }
  }

  private func linkAirways(findFix: @escaping FixResolver) {
    for key in airways.keys {
      airways[key]?.data = self
      airways[key]?.injectFixResolvers(findFix: findFix)
    }
  }

  private func linkHeliportsWithChildren(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  ) {
    for key in heliports.keys {
      // Link the heliport itself
      heliports[key]?.data = self

      // Link heliport waypoints
      for i in heliports[key]?.waypoints.indices ?? (0..<0) {
        heliports[key]?.waypoints[i].data = self
      }

      // Link heliport approaches with closure injection
      for i in heliports[key]?.approaches.indices ?? (0..<0) {
        heliports[key]?.approaches[i].data = self
        heliports[key]?.approaches[i].injectLegResolvers(findFix: findFix, findNavaid: findNavaid)
      }

      // Link heliport MSA records
      for i in heliports[key]?.msaRecords.indices ?? (0..<0) {
        heliports[key]?.msaRecords[i].data = self
      }
    }
  }

  // MARK: - Closure Factories

  private func makeFindFix() -> FixResolver {
    return { [weak self] identifier, sectionCode, airportId in
      await self?.resolveFix(identifier, sectionCode: sectionCode, airportId: airportId)
    }
  }

  private func makeFindNavaid() -> NavaidResolver {
    return { [weak self] identifier, sectionCode in
      await self?.resolveNavaid(identifier, sectionCode: sectionCode)
    }
  }

  // MARK: - Public Lookup Methods

  /// Get an airport by identifier (ICAO code or FAA LID).
  public func airport(_ id: String) -> Airport? {
    airports[id]
  }

  /// Get a VHF navaid by identifier.
  public func vhfNavaid(_ identifier: String) -> VHFNavaid? {
    vhfNavaids[identifier]
  }

  /// Get an NDB navaid by identifier.
  public func ndbNavaid(_ identifier: String) -> NDBNavaid? {
    ndbNavaids[identifier]
  }

  /// Get an enroute waypoint by identifier.
  public func enrouteWaypoint(_ identifier: String) -> EnrouteWaypoint? {
    enrouteWaypoints[identifier]
  }

  /// Get a terminal waypoint by identifier and airport.
  public func terminalWaypoint(_ identifier: String, airportId: String) -> TerminalWaypoint? {
    _terminalWaypoints.first { $0.identifier == identifier && $0.airportId == airportId }
  }

  /// Get an airway by identifier.
  public func airway(_ identifier: String) -> Airway? {
    airways[identifier]
  }

  /// Get a runway by identifier and airport.
  public func runway(_ identifier: String, airportId: String) -> Runway? {
    airports[airportId]?.runways.first { $0.name == identifier }
  }

  /// Get a localizer by identifier and airport.
  public func localizer(_ identifier: String, airportId: String) -> LocalizerGlideSlope? {
    airports[airportId]?.localizers.first { $0.localizerId == identifier }
  }

  /// Get an approach by identifier and airport.
  public func approach(_ identifier: String, airportId: String) -> Approach? {
    airports[airportId]?.approaches.first { $0.identifier == identifier }
  }

  /// Get a heliport by identifier.
  public func heliport(_ id: String) -> Heliport? {
    heliports[id]
  }

  /// Returns the GridMORA containing the given coordinate, if available.
  ///
  /// - Parameter coordinate: The coordinate to look up.
  /// - Returns: The GridMORA for the grid square containing the coordinate, or `nil` if not available.
  public func gridMORA(at coordinate: CLLocationCoordinate2D) -> GridMORA? {
    let latDeg = Int(floor(coordinate.latitude))
    let lonDeg = Int(floor(coordinate.longitude))
    return gridMORA(latitudeDeg: latDeg, longitudeDeg: lonDeg)
  }

  /// Returns the GridMORA for the given grid square, if available.
  ///
  /// - Parameters:
  ///   - latitudeDeg: Latitude of the grid square's south edge in degrees.
  ///   - longitudeDeg: Longitude of the grid square's west edge in degrees.
  /// - Returns: The GridMORA for the specified grid square, or `nil` if not available.
  public func gridMORA(latitudeDeg: Int, longitudeDeg: Int) -> GridMORA? {
    gridMORAs.first { $0.latitudeDeg == latitudeDeg && $0.longitudeDeg == longitudeDeg }
  }

  // MARK: - Fix Resolution

  /// Resolves a fix based on identifier and optional section code.
  ///
  /// Section codes indicate fix type:
  /// - `"D "` or `"D"`: VHF Navaid
  /// - `"DB"`: NDB Navaid
  /// - `"EA"`: Enroute Waypoint
  /// - `"PC"`: Terminal Waypoint (requires airportId)
  ///
  /// - Parameters:
  ///   - identifier: The fix identifier.
  ///   - sectionCode: Optional section code indicating fix type.
  ///   - airportId: Optional airport identifier for terminal waypoint resolution.
  /// - Returns: The resolved Fix, or nil if not found.
  public func resolveFix(
    _ identifier: String,
    sectionCode: SectionCode?,
    airportId: String?
  ) -> Fix? {
    guard let sectionCode else {
      // No section code - try each type in order of likelihood
      if let wp = enrouteWaypoints[identifier] {
        return .enrouteWaypoint(wp)
      }
      if let vhf = vhfNavaids[identifier] {
        return .vhfNavaid(vhf)
      }
      if let ndb = ndbNavaids[identifier] {
        return .ndbNavaid(ndb)
      }
      if let airportId,
        let tw = terminalWaypoint(identifier, airportId: airportId)
      {
        return .terminalWaypoint(tw)
      }
      return nil
    }

    switch sectionCode {
      case .vhfNavaid:
        return vhfNavaids[identifier].map { .vhfNavaid($0) }
      case .ndbNavaid:
        return ndbNavaids[identifier].map { .ndbNavaid($0) }
      case .enrouteWaypoint:
        return enrouteWaypoints[identifier].map { .enrouteWaypoint($0) }
      case .terminalWaypoint:
        if let airportId,
          let tw = terminalWaypoint(identifier, airportId: airportId)
        {
          return .terminalWaypoint(tw)
        }
        return nil
      default:
        // Other section codes - try all types
        if let wp = enrouteWaypoints[identifier] {
          return .enrouteWaypoint(wp)
        }
        if let vhf = vhfNavaids[identifier] {
          return .vhfNavaid(vhf)
        }
        if let ndb = ndbNavaids[identifier] {
          return .ndbNavaid(ndb)
        }
        return nil
    }
  }

  /// Resolves a navaid (VHF or NDB) based on identifier and optional section code.
  ///
  /// - Parameters:
  ///   - identifier: The navaid identifier.
  ///   - sectionCode: Optional section code indicating navaid type.
  /// - Returns: The resolved Navaid, or nil if not found.
  public func resolveNavaid(
    _ identifier: String,
    sectionCode: String?
  ) -> Navaid? {
    guard let section = sectionCode?.trimmingCharacters(in: .whitespaces), !section.isEmpty else {
      // No section code - try VHF first, then NDB
      if let vhf = vhfNavaids[identifier] {
        return .vhf(vhf)
      }
      if let ndb = ndbNavaids[identifier] {
        return .ndb(ndb)
      }
      return nil
    }

    switch section {
      case "D":
        return vhfNavaids[identifier].map { .vhf($0) }
      case "DB":
        return ndbNavaids[identifier].map { .ndb($0) }
      default:
        // Unknown section code - try both
        if let vhf = vhfNavaids[identifier] {
          return .vhf(vhf)
        }
        if let ndb = ndbNavaids[identifier] {
          return .ndb(ndb)
        }
        return nil
    }
  }

  // MARK: - Codable Snapshot

  /// Returns a Codable snapshot of the linked data.
  ///
  /// Since `CIFPData` is an actor, it cannot directly conform to `Codable`.
  /// Use this method to get a snapshot that can be encoded to JSON.
  public func snapshot() -> CIFPDataSnapshot {
    CIFPDataSnapshot(
      header: header,
      cycle: cycle,
      gridMORAs: gridMORAs,
      vhfNavaids: vhfNavaids,
      ndbNavaids: ndbNavaids,
      enrouteWaypoints: enrouteWaypoints,
      airways: airways,
      airports: airports,
      controlledAirspaces: controlledAirspaces,
      specialUseAirspaces: specialUseAirspaces,
      heliports: heliports
    )
  }
}

// MARK: - CIFPDataSnapshot

/// A Codable snapshot of linked CIFP data.
///
/// This struct captures the hierarchical structure where child records
/// (runways, procedures, etc.) are nested within their parent airports/heliports.
public struct CIFPDataSnapshot: Sendable, Codable {
  /// The file header information.
  public let header: Header

  /// The AIRAC cycle of this data.
  public let cycle: Cycle

  /// Grid MORA records.
  public let gridMORAs: [GridMORA]

  /// VHF Navaids keyed by identifier.
  public let vhfNavaids: [String: VHFNavaid]

  /// NDB Navaids keyed by identifier.
  public let ndbNavaids: [String: NDBNavaid]

  /// Enroute waypoints keyed by identifier.
  public let enrouteWaypoints: [String: EnrouteWaypoint]

  /// Airways keyed by identifier.
  public let airways: [String: Airway]

  /// Airports keyed by identifier (ICAO code or FAA LID).
  /// Each airport contains its runways, procedures, and other child records.
  public let airports: [String: Airport]

  /// Controlled airspace records.
  public let controlledAirspaces: [ControlledAirspace]

  /// Special use airspace records.
  public let specialUseAirspaces: [SpecialUseAirspace]

  /// Heliports keyed by identifier.
  /// Each heliport contains its waypoints, approaches, and MSA records.
  public let heliports: [String: Heliport]
}
