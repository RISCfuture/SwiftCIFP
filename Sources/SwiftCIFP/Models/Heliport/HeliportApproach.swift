import CoreLocation
import Foundation

/// Heliport approach procedure.
public struct HeliportApproach: Sendable, Codable, ProcedureLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Closure for resolving fix identifiers (internal use).
  var findFix: FixResolver?

  /// Closure for resolving navaid identifiers (internal use).
  var findNavaid: NavaidResolver?

  /// Parent heliport ICAO identifier.
  let parentId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Approach identifier.
  public let identifier: String

  /// Approach type.
  public let approachType: ApproachType?

  /// Transition identifier.
  public let transitionId: String?

  /// Procedure legs.
  public internal(set) var legs: [ProcedureLeg]

  /// Missed approach legs.
  public internal(set) var missedApproachLegs: [ProcedureLeg]

  /// Creates a HeliportApproach record.
  init(
    parentId: String,
    icaoRegion: String,
    identifier: String,
    approachType: ApproachType?,
    transitionId: String?,
    legs: [ProcedureLeg],
    missedApproachLegs: [ProcedureLeg]
  ) {
    self.parentId = parentId
    self.icaoRegion = icaoRegion
    self.identifier = identifier
    self.approachType = approachType
    self.transitionId = transitionId
    self.legs = legs
    self.missedApproachLegs = missedApproachLegs
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case parentId, icaoRegion, identifier, approachType
    case transitionId, legs, missedApproachLegs
    // Note: 'data', 'findFix', 'findNavaid' are excluded
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
    self.findFix = findFix
    self.findNavaid = findNavaid

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
