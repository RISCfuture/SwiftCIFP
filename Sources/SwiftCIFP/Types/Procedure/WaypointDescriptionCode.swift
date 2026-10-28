import Foundation

/// Waypoint description code (ARINC 424 field 5.17, record columns 40–43).
///
/// Each column carries an independent meaning. A blank column is `nil`.
public struct WaypointDescriptionCode: Sendable, Codable, Equatable, Hashable {
  /// Column 40 - Fix type.
  public let fixType: FixType?

  /// Column 41 - Fly-over or fly-by, and charting status. A blank column is a fly-by fix.
  public let fixStatus: FixStatus?

  /// Column 42 - Fix function.
  public let fixFunction: FixFunction?

  /// Column 43 - Approach role.
  public let approachRole: ApproachRole?

  /// The four-character code as published, with blank columns as spaces.
  public var code: String {
    String(
      [fixType?.rawValue, fixStatus?.rawValue, fixFunction?.rawValue, approachRole?.rawValue]
        .map { $0 ?? " " }
    )
  }

  /// Whether this is an initial approach fix (IAF), including one with holding or one that
  /// is also the final approach course fix.
  public var isIAF: Bool {
    switch approachRole {
      case .initialApproachFix, .initialApproachFixWithHolding, .initialApproachFixWithFACF:
        true
      default:
        false
    }
  }

  /// Whether this is an intermediate approach fix.
  public var isIntermediateFix: Bool {
    approachRole == .intermediateApproachFix
  }

  /// Whether this is a final approach fix (FAF).
  public var isFAF: Bool {
    approachRole == .finalApproachFix
  }

  /// Whether this is a final approach course fix (FACF).
  public var isFACF: Bool {
    approachRole == .finalApproachCourseFix || approachRole == .initialApproachFixWithFACF
  }

  /// Whether this is a missed approach point (MAP).
  public var isMAP: Bool {
    approachRole == .missedApproachPoint
  }

  /// Whether this leg begins the missed approach procedure.
  public var isFirstMissedApproachLeg: Bool {
    fixFunction == .firstMissedApproachLeg
  }

  /// Whether this is a named or unnamed step-down fix.
  public var isStepDown: Bool {
    switch fixFunction {
      case .namedStepDown, .unnamedStepDownBeforeFAF, .unnamedStepDownAfterFAF:
        true
      default:
        false
    }
  }

  /// Whether this is a fly-over waypoint. Waypoints that are not fly-over are fly-by.
  public var isFlyover: Bool {
    fixStatus == .flyover || fixStatus == .flyoverEndOfRoute
  }

  /// Creates a waypoint description code.
  init(
    fixType: FixType?,
    fixStatus: FixStatus?,
    fixFunction: FixFunction?,
    approachRole: ApproachRole?
  ) {
    self.fixType = fixType
    self.fixStatus = fixStatus
    self.fixFunction = fixFunction
    self.approachRole = approachRole
  }
}

// MARK: - Column Codes

extension WaypointDescriptionCode {
  /// Column 40: the fix type.
  public enum FixType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Airport as waypoint.
    case airport = "A"

    /// Essential waypoint.
    case essential = "E"

    /// Off airway.
    case offAirway = "F"

    /// Runway or helipad as waypoint.
    case runway = "G"

    /// Heliport as waypoint.
    case heliport = "H"

    /// NDB navaid.
    case ndb = "N"

    /// Phantom waypoint.
    case phantom = "P"

    /// Non-essential reporting.
    case nonEssential = "R"

    /// Transition essential waypoint.
    case transitionEssential = "T"

    /// VHF navaid.
    case vhf = "V"
  }

  /// Column 41: fly-over or fly-by, and charting status.
  public enum FixStatus: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Fly-over waypoint ending a SID or STAR route, an approach transition, or a final
    /// approach.
    case flyoverEndOfRoute = "B"

    /// End of an en route airway or terminal procedure route.
    case endOfRoute = "E"

    /// Uncharted airway intersection.
    case unchartedAirwayIntersection = "U"

    /// Fly-over waypoint.
    case flyover = "Y"
  }

  /// Column 42: the fix function.
  public enum FixFunction: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Unnamed step-down fix after the final approach fix.
    case unnamedStepDownAfterFAF = "A"

    /// Unnamed step-down fix before the final approach fix.
    case unnamedStepDownBeforeFAF = "B"

    /// ATC compulsory reporting point.
    case atcCompulsory = "C"

    /// Oceanic gateway.
    case oceanicGateway = "G"

    /// First leg of the missed approach procedure.
    ///
    /// This marks where the missed approach sequence begins, which is the leg after the
    /// missed approach point. It does not identify the missed approach point itself.
    case firstMissedApproachLeg = "M"

    /// Path point fix.
    case pathPoint = "P"

    /// Fix marking a course change on the final approach.
    case turningFinalApproach = "R"

    /// Named step-down fix.
    case namedStepDown = "S"
  }

  /// Column 43: the fix's role in an approach.
  public enum ApproachRole: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Initial approach fix (IAF).
    case initialApproachFix = "A"

    /// Intermediate approach fix.
    case intermediateApproachFix = "B"

    /// Initial approach fix with holding.
    case initialApproachFixWithHolding = "C"

    /// Initial approach fix that is also the final approach course fix.
    case initialApproachFixWithFACF = "D"

    /// Final end point fix.
    case finalEndPoint = "E"

    /// Published or database final approach fix (FAF).
    case finalApproachFix = "F"

    /// Holding fix.
    case holdingFix = "H"

    /// Final approach course fix (FACF).
    case finalApproachCourseFix = "I"

    /// Published missed approach point (MAP).
    case missedApproachPoint = "M"
  }
}
