import Foundation

/// Approach procedure.
///
/// Instrument approach procedures provide guidance from the enroute
/// environment to a point from which a landing can be completed.
public struct Approach: Sendable, Codable, ProcedureLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Closure for resolving fix identifiers (internal use).
  var findFix: FixResolver?

  /// Closure for resolving navaid identifiers (internal use).
  var findNavaid: NavaidResolver?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Approach identifier (e.g., "I09L", "R27", "V15").
  public let identifier: String

  /// Approach type (ILS, RNAV, VOR, etc.).
  public let approachType: ApproachType

  /// Route type qualifier.
  public let routeType: ApproachRouteType?

  /// Transition identifier (if this is a transition).
  public let transitionId: String?

  /// Associated runway identifier (e.g., "RW19L").
  public let runwayId: String?

  /// Multiple indicator (for multiple approaches to same runway).
  public let multipleIndicator: String?

  /// Approach legs (excluding missed approach).
  public internal(set) var legs: [ProcedureLeg]

  /// Missed approach legs.
  public internal(set) var missedApproachLegs: [ProcedureLeg]

  // MARK: - SBAS/LPV Continuation Data

  /// SBAS approach service level (LPV, LP, or none).
  public let sbasServiceLevel: SBASServiceLevel?

  /// Required navigation performance for the approach.
  public let requiredNavPerformance: RequiredNavPerformance?

  /// Lateral navigation capability.
  public let lateralNavCapability: LateralNavCapability?

  /// The final approach fix (FAF).
  public var finalApproachFix: ProcedureLeg? {
    legs.first { $0.waypointDescription?.isFAF ?? false }
  }

  /// The missed approach point (MAP).
  public var missedApproachPoint: ProcedureLeg? {
    legs.first { $0.waypointDescription?.isMAP ?? false }
  }

  /// Whether this is a precision approach.
  public var isPrecision: Bool {
    switch approachType {
      case .ils, .gls, .mls, .mlsTypeA, .mlsTypeBC:
        true
      default:
        false
    }
  }

  /// Whether this is an RNAV approach.
  public var isRNAV: Bool {
    switch approachType {
      case .rnav, .gps, .rnpAR:
        true
      default:
        false
    }
  }

  /// All legs including missed approach.
  public var allLegs: [ProcedureLeg] {
    legs + missedApproachLegs
  }

  /// Creates an Approach record.
  init(
    airportId: String,
    icaoRegion: String,
    identifier: String,
    approachType: ApproachType,
    routeType: ApproachRouteType?,
    transitionId: String?,
    runwayId: String?,
    multipleIndicator: String?,
    legs: [ProcedureLeg],
    missedApproachLegs: [ProcedureLeg],
    sbasServiceLevel: SBASServiceLevel? = nil,
    requiredNavPerformance: RequiredNavPerformance? = nil,
    lateralNavCapability: LateralNavCapability? = nil
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.approachType = approachType
    self.routeType = routeType
    self.transitionId = transitionId
    self.runwayId = runwayId
    self.multipleIndicator = multipleIndicator
    self.legs = legs
    self.missedApproachLegs = missedApproachLegs
    self.sbasServiceLevel = sbasServiceLevel
    self.requiredNavPerformance = requiredNavPerformance
    self.lateralNavCapability = lateralNavCapability
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, identifier, approachType
    case routeType, transitionId, runwayId
    case multipleIndicator, legs, missedApproachLegs
    case sbasServiceLevel, requiredNavPerformance, lateralNavCapability
    // Note: 'data', 'findFix', 'findNavaid' are excluded
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension Approach: Identifiable, Equatable, Hashable {
  public var id: String {
    var components = [airportId, identifier]
    if let transitionId {
      components.append(transitionId)
    }
    return components.joined(separator: "-")
  }

  public static func == (lhs: Approach, rhs: Approach) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension Approach: CustomStringConvertible {
  public var description: String {
    var desc = "\(approachType.description) \(identifier)"
    if let transitionId {
      desc += ".\(transitionId)"
    }
    return desc
  }
}

// MARK: - ProcedureLinkable

extension Approach {
  /// Injects fix and navaid resolver closures into the procedure's legs.
  mutating func injectLegResolvers(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  ) {
    self.findFix = findFix
    self.findNavaid = findNavaid

    // Inject into approach legs
    for i in legs.indices {
      legs[i].findFix = findFix
      legs[i].findNavaid = findNavaid
      legs[i].parentAirportId = airportId
    }

    // Inject into missed approach legs
    for i in missedApproachLegs.indices {
      missedApproachLegs[i].findFix = findFix
      missedApproachLegs[i].findNavaid = findNavaid
      missedApproachLegs[i].parentAirportId = airportId
    }
  }
}

// MARK: - Linked Properties

extension Approach {
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

  /// The associated runway.
  ///
  /// This property resolves the `runwayId` to the actual `Runway` object
  /// when linked via `CIFPData`.
  public var runway: Runway? {
    get async {
      guard let runwayId,
        let data
      else { return nil }
      return await data.runway(runwayId, airportId: airportId)
    }
  }
}
