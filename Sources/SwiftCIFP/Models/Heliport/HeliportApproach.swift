import Foundation

/// Heliport approach procedure.
public struct HeliportApproach: Sendable, Codable, ProcedureLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent heliport ICAO identifier.
  let parentId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Approach identifier.
  public let identifier: String

  /// Approach type, shared by the procedure's transitions and its final approach route.
  public let approachType: ApproachType

  /// Whether this route is a transition or the final approach.
  public let routeType: Approach.RouteType

  /// The navigation equipment this route requires.
  public let navigationRequirement: Approach.NavigationRequirement?

  /// Whether this route's minimums are for a straight-in landing, a circling landing,
  /// or a helipad.
  public let landing: Approach.Landing?

  /// Transition identifier.
  public let transitionId: String?

  /// Procedure legs.
  public internal(set) var legs: [ProcedureLeg]

  /// Missed approach legs.
  public internal(set) var missedApproachLegs: [ProcedureLeg]

  /// The procedure's lines of minimums, if it publishes a level of service record.
  public let levelsOfService: Approach.LevelsOfService?

  /// Creates a HeliportApproach record.
  init(
    parentId: String,
    icaoRegion: String,
    identifier: String,
    approachType: ApproachType,
    routeType: Approach.RouteType,
    navigationRequirement: Approach.NavigationRequirement?,
    landing: Approach.Landing?,
    transitionId: String?,
    legs: [ProcedureLeg],
    missedApproachLegs: [ProcedureLeg],
    levelsOfService: Approach.LevelsOfService?
  ) {
    self.parentId = parentId
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
    case parentId, icaoRegion, identifier, approachType
    case routeType, navigationRequirement, landing, transitionId, legs
    case missedApproachLegs, levelsOfService
    // Note: 'data' is excluded
  }
}

// MARK: - HeliportApproach Identifiable, Equatable, Hashable

extension HeliportApproach: Identifiable, Equatable, Hashable {
  public var id: String {
    var components = [parentId, identifier]
    if let transitionId {
      components.append(transitionId)
    }
    return components.joined(separator: "-")
  }

  public static func == (lhs: HeliportApproach, rhs: HeliportApproach) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - HeliportApproach ProcedureLinkable

extension HeliportApproach {
  /// Injects fix and navaid resolver closures into the procedure's legs.
  mutating func injectLegResolvers(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  ) {
    // Inject into approach legs
    for i in legs.indices {
      legs[i].findFix = findFix
      legs[i].findNavaid = findNavaid
      legs[i].parentAirportId = parentId
    }

    // Inject into missed approach legs
    for i in missedApproachLegs.indices {
      missedApproachLegs[i].findFix = findFix
      missedApproachLegs[i].findNavaid = findNavaid
      missedApproachLegs[i].parentAirportId = parentId
    }
  }
}

// MARK: - HeliportApproach Linked Properties

extension HeliportApproach {
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

  /// All legs including missed approach.
  public var allLegs: [ProcedureLeg] {
    legs + missedApproachLegs
  }
}
