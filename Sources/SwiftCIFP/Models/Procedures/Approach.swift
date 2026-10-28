import Foundation

/// Approach procedure.
///
/// Instrument approach procedures provide guidance from the enroute
/// environment to a point from which a landing can be completed.
public struct Approach: Sendable, Codable, ProcedureLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Approach identifier (e.g., "I09L", "R27", "V15").
  public let identifier: String

  /// Approach type (ILS, RNAV, VOR, etc.), shared by the procedure's transitions and its
  /// final approach route.
  public let approachType: ApproachType

  /// Whether this route is a transition or the final approach.
  public let routeType: RouteType

  /// The navigation equipment this route requires.
  public let navigationRequirement: NavigationRequirement?

  /// Whether this route's minimums are for a straight-in landing, a circling landing,
  /// or a helipad.
  public let landing: Landing?

  /// Transition identifier (if this is a transition).
  public let transitionId: String?

  /// Approach legs (excluding missed approach).
  public internal(set) var legs: [ProcedureLeg]

  /// Missed approach legs.
  public internal(set) var missedApproachLegs: [ProcedureLeg]

  /// The procedure's lines of minimums, if it publishes a level of service record.
  public let levelsOfService: LevelsOfService?

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
    routeType: RouteType,
    navigationRequirement: NavigationRequirement? = nil,
    landing: Landing? = nil,
    transitionId: String?,
    legs: [ProcedureLeg],
    missedApproachLegs: [ProcedureLeg],
    levelsOfService: LevelsOfService? = nil
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.approachType = approachType
    self.routeType = routeType
    self.navigationRequirement = navigationRequirement
    self.landing = landing
    self.transitionId = transitionId
    self.legs = legs
    self.missedApproachLegs = missedApproachLegs
    self.levelsOfService = levelsOfService
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, identifier, approachType
    case routeType, navigationRequirement, landing, transitionId, legs, missedApproachLegs
    case levelsOfService
    // Note: 'data' is excluded
  }
}

// MARK: - Route Type

extension Approach {
  /// The part of an approach procedure a route covers (ARINC 424 field 5.7).
  public enum RouteType: Sendable, Codable, Hashable, CaseIterable {
    /// An approach transition, leading to the final approach route.
    case transition

    /// The final approach route, including its missed approach.
    case finalApproach

    /// A separately coded missed approach.
    case missedApproach

    private static let transitionCode: Character = "A",
      missedApproachCode: Character = "Z"

    /// Creates a route type from its record code: "A" for a transition, "Z" for a missed
    /// approach, or the approach type code for a final approach route.
    init?(code: Character) {
      switch code {
        case Self.transitionCode: self = .transition
        case Self.missedApproachCode: self = .missedApproach
        case _ where ApproachType(rawValue: code) != nil: self = .finalApproach
        default: return nil
      }
    }
  }
}

// MARK: - Route Qualifiers

extension Approach {
  /// The navigation equipment an approach requires (ARINC 424 field 5.7, route qualifier 1).
  public enum NavigationRequirement: Character, Sendable, Codable, CaseIterable,
    ByteInitializable
  {
    /// DME required.
    case dmeRequired = "D"

    /// RNP authorization required. The FAA codes this on RNAV (RNP) approaches.
    case rnpAR = "F"

    /// GPS required; DME/DME to the procedure's RNP not authorized.
    case gpsRequiredDMEDMENotAuthorized = "J"

    /// GBAS procedure.
    case gbas = "L"

    /// DME not required.
    case dmeNotRequired = "N"

    /// GPS required.
    case gpsRequired = "P"

    /// GPS, or DME/DME to the procedure's RNP, required.
    case gpsOrDMEDMERequired = "R"

    /// DME/DME required.
    case dmeDMERequired = "T"

    /// RNAV, sensor not specified.
    case rnavSensorNotSpecified = "U"

    /// VOR/DME RNAV.
    case vorDMERNAV = "V"

    /// SBAS procedure.
    case sbas = "W"
  }

  /// The kind of landing an approach's minimums are for (ARINC 424 field 5.7, route
  /// qualifier 2).
  public enum Landing: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Straight-in minimums.
    case straightIn = "S"

    /// Circle-to-land minimums.
    case circleToLand = "C"

    /// A helicopter approach to a helipad.
    case helipad = "H"
  }
}

// MARK: - Identifier Components

extension Approach {
  private static let runwayPrefix = "RW",
    runwayDesignations: Set<Character> = ["L", "R", "C", "T"]

  /// The runway the approach serves (e.g., "RW19L"), or nil for a circling approach or one
  /// identified by its final approach course.
  public var runwayId: String? {
    let characters = Array(identifier)
    guard characters.count >= 3, characters[1...2].allSatisfy(\.isWholeNumber),
      characters.count == 3 || !characters[3].isWholeNumber
    else { return nil }

    let designation =
      characters.count > 3 && Self.runwayDesignations.contains(characters[3])
      ? String(characters[3]) : ""
    return Self.runwayPrefix + String(characters[1...2]) + designation
  }

  /// The letter distinguishing approaches of the same type to the same runway (the "Z" of
  /// "RNAV (GPS) Z RWY 12").
  public var multipleIndicator: String? {
    let characters = Array(identifier)
    return characters.count > 4 ? String(characters[4]) : nil
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
