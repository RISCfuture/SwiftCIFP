import CoreLocation
import Foundation
@preconcurrency import RegexBuilder

/// Container for CIFP (Coded Instrument Flight Procedures) data.
///
/// The CIFP struct parses and stores instrument flight procedure data
/// from FAA CIFP files. Child records (runways, procedures, waypoints, etc.)
/// are accessible immediately through their parent airport or heliport objects.
///
/// ## Basic Access
///
/// After parsing, you can access airport data and their children directly:
///
/// ```swift
/// let cifp = try await CIFP(url: fileURL)
/// if let klax = cifp.airports["KLAX"] {
///     print(klax.runways)      // Works immediately
///     print(klax.sids)         // Works immediately
///     print(klax.approaches)   // Works immediately
/// }
/// ```
///
/// ## Fix Resolution
///
/// To resolve procedure leg fixes to their actual waypoint/navaid objects,
/// use ``linked()`` to create a ``CIFPData`` actor.
public struct CIFP: Sendable, Codable {

  /// Estimated number of records for pre-allocation.
  private static let estimatedRecordCount = 400_000

  /// The file header information.
  public let header: Header

  /// The AIRAC cycle of this data.
  public let cycle: Cycle

  // MARK: - Standalone Records

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

  // MARK: - Airport-Associated Records

  /// Airports keyed by identifier (ICAO code or FAA LID).
  /// Access child records (runways, procedures, etc.) through each Airport's properties.
  /// See ``Airport`` for details on identifier types.
  public let airports: [String: Airport]

  /// Terminal waypoints (internal - kept for fix resolution in CIFPData).
  let terminalWaypoints: [TerminalWaypoint]

  // MARK: - Airspace

  /// Controlled airspace records.
  public let controlledAirspaces: [ControlledAirspace]

  /// Special use airspace records.
  public let specialUseAirspaces: [SpecialUseAirspace]

  // MARK: - Heliport

  /// Heliports keyed by identifier.
  /// Access child records (waypoints, approaches, etc.) through each Heliport's properties.
  public let heliports: [String: Heliport]

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

  /// Creates a CIFP container by parsing the given data.
  ///
  /// Uses streaming byte-based parsing for optimal performance.
  ///
  /// - Parameters:
  ///   - data: The CIFP file content as raw bytes.
  ///   - progressHandler: Optional callback called before processing begins with a Progress
  ///     object that you can use to track parsing progress.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber). Line number is nil for aggregation errors.
  /// - Throws: CIFPError if the file format is invalid.
  public init(
    data: Data,
    progressHandler: @Sendable (Progress) -> Void = { _ in },
    errorCallback: ((Error, Int?) -> Void)? = nil
  ) throws {
    var builder = CIFPBuilder()

    var lineNumber = 0

    // Setup progress tracking based on data size
    let progress = Progress(totalUnitCount: Int64(data.count))
    progressHandler(progress)

    var reader = CIFPLineReader(data: data)
    while let line = reader.next() {
      lineNumber += 1
      do {
        let record = try CIFPByteParser.parseRecord(line, lineNumber: lineNumber)
        builder.add(record)
      } catch {
        errorCallback?(error, lineNumber)
      }
      progress.completedUnitCount = Int64(reader.bytesRead)
    }
    progress.completedUnitCount = progress.totalUnitCount

    let result = builder.build(errorCallback: errorCallback)
    self.header = result.header
    self.cycle = result.cycle
    self.gridMORAs = result.gridMORAs
    self.vhfNavaids = result.vhfNavaids
    self.ndbNavaids = result.ndbNavaids
    self.enrouteWaypoints = result.enrouteWaypoints
    self.airways = result.airways
    self.airports = result.airports
    self.terminalWaypoints = result.terminalWaypoints
    self.controlledAirspaces = result.controlledAirspaces
    self.specialUseAirspaces = result.specialUseAirspaces
    self.heliports = result.heliports
  }

  /// Creates a CIFP container by streaming from a generic async byte sequence.
  ///
  /// This allows parsing from any async byte source, such as `URLSession.AsyncBytes`.
  ///
  /// - Parameters:
  ///   - bytes: An async sequence of bytes to parse.
  ///   - totalBytes: Optional total byte count for progress tracking. If not provided,
  ///     progress will be indeterminate.
  ///   - progressHandler: Optional callback called before processing begins with a Progress
  ///     object that you can use to track parsing progress.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber). Line number is nil for aggregation errors.
  /// - Throws: CIFPError if the file format is invalid.
  public init<S: AsyncSequence>(
    bytes: S,
    totalBytes: Int64? = nil,
    progressHandler: @Sendable (Progress) -> Void = { _ in },
    errorCallback: ((Error, Int?) -> Void)? = nil
  ) async throws where S.Element == UInt8, S: Sendable {
    var builder = CIFPBuilder()

    var lineNumber = 0
    var bytesRead: Int64 = 0

    // Setup progress tracking
    let progress = Progress(totalUnitCount: totalBytes ?? -1)
    progressHandler(progress)

    for try await line in AsyncBytesLineReader(source: bytes) {
      lineNumber += 1
      bytesRead += Int64(line.count + 1)  // +1 for newline
      do {
        let record = try CIFPByteParser.parseRecord(line[...], lineNumber: lineNumber)
        builder.add(record)
      } catch {
        errorCallback?(error, lineNumber)
      }
      progress.completedUnitCount = bytesRead
    }
    if progress.totalUnitCount > 0 {
      progress.completedUnitCount = progress.totalUnitCount
    }

    let result = builder.build(errorCallback: errorCallback)
    self.header = result.header
    self.cycle = result.cycle
    self.gridMORAs = result.gridMORAs
    self.vhfNavaids = result.vhfNavaids
    self.ndbNavaids = result.ndbNavaids
    self.enrouteWaypoints = result.enrouteWaypoints
    self.airways = result.airways
    self.airports = result.airports
    self.terminalWaypoints = result.terminalWaypoints
    self.controlledAirspaces = result.controlledAirspaces
    self.specialUseAirspaces = result.specialUseAirspaces
    self.heliports = result.heliports
  }

  /// Creates a CIFP container by streaming from a file URL.
  ///
  /// Uses async streaming for efficient memory usage with large files.
  ///
  /// - Parameters:
  ///   - url: The URL of the CIFP file to parse.
  ///   - progressHandler: Optional callback called before processing begins with a Progress
  ///     object that you can use to track parsing progress.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber). Line number is nil for aggregation errors.
  /// - Throws: CIFPError if the file format is invalid.
  public init(
    url: URL,
    progressHandler: @Sendable (Progress) -> Void = { _ in },
    errorCallback: ((Error, Int?) -> Void)? = nil
  ) async throws {
    var builder = CIFPBuilder()

    var lineNumber = 0
    var bytesRead: Int64 = 0

    let reader = AsyncCIFPLineReader(url: url)

    // Setup progress tracking based on file size
    let progress: Progress
    if let fileSize = reader.fileSize {
      progress = Progress(totalUnitCount: fileSize)
    } else {
      progress = Progress(totalUnitCount: -1)  // Indeterminate
    }
    progressHandler(progress)

    for try await line in reader {
      lineNumber += 1
      bytesRead += Int64(line.count + 1)  // +1 for newline
      do {
        let record = try CIFPByteParser.parseRecord(line[...], lineNumber: lineNumber)
        builder.add(record)
      } catch {
        errorCallback?(error, lineNumber)
      }
      progress.completedUnitCount = bytesRead
    }
    if progress.totalUnitCount > 0 {
      progress.completedUnitCount = progress.totalUnitCount
    }

    let result = builder.build(errorCallback: errorCallback)
    self.header = result.header
    self.cycle = result.cycle
    self.gridMORAs = result.gridMORAs
    self.vhfNavaids = result.vhfNavaids
    self.ndbNavaids = result.ndbNavaids
    self.enrouteWaypoints = result.enrouteWaypoints
    self.airways = result.airways
    self.airports = result.airports
    self.terminalWaypoints = result.terminalWaypoints
    self.controlledAirspaces = result.controlledAirspaces
    self.specialUseAirspaces = result.specialUseAirspaces
    self.heliports = result.heliports
  }

  // MARK: - Convenience Methods

  /// Get an airway by identifier.
  public func airway(_ identifier: String) -> Airway? {
    airways[identifier]
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

  /// Get an airport by identifier (ICAO code or FAA LID).
  public func airport(_ id: String) -> Airport? {
    airports[id]
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
}

// MARK: - Linked Data

extension CIFP {
  /// Creates a CIFPData actor for fix resolution.
  ///
  /// Most use cases don't need linking - you can access runways, procedures, and
  /// other child records directly through `airports["KLAX"]?.runways` etc.
  ///
  /// Only call this method when you need to resolve procedure leg fixes to their
  /// actual waypoint/navaid objects, or follow relationships like `runway.localizer`.
  ///
  /// - Returns: A `CIFPData` actor with established model links for fix resolution.
  ///
  /// ## Example
  /// ```swift
  /// let cifp = try await CIFP(url: fileURL)
  /// let data = await cifp.linked()
  ///
  /// // Resolve procedure leg fixes
  /// for leg in approach.legs {
  ///     if let fix = await leg.fix {
  ///         print(fix.identifier)
  ///     }
  /// }
  /// ```
  public func linked() async -> CIFPData {
    await CIFPData(from: self)
  }
}

// MARK: - CIFPBuilder

/// Builder for aggregating parsed records into CIFP.
private struct CIFPBuilder {
  // MARK: - Static Regex Patterns

  /// Matches "VOLUME" followed by whitespace and a 4-digit cycle number.
  nonisolated(unsafe) private static let volumeCycleRegex = Regex {
    "VOLUME"
    OneOrMore(.whitespace)
    Capture { Repeat(.digit, count: 4) }
  }

  /// Matches a date in DD-MMM-YYYY format (e.g., "15-JAN-2024").
  nonisolated(unsafe) private static let creationDateRegex = Regex {
    Repeat(.digit, count: 2)
    "-"
    Repeat("A"..."Z", count: 3)
    "-"
    Repeat(.digit, count: 4)
  }

  /// Parses the creation date from HDR01.
  private static let creationDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  var headerRecords: [HeaderRecord] = []
  var gridMORAs: [GridMORA] = []
  var vhfNavaids: [String: VHFNavaid] = [:]
  var ndbNavaids: [String: NDBNavaid] = [:]
  var enrouteWaypoints: [String: EnrouteWaypoint] = [:]
  var airwayFixes: [String: [AirwayFix]] = [:]
  var airwayMeta: [String: (routeType: AirwayRouteType?, level: AirwayLevel?)] = [:]
  var airports: [String: Airport] = [:]
  var runways: [Runway] = []
  var terminalWaypoints: [TerminalWaypoint] = []
  var terminalNavaids: [TerminalNavaid] = []
  var localizers: [LocalizerGlideSlope] = []
  var pathPointRecords:
    [String: (primary: PathPoint?, continuation: PathPointContinuationRecord?)] =
      [:]
  var msaRecords: [String: (base: MSARecord, sectors: [MSASector])] = [:]
  var sidLegs: [String: [ProcedureLegRecord]] = [:]
  var starLegs: [String: [ProcedureLegRecord]] = [:]
  var approachLegs: [String: [ProcedureLegRecord]] = [:]
  var controlledAirspaceRecords: [String: [AirspaceBoundaryRecord]] = [:]
  var specialUseAirspaceRecords: [String: [AirspaceBoundaryRecord]] = [:]
  var heliports: [String: Heliport] = [:]
  var heliportWaypoints: [HeliportWaypoint] = []
  var heliportSIDLegs: [String: [ProcedureLegRecord]] = [:]
  var heliportSTARLegs: [String: [ProcedureLegRecord]] = [:]
  var heliportApproachLegs: [String: [ProcedureLegRecord]] = [:]
  var heliportMSARecords: [String: (base: HeliportMSARecord, sectors: [MSASector])] = [:]
  var approachContinuations: [String: ApproachContinuationRecord] = [:]

  mutating func add(_ record: ParsedRecord) {
    switch record {
      case .header(let r):
        headerRecords.append(r)
      case .gridMORAs(let records):
        gridMORAs.append(contentsOf: records)
      case .vhfNavaid(let r):
        vhfNavaids[r.identifier] = r
      case .ndbNavaid(let r):
        ndbNavaids[r.identifier] = r
      case .enrouteWaypoint(let r):
        enrouteWaypoints[r.identifier] = r
      case .airwayFix(let r):
        airwayFixes[r.airwayId, default: []].append(r.fix)
        if airwayMeta[r.airwayId] == nil {
          airwayMeta[r.airwayId] = (r.routeType, r.level)
        }
      case .airport(let r):
        airports[r.id] = r
      case .terminalWaypoint(let r):
        terminalWaypoints.append(r)
      case .terminalNavaid(let r):
        terminalNavaids.append(r)
      case .runway(let r):
        runways.append(r)
      case .localizer(let r):
        localizers.append(r)
      case .pathPoint(let r):
        let key = "\(r.airportId)-\(r.approachId)-\(r.runwayId)"
        if var existing = pathPointRecords[key] {
          existing.primary = r
          pathPointRecords[key] = existing
        } else {
          pathPointRecords[key] = (primary: r, continuation: nil)
        }
      case .pathPointContinuation(let r):
        let key = "\(r.airportId)-\(r.approachId)-\(r.runwayId)"
        if var existing = pathPointRecords[key] {
          existing.continuation = r
          pathPointRecords[key] = existing
        } else {
          pathPointRecords[key] = (primary: nil, continuation: r)
        }
      case .msa(let r):
        let key = "\(r.airportId)-\(r.center)"
        if var existing = msaRecords[key] {
          existing.sectors.append(r.sector)
          msaRecords[key] = existing
        } else {
          msaRecords[key] = (r, [r.sector])
        }
      case .sidLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        sidLegs[key, default: []].append(r)
      case .starLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        starLegs[key, default: []].append(r)
      case .approachLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        approachLegs[key, default: []].append(r)
      case .controlledAirspace(let r):
        let key = r.centerOrDesignation
        controlledAirspaceRecords[key, default: []].append(r)
      case .specialUseAirspace(let r):
        let key = r.centerOrDesignation
        specialUseAirspaceRecords[key, default: []].append(r)
      case .heliport(let r):
        heliports[r.id] = r
      case .heliportWaypoint(let r):
        heliportWaypoints.append(r)
      case .heliportSIDLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        heliportSIDLegs[key, default: []].append(r)
      case .heliportSTARLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        heliportSTARLegs[key, default: []].append(r)
      case .heliportApproachLeg(let r):
        let key = "\(r.airportId)-\(r.procedureId)"
        heliportApproachLegs[key, default: []].append(r)
      case .heliportMSA(let r):
        let key = "\(r.parentId)-\(r.center)"
        if var existing = heliportMSARecords[key] {
          existing.sectors.append(r.sector)
          heliportMSARecords[key] = existing
        } else {
          heliportMSARecords[key] = (r, [r.sector])
        }
      case .approachContinuation(let r):
        let key = "\(r.airportId)-\(r.procedureId)-\(r.transitionId ?? "")"
        approachContinuations[key] = r
    }
  }

  func build(errorCallback: ((Error, Int?) -> Void)?) -> CIFPBuildResult {
    let headerText = headerRecords.sorted(by: { $0.lineNumber < $1.lineNumber }).map(\.text),
      header = parseHeader(from: headerText),
      cycle = buildCycle(from: headerText, header: header)

    let airways = buildAirways(errorCallback: errorCallback),
      msas = buildMSAs(errorCallback: errorCallback),
      sids = buildSIDs(errorCallback: errorCallback),
      stars = buildSTARs(errorCallback: errorCallback),
      approaches = buildApproaches(errorCallback: errorCallback),
      controlledAirspaces = buildControlledAirspaces(errorCallback: errorCallback),
      specialUseAirspaces = buildSpecialUseAirspaces(errorCallback: errorCallback),
      heliportApproaches = buildHeliportApproaches(errorCallback: errorCallback),
      heliportMSAs = buildHeliportMSAs(),
      pathPoints = buildPathPoints()

    let foldedAirports = foldChildrenIntoAirports(
      airports,
      runways: runways,
      waypoints: terminalWaypoints,
      navaids: terminalNavaids,
      localizers: localizers,
      pathPoints: pathPoints,
      msas: msas,
      sids: sids,
      stars: stars,
      approaches: approaches
    )

    let foldedHeliports = foldChildrenIntoHeliports(
      heliports,
      waypoints: heliportWaypoints,
      approaches: heliportApproaches,
      msas: heliportMSAs
    )

    return CIFPBuildResult(
      header: header,
      cycle: cycle,
      gridMORAs: gridMORAs,
      vhfNavaids: vhfNavaids,
      ndbNavaids: ndbNavaids,
      enrouteWaypoints: enrouteWaypoints,
      airways: airways,
      airports: foldedAirports,
      terminalWaypoints: terminalWaypoints,
      controlledAirspaces: controlledAirspaces,
      specialUseAirspaces: specialUseAirspaces,
      heliports: foldedHeliports
    )
  }

  // MARK: - Build Helpers

  private func buildCycle(from headerText: [String], header: Header) -> Cycle {
    if let c = Cycle(yymm: header.cycleId) {
      return c
    }
    // Fall back to looking for "VOLUME XXXX" pattern
    for text in headerText {
      guard let match = text.firstMatch(of: Self.volumeCycleRegex) else { continue }
      let cycleStr = String(match.1)
      guard let c = Cycle(yymm: cycleStr) else { continue }
      return c
    }
    return Cycle.effective
  }

  private func buildAirways(errorCallback: ((Error, Int?) -> Void)?) -> [String: Airway] {
    var airways: [String: Airway] = [:]
    for (ident, fixes) in airwayFixes {
      guard let meta = airwayMeta[ident],
        let routeType = meta.routeType,
        let level = meta.level
      else {
        errorCallback?(
          CIFPError.aggregationError(
            recordType: "Airway",
            identifier: ident,
            reason: .missingAirwayMetadata
          ),
          nil
        )
        continue
      }
      airways[ident] = Airway(
        identifier: ident,
        routeType: routeType,
        level: level,
        fixes: fixes.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
      )
    }
    return airways
  }

  private func buildMSAs(errorCallback: ((Error, Int?) -> Void)?) -> [MSA] {
    var msas: [MSA] = []
    for (key, value) in msaRecords {
      guard let radiusNM = value.base.radius else {
        errorCallback?(
          CIFPError.aggregationError(recordType: "MSA", identifier: key, reason: .missingMSARadius),
          nil
        )
        continue
      }
      // Per ARINC 424, default to magnetic when Magnetic/True Indicator is blank
      let bearingReference = value.base.bearingReference ?? .magnetic
      msas.append(
        MSA(
          airportId: value.base.airportId,
          icaoRegion: value.base.icaoRegion,
          center: value.base.center,
          centerICAO: value.base.centerICAO,
          multipleCode: value.base.multipleCode,
          radiusNM: radiusNM,
          sectors: Set(value.sectors),
          bearingReference: bearingReference
        )
      )
    }
    return msas
  }

  private func buildSIDs(errorCallback: ((Error, Int?) -> Void)?) -> [SID] {
    var sids: [SID] = []
    for (key, legs) in sidLegs {
      guard let first = legs.first,
        let routeTypeChar = first.routeType,
        let routeType = SIDRouteType(rawValue: routeTypeChar)
      else {
        let reason: AggregationErrorReason =
          if let first = legs.first, let char = first.routeType {
            .invalidRouteType(char)
          } else {
            .missingRouteType
          }
        errorCallback?(
          CIFPError.aggregationError(recordType: "SID", identifier: key, reason: reason),
          nil
        )
        continue
      }
      sids.append(
        SID(
          airportId: first.airportId,
          icaoRegion: first.icaoRegion,
          identifier: first.procedureId,
          routeType: routeType,
          transitionId: first.transitionId,
          runwayNames: [],
          legs: legs.map(\.leg).sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
        )
      )
    }
    return sids
  }

  private func buildSTARs(errorCallback: ((Error, Int?) -> Void)?) -> [STAR] {
    var stars: [STAR] = []
    for (key, legs) in starLegs {
      guard let first = legs.first,
        let routeTypeChar = first.routeType,
        let routeType = STARRouteType(rawValue: routeTypeChar)
      else {
        let reason: AggregationErrorReason =
          if let first = legs.first, let char = first.routeType {
            .invalidRouteType(char)
          } else {
            .missingRouteType
          }
        errorCallback?(
          CIFPError.aggregationError(recordType: "STAR", identifier: key, reason: reason),
          nil
        )
        continue
      }
      stars.append(
        STAR(
          airportId: first.airportId,
          icaoRegion: first.icaoRegion,
          identifier: first.procedureId,
          routeType: routeType,
          transitionId: first.transitionId,
          runwayNames: [],
          legs: legs.map(\.leg).sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
        )
      )
    }
    return stars
  }

  private func buildApproaches(errorCallback: ((Error, Int?) -> Void)?) -> [Approach] {
    var approaches: [Approach] = []
    for (key, legRecords) in approachLegs {
      guard let first = legRecords.first,
        let approachTypeChar = first.routeType,
        let approachType = ApproachType(rawValue: approachTypeChar)
      else {
        let reason: AggregationErrorReason =
          if let first = legRecords.first, let char = first.routeType {
            .invalidApproachType(char)
          } else {
            .missingApproachType
          }
        errorCallback?(
          CIFPError.aggregationError(recordType: "Approach", identifier: key, reason: reason),
          nil
        )
        continue
      }
      let sortedRecords = legRecords.sorted(by: { $0.leg.sequenceNumber < $1.leg.sequenceNumber })

      // All legs at or after the first missed approach marker are missed approach legs.
      // The FAA CIFP data only explicitly marks the first missed approach leg; subsequent
      // legs (e.g., DF back to a hold fix, HM at the hold) lack the marker.
      let firstMissedIndex =
        sortedRecords.firstIndex(where: \.isMissedApproach)
        ?? sortedRecords.endIndex
      let mainLegs = sortedRecords[..<firstMissedIndex].map(\.leg)
      let missedLegs = sortedRecords[firstMissedIndex...].map(\.leg)

      // Look up continuation record for SBAS/LPV data
      let continuation = approachContinuations[key]

      approaches.append(
        Approach(
          airportId: first.airportId,
          icaoRegion: first.icaoRegion,
          identifier: first.procedureId,
          approachType: approachType,
          routeType: nil,
          transitionId: first.transitionId,
          runwayId: nil,
          multipleIndicator: nil,
          legs: mainLegs,
          missedApproachLegs: missedLegs,
          sbasServiceLevel: continuation?.sbasServiceLevel,
          requiredNavPerformance: continuation?.requiredNavPerformance,
          lateralNavCapability: continuation?.lateralNavCapability
        )
      )
    }
    return approaches
  }

  private func buildControlledAirspaces(errorCallback: ((Error, Int?) -> Void)?)
    -> [ControlledAirspace]
  {
    var controlledAirspaces: [ControlledAirspace] = []
    for (key, records) in controlledAirspaceRecords {
      guard let first = records.first else {
        errorCallback?(
          CIFPError.aggregationError(
            recordType: "ControlledAirspace",
            identifier: key,
            reason: .noBoundaryRecords
          ),
          nil
        )
        continue
      }
      controlledAirspaces.append(
        ControlledAirspace(
          icaoRegion: first.icaoRegion,
          airspaceCenter: first.centerOrDesignation,
          airspaceClass: first.airspaceClass,
          multipleCode: first.multipleCode,
          name: first.name,
          boundaries: records.map(\.boundary).sorted(by: { $0.sequenceNumber < $1.sequenceNumber }),
          lowerLimit: first.lowerLimit,
          upperLimit: first.upperLimit
        )
      )
    }
    return controlledAirspaces
  }

  private func buildSpecialUseAirspaces(errorCallback: ((Error, Int?) -> Void)?)
    -> [SpecialUseAirspace]
  {
    var specialUseAirspaces: [SpecialUseAirspace] = []
    for (key, records) in specialUseAirspaceRecords {
      guard let first = records.first,
        let restrictiveType = first.restrictiveType
      else {
        let reason: AggregationErrorReason =
          if records.first != nil {
            .missingRestrictiveType
          } else {
            .noBoundaryRecords
          }
        errorCallback?(
          CIFPError.aggregationError(
            recordType: "SpecialUseAirspace",
            identifier: key,
            reason: reason
          ),
          nil
        )
        continue
      }
      specialUseAirspaces.append(
        SpecialUseAirspace(
          icaoRegion: first.icaoRegion,
          restrictiveType: restrictiveType,
          designation: first.centerOrDesignation,
          multipleCode: first.multipleCode,
          name: first.name,
          boundaries: records.map(\.boundary).sorted(by: { $0.sequenceNumber < $1.sequenceNumber }),
          lowerLimit: first.lowerLimit,
          upperLimit: first.upperLimit
        )
      )
    }
    return specialUseAirspaces
  }

  private func buildHeliportApproaches(errorCallback: ((Error, Int?) -> Void)?)
    -> [HeliportApproach]
  {
    var heliportApproaches: [HeliportApproach] = []
    for (key, legs) in heliportApproachLegs {
      guard let first = legs.first else {
        errorCallback?(
          CIFPError.aggregationError(
            recordType: "HeliportApproach",
            identifier: key,
            reason: .noLegRecords
          ),
          nil
        )
        continue
      }
      heliportApproaches.append(
        HeliportApproach(
          parentId: first.airportId,
          icaoRegion: first.icaoRegion,
          identifier: first.procedureId,
          approachType: nil,
          transitionId: nil,
          legs: legs.map(\.leg).sorted(by: { $0.sequenceNumber < $1.sequenceNumber }),
          missedApproachLegs: []
        )
      )
    }
    return heliportApproaches
  }

  private func buildHeliportMSAs() -> [HeliportMSA] {
    var heliportMSAs: [HeliportMSA] = []
    for (_, value) in heliportMSARecords {
      heliportMSAs.append(
        HeliportMSA(
          parentId: value.base.parentId,
          icaoRegion: value.base.icaoRegion,
          center: value.base.center,
          radiusNM: value.base.radius,
          sectors: Set(value.sectors)
        )
      )
    }
    return heliportMSAs
  }

  private func buildPathPoints() -> [PathPoint] {
    var pathPoints: [PathPoint] = []
    for (_, record) in pathPointRecords {
      guard let primary = record.primary else {
        // Continuation record without primary - skip (orphaned continuation)
        continue
      }
      let continuation = record.continuation
      pathPoints.append(
        PathPoint(
          airportId: primary.airportId,
          icaoRegion: primary.icaoRegion,
          approachId: primary.approachId,
          runwayId: primary.runwayId,
          pathPointType: primary.pathPointType,
          coordinate: primary.coordinate,
          ellipsoidHeightFt: primary.ellipsoidHeightFt,
          glidepathAngleDeg: primary.glidepathAngleDeg,
          flightPathAlignmentPoint: primary.flightPathAlignmentPoint,
          courseWidthM: primary.courseWidthM,
          lengthOffsetM: primary.lengthOffsetM,
          referencePathId: primary.referencePathId,
          fpapEllipsoidHeightFt: continuation?.fpapEllipsoidHeightFt,
          fpapOrthometricHeightFt: continuation?.fpapOrthometricHeightFt,
          ltpOrthometricHeightFt: continuation?.ltpOrthometricHeightFt,
          approachTypeIdentifier: continuation?.approachTypeIdentifier,
          gnssChannelNumber: continuation?.gnssChannelNumber,
          helicopterProcedureCourse: continuation?.helicopterProcedureCourse
        )
      )
    }
    return pathPoints
  }

  private func foldChildrenIntoAirports(
    _ airports: [String: Airport],
    runways: [Runway],
    waypoints: [TerminalWaypoint],
    navaids: [TerminalNavaid],
    localizers: [LocalizerGlideSlope],
    pathPoints: [PathPoint],
    msas: [MSA],
    sids: [SID],
    stars: [STAR],
    approaches: [Approach]
  ) -> [String: Airport] {
    var foldedAirports = airports
    let runwaysByAirport = Dictionary(grouping: runways) { $0.airportId }
    for (airportId, aptRunways) in runwaysByAirport {
      foldedAirports[airportId]?.runways = aptRunways
    }
    let waypointsByAirport = Dictionary(grouping: waypoints) { $0.airportId }
    for (airportId, wpts) in waypointsByAirport {
      foldedAirports[airportId]?.terminalWaypoints = wpts
    }
    let navaidsByAirport = Dictionary(grouping: navaids) { $0.airportId }
    for (airportId, navs) in navaidsByAirport {
      foldedAirports[airportId]?.terminalNavaids = navs
    }
    let localizersByAirport = Dictionary(grouping: localizers) { $0.airportId }
    for (airportId, locs) in localizersByAirport {
      foldedAirports[airportId]?.localizers = locs
    }
    let pathPointsByAirport = Dictionary(grouping: pathPoints) { $0.airportId }
    for (airportId, points) in pathPointsByAirport {
      foldedAirports[airportId]?.pathPoints = points
    }
    let msasByAirport = Dictionary(grouping: msas) { $0.airportId }
    for (airportId, airportMsas) in msasByAirport {
      foldedAirports[airportId]?.msaRecords = airportMsas
    }
    let sidsByAirport = Dictionary(grouping: sids) { $0.airportId }
    for (airportId, airportSids) in sidsByAirport {
      foldedAirports[airportId]?.sids = airportSids
    }
    let starsByAirport = Dictionary(grouping: stars) { $0.airportId }
    for (airportId, airportStars) in starsByAirport {
      foldedAirports[airportId]?.stars = airportStars
    }
    let approachesByAirport = Dictionary(grouping: approaches) { $0.airportId }
    for (airportId, airportApproaches) in approachesByAirport {
      foldedAirports[airportId]?.approaches = airportApproaches
    }
    return foldedAirports
  }

  private func foldChildrenIntoHeliports(
    _ heliports: [String: Heliport],
    waypoints: [HeliportWaypoint],
    approaches: [HeliportApproach],
    msas: [HeliportMSA]
  ) -> [String: Heliport] {
    var foldedHeliports = heliports
    let waypointsByHeliport = Dictionary(grouping: waypoints) { $0.parentId }
    for (heliportId, wpts) in waypointsByHeliport {
      foldedHeliports[heliportId]?.waypoints = wpts
    }
    let approachesByHeliport = Dictionary(grouping: approaches) { $0.parentId }
    for (heliportId, apps) in approachesByHeliport {
      foldedHeliports[heliportId]?.approaches = apps
    }
    let msasByHeliport = Dictionary(grouping: msas) { $0.parentId }
    for (heliportId, msaList) in msasByHeliport {
      foldedHeliports[heliportId]?.msaRecords = msaList
    }
    return foldedHeliports
  }

  // MARK: - Header Parsing

  /// Parses header information from HDR01-HDR05 records.
  ///
  /// HDR01 format (FAA CIFP):
  /// - Positions 0-4: Record ID (HDR01)
  /// - Positions 5-19: File name (15 chars, e.g., "FAACIFP18      ")
  /// - Positions 20-22: Version number (3 chars)
  /// - Position 23: File type (P=Production, T=Test)
  /// - Positions 24-30: Record count (7 digits)
  /// - Positions 31-34: Reserved (4 chars)
  /// - Positions 35-38: Cycle ID (YYMM)
  private func parseHeader(from headerText: [String]) -> Header {
    // Find HDR01 line
    guard let hdr01 = headerText.first(where: { $0.hasPrefix("HDR01") }) else {
      return defaultHeader(descriptiveText: headerText)
    }

    // Parse HDR01 fields (0-based indices)
    let fileName = extractField(from: hdr01, start: 5, length: 15),
      versionNumber = extractField(from: hdr01, start: 20, length: 3),
      fileTypeChar = extractField(from: hdr01, start: 23, length: 1),
      recordCountStr = extractField(from: hdr01, start: 24, length: 7),
      cycleId = extractField(from: hdr01, start: 35, length: 4)

    // Parse file type
    let fileType = FileType(rawValue: fileTypeChar) ?? .production

    // Parse record count
    let recordCount = Int(recordCountStr) ?? 0

    // Parse creation date from HDR01 (format: DD-MMM-YYYY starting around column 41)
    let creationDateComponents = parseCreationDate(from: hdr01)

    // Extract data supplier - typically in HDR01 after the date
    let dataSupplier = parseDataSupplier(from: hdr01)

    return Header(
      fileName: fileName,
      volumeSet: "",
      versionNumber: versionNumber,
      fileType: fileType,
      recordCount: recordCount,
      cycleId: cycleId,
      creationDateComponents: creationDateComponents,
      dataSupplier: dataSupplier,
      descriptiveText: headerText
    )
  }

  /// Extracts a field from a string at the given position.
  private func extractField(from string: String, start: Int, length: Int) -> String {
    guard start >= 0, start < string.count else { return "" }
    let startIndex = string.index(string.startIndex, offsetBy: start),
      endOffset = min(start + length, string.count),
      endIndex = string.index(string.startIndex, offsetBy: endOffset)
    return String(string[startIndex..<endIndex]).trimmingCharacters(in: .whitespaces)
  }

  private func parseCreationDate(from hdr01: String) -> DateComponents? {
    // Look for DD-MMM-YYYY pattern
    guard let match = hdr01.firstMatch(of: Self.creationDateRegex) else {
      return nil
    }
    let dateStr = String(match.0)
    guard let date = Self.creationDateFormatter.date(from: dateStr) else { return nil }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar.dateComponents([.year, .month, .day], from: date)
  }

  /// Parses the data supplier from HDR01.
  private func parseDataSupplier(from hdr01: String) -> String {
    // Data supplier is typically after the timestamp, before the CRC
    // Look for patterns like "U.S.A. DOT FAA" or "FAA"
    if hdr01.contains("FAA") {
      return "FAA"
    }
    return "Unknown"
  }

  /// Returns a default header when HDR01 cannot be parsed.
  private func defaultHeader(descriptiveText: [String]) -> Header {
    Header(
      fileName: "FAACIFP18",
      volumeSet: "",
      versionNumber: "001",
      fileType: .production,
      recordCount: 0,
      cycleId: "",
      creationDateComponents: nil,
      dataSupplier: "FAA",
      descriptiveText: descriptiveText
    )
  }
}

/// Result of building a CIFP from parsed records.
private struct CIFPBuildResult {
  let header: Header
  let cycle: Cycle
  let gridMORAs: [GridMORA]
  let vhfNavaids: [String: VHFNavaid]
  let ndbNavaids: [String: NDBNavaid]
  let enrouteWaypoints: [String: EnrouteWaypoint]
  let airways: [String: Airway]
  /// Airports with folded children (runways, waypoints, procedures, etc.)
  let airports: [String: Airport]
  /// Terminal waypoints kept for fix resolution in CIFPData
  let terminalWaypoints: [TerminalWaypoint]
  let controlledAirspaces: [ControlledAirspace]
  let specialUseAirspaces: [SpecialUseAirspace]
  /// Heliports with folded children (waypoints, approaches, MSAs)
  let heliports: [String: Heliport]
}
