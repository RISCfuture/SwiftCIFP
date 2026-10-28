import Foundation

/// Waypoint type (ARINC 424 field 5.42, record columns 27–29).
///
/// Each column carries an independent meaning. A blank column is `nil`.
public struct WaypointType: Sendable, Codable, Equatable, Hashable {
  /// Column 27 - What kind of fix the waypoint is.
  public let kind: Kind?

  /// Column 28 - The waypoint's role in an approach or the airspace structure.
  public let function: Function?

  /// Column 29 - The kind of terminal procedure the waypoint is used in.
  public let procedureUse: ProcedureUse?
}

// MARK: - Column Codes

extension WaypointType {
  /// Column 27: what kind of fix the waypoint is.
  public enum Kind: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Arc center fix (terminal waypoints).
    case arcCenterFix = "A"

    /// Named intersection that is also an RNAV waypoint.
    case combinedNamedIntersectionAndRNAV = "C"

    /// Unnamed, charted intersection.
    case unnamedChartedIntersection = "I"

    /// Middle marker as waypoint (terminal waypoints).
    case middleMarker = "M"

    /// NDB navaid as waypoint.
    case ndb = "N"

    /// Outer marker as waypoint (terminal waypoints).
    case outerMarker = "O"

    /// Named intersection.
    case namedIntersection = "R"

    /// Uncharted airway intersection (enroute waypoints).
    case unchartedAirwayIntersection = "U"

    /// VFR waypoint.
    case vfr = "V"

    /// RNAV waypoint.
    case rnav = "W"
  }

  /// Column 28: the waypoint's role in an approach or the airspace structure.
  ///
  /// Enroute and terminal waypoints share most codes but assign "P" and "S" differently.
  public enum Function: Sendable, Codable, Equatable, Hashable, CaseIterable {
    /// Final approach fix.
    case finalApproachFix

    /// Initial approach fix that is also the final approach fix.
    case initialAndFinalApproachFix

    /// Final approach course fix.
    case finalApproachCourseFix

    /// Intermediate approach fix.
    case intermediateApproachFix

    /// Off-route intersection in the FAA National Reference System (enroute waypoints).
    case offRouteIntersectionInNationalReferenceSystem

    /// Off-route intersection (enroute waypoints).
    case offRouteIntersection

    /// Initial approach fix.
    case initialApproachFix

    /// Final approach course fix at an initial approach fix.
    case finalApproachCourseFixAtIAF

    /// Final approach course fix at an intermediate approach fix.
    case finalApproachCourseFixAtIntermediateFix

    /// Missed approach fix.
    case missedApproachFix

    /// Initial approach fix that is also the missed approach fix.
    case initialAndMissedApproachFix

    /// Oceanic entry or exit waypoint (enroute waypoints).
    case oceanicEntryExit

    /// Pitch and catch point in the FAA High Altitude Redesign (enroute waypoints).
    case pitchAndCatchPoint

    /// AACAA or special use airspace waypoint in the FAA High Altitude Redesign (enroute
    /// waypoints).
    case highAltitudeRedesignAirspaceWaypoint

    /// Unnamed step-down fix (terminal waypoints).
    case unnamedStepDownFix

    /// Named step-down fix (terminal waypoints).
    case namedStepDownFix

    /// FIR/UIR or controlled airspace intersection.
    case airspaceIntersection

    /// Latitude/longitude intersection on a full degree of latitude (enroute waypoints).
    case fullDegreeLatitudeLongitudeIntersection

    /// Latitude/longitude intersection on a half degree of latitude (enroute waypoints).
    case halfDegreeLatitudeLongitudeIntersection

    /// Creates a function from an enroute waypoint's column 28 code.
    init?(enrouteCode code: Character) {
      switch code {
        case "E": self = .offRouteIntersectionInNationalReferenceSystem
        case "F": self = .offRouteIntersection
        case "O": self = .oceanicEntryExit
        case "P": self = .pitchAndCatchPoint
        case "S": self = .highAltitudeRedesignAirspaceWaypoint
        case "V": self = .fullDegreeLatitudeLongitudeIntersection
        case "W": self = .halfDegreeLatitudeLongitudeIntersection
        default: self.init(sharedCode: code)
      }
    }

    /// Creates a function from a terminal waypoint's column 28 code.
    init?(terminalCode code: Character) {
      switch code {
        case "P": self = .unnamedStepDownFix
        case "S": self = .namedStepDownFix
        default: self.init(sharedCode: code)
      }
    }

    private init?(sharedCode code: Character) {
      switch code {
        case "A": self = .finalApproachFix
        case "B": self = .initialAndFinalApproachFix
        case "C": self = .finalApproachCourseFix
        case "D": self = .intermediateApproachFix
        case "I": self = .initialApproachFix
        case "K": self = .finalApproachCourseFixAtIAF
        case "L": self = .finalApproachCourseFixAtIntermediateFix
        case "M": self = .missedApproachFix
        case "N": self = .initialAndMissedApproachFix
        case "U": self = .airspaceIntersection
        default: return nil
      }
    }
  }

  /// Column 29: the kind of terminal procedure the waypoint is used in.
  public enum ProcedureUse: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// SID.
    case sid = "D"

    /// STAR.
    case star = "E"

    /// Approach.
    case approach = "F"

    /// More than one kind of procedure.
    case multiple = "Z"
  }
}
