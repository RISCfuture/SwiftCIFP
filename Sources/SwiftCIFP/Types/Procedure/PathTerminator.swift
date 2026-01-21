import Foundation

/// Path terminator codes defining how procedure legs are flown.
///
/// These two-character codes specify the type of path and the
/// termination point for each leg of a flight procedure.
public enum PathTerminator: String, Sendable, Codable, CaseIterable {
  /// Initial Fix - starting point of a procedure.
  case initialFix = "IF"

  /// Track to Fix - fly direct track to a fix.
  case trackToFix = "TF"

  /// Course to Fix - intercept and fly course to fix.
  case courseToFix = "CF"

  /// Direct to Fix - fly direct to fix (any track).
  case directToFix = "DF"

  /// Fix to Altitude - climb/descend from fix to altitude.
  case fixToAltitude = "FA"

  /// Track from Fix to Distance - fly track for specified distance.
  case trackFromFixDistance = "FC"

  /// Track from Fix to DME - fly track to DME distance from navaid.
  case trackFromFixDME = "FD"

  /// From Fix to Manual termination.
  case fromFixManual = "FM"

  /// Course to Altitude - fly course until reaching altitude.
  case courseToAltitude = "CA"

  /// Course to DME Distance - fly course to DME distance.
  case courseToDME = "CD"

  /// Course to Intercept - fly course to intercept next leg.
  case courseToIntercept = "CI"

  /// Course to Radial - fly course to intercept radial.
  case courseToRadial = "CR"

  /// Arc to Fix - fly DME arc to fix.
  case arcToFix = "AF"

  /// Radius to Fix - fly constant-radius arc to fix.
  case radiusToFix = "RF"

  /// Heading to Altitude - fly heading until altitude.
  case headingToAltitude = "VA"

  /// Heading to DME Distance - fly heading to DME distance.
  case headingToDME = "VD"

  /// Heading to Intercept - fly heading to intercept next leg.
  case headingToIntercept = "VI"

  /// Heading to Manual termination.
  case headingManual = "VM"

  /// Heading to Radial - fly heading to intercept radial.
  case headingToRadial = "VR"

  /// Procedure Turn - course reversal maneuver.
  case procedureTurn = "PI"

  /// Hold to Altitude - hold until reaching altitude.
  case holdToAltitude = "HA"

  /// Hold to Fix - hold pattern terminating at fix.
  case holdToFix = "HF"

  /// Hold to Manual termination.
  case holdManual = "HM"

  /// Whether this is a hold pattern.
  public var isHoldPattern: Bool {
    switch self {
      case .holdToAltitude, .holdToFix, .holdManual:
        true
      default:
        false
    }
  }
}
