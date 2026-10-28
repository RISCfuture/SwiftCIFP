import Foundation

/// STAR (Standard Terminal Arrival Route) procedure.
///
/// STARs are published arrival procedures that provide a transition
/// from the enroute structure to an approach fix.
public struct STAR: Sendable, Codable, ProcedureLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// STAR identifier (e.g., "RIIVR2", "SEAVU4").
  public let identifier: String

  /// Route type.
  public let routeType: RouteType

  /// Transition identifier (if this is a transition).
  public let transitionId: String?

  /// Associated runway identifier(s).
  public let runwayNames: Set<String>

  /// Procedure legs in sequence.
  public internal(set) var legs: [ProcedureLeg]

  /// The initial fix of the procedure.
  public var startFix: String? {
    legs.first?.fixId
  }

  /// Whether this is an RNAV STAR.
  public var isRNAV: Bool {
    switch routeType {
      case .rnavEnrouteTransition, .rnavCommonRoute, .rnavRunwayTransition:
        true
      default:
        false
    }
  }

  /// Creates a STAR record.
  init(
    airportId: String,
    icaoRegion: String,
    identifier: String,
    routeType: RouteType,
    transitionId: String?,
    runwayNames: Set<String>,
    legs: [ProcedureLeg]
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.routeType = routeType
    self.transitionId = transitionId
    self.runwayNames = runwayNames
    self.legs = legs
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, identifier, routeType
    case transitionId, runwayNames = "runways", legs
    // Note: 'data' is excluded
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension STAR: Identifiable, Equatable, Hashable {
  public var id: String {
    var components = [airportId, identifier]
    if let transitionId {
      components.append(transitionId)
    }
    return components.joined(separator: "-")
  }

  public static func == (lhs: STAR, rhs: STAR) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension STAR: CustomStringConvertible {
  public var description: String {
    var desc = identifier
    if let transitionId {
      desc += ".\(transitionId)"
    }
    return desc
  }
}

// MARK: - ProcedureLinkable

extension STAR {
  /// Injects fix and navaid resolver closures into the procedure's legs.
  mutating func injectLegResolvers(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  ) {
    // Inject into all legs
    for i in legs.indices {
      legs[i].findFix = findFix
      legs[i].findNavaid = findNavaid
      legs[i].parentAirportId = airportId
    }
  }
}

// MARK: - Linked Properties

extension STAR {
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

  /// The associated runway objects.
  ///
  /// This property resolves the `runwayNames` set to actual `Runway` objects
  /// when linked via `CIFPData`.
  public var runways: [Runway] {
    get async {
      guard let data else { return [] }
      guard let airport = await data.airport(airportId) else { return [] }
      return airport.runways.filter { runwayNames.contains($0.name) }
    }
  }
}

// MARK: - Route Type

extension STAR {
  /// STAR route type (arrival procedure).
  public enum RouteType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// STAR enroute transition.
    case enrouteTransition = "1"

    /// STAR or common route.
    case commonRoute = "2"

    /// STAR runway transition.
    case runwayTransition = "3"

    /// RNAV STAR enroute transition.
    case rnavEnrouteTransition = "4"

    /// RNAV STAR or common route.
    case rnavCommonRoute = "5"

    /// RNAV STAR runway transition.
    case rnavRunwayTransition = "6"

    /// Profile descent enroute transition.
    case profileDescentEnrouteTransition = "7"

    /// Profile descent common route.
    case profileDescentCommonRoute = "8"

    /// Profile descent runway transition.
    case profileDescentRunwayTransition = "9"

    /// FMS STAR enroute transition.
    case fmsEnrouteTransition = "F"

    /// FMS STAR or common route.
    case fmsCommonRoute = "M"

    /// FMS STAR runway transition.
    case fmsRunwayTransition = "S"

    /// Whether this route type is a runway transition.
    public var isRunwayTransition: Bool {
      switch self {
        case .runwayTransition, .rnavRunwayTransition, .profileDescentRunwayTransition,
          .fmsRunwayTransition:
          true
        default:
          false
      }
    }
  }
}
