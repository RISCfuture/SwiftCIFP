import Foundation

/// A single leg of a flight procedure (SID, STAR, or Approach).
public struct ProcedureLeg: Sendable, Codable, Equatable, Hashable {

  // MARK: - Linking Properties

  /// Closure for resolving fix identifiers (injected by parent procedure).
  var findFix: FixResolver?

  /// Closure for resolving navaid identifiers (injected by parent procedure).
  var findNavaid: NavaidResolver?

  /// Parent airport identifier (for terminal waypoint resolution).
  var parentAirportId: String?

  /// Sequence number of this leg within the procedure.
  public let sequenceNumber: Int

  /// Fix/waypoint identifier for this leg.
  public let fixId: String?

  /// ICAO region of the fix.
  public let fixICAO: String?

  /// Section code indicating fix type.
  public let fixSectionCode: SectionCode?

  /// Waypoint description code.
  public let waypointDescription: WaypointDescriptionCode?

  /// Turn direction requirement.
  public let turnDirection: TurnDirection?

  /// Required navigation performance value in nautical miles.
  public let rnpNM: Double?

  /// Path terminator code.
  public let pathTerminator: PathTerminator?

  /// Whether the turn direction is valid/required.
  public let isTurnDirectionValid: Bool

  /// Recommended navaid identifier.
  public let recommendedNavaid: String?

  /// Recommended navaid ICAO region.
  public let recommendedNavaidICAO: String?

  /// Arc radius in nautical miles.
  public let arcRadiusNM: Double?

  /// Theta - magnetic bearing to fix from navaid in degrees.
  public let thetaDeg: Double?

  /// Rho - distance to fix from navaid in nautical miles.
  public let rhoNM: Double?

  /// Outbound magnetic course in degrees.
  public let magneticCourseDeg: Double?

  /// Route distance in nm, or hold time in minutes (dual-purpose field).
  public let routeDistanceNMOrMinutes: Double?

  /// Altitude constraint for this leg.
  public let altitudeConstraint: AltitudeConstraint?

  /// Transition altitude in feet.
  public let transitionAltitudeFt: Int?

  /// Speed constraint for this leg.
  public let speedConstraint: SpeedConstraint?

  /// Vertical angle in degrees (for VNAV).
  public let verticalAngleDeg: Double?

  /// Center fix identifier (for RF legs).
  public let centerFix: String?

  /// Center fix ICAO region.
  public let centerFixICAO: String?

  /// Whether this leg is an initial fix.
  public var isInitialFix: Bool {
    pathTerminator == .initialFix
  }

  /// Whether this leg defines a hold pattern.
  public var isHoldPattern: Bool {
    pathTerminator?.isHoldPattern ?? false
  }

  /// Creates a ProcedureLeg.
  init(
    sequenceNumber: Int,
    fixId: String?,
    fixICAO: String?,
    fixSectionCode: SectionCode?,
    waypointDescription: WaypointDescriptionCode?,
    turnDirection: TurnDirection?,
    rnpNM: Double?,
    pathTerminator: PathTerminator?,
    isTurnDirectionValid: Bool,
    recommendedNavaid: String?,
    recommendedNavaidICAO: String?,
    arcRadiusNM: Double?,
    thetaDeg: Double?,
    rhoNM: Double?,
    magneticCourseDeg: Double?,
    routeDistanceNMOrMinutes: Double?,
    altitudeConstraint: AltitudeConstraint?,
    transitionAltitudeFt: Int?,
    speedConstraint: SpeedConstraint?,
    verticalAngleDeg: Double?,
    centerFix: String?,
    centerFixICAO: String?
  ) {
    self.sequenceNumber = sequenceNumber
    self.fixId = fixId
    self.fixICAO = fixICAO
    self.fixSectionCode = fixSectionCode
    self.waypointDescription = waypointDescription
    self.turnDirection = turnDirection
    self.rnpNM = rnpNM
    self.pathTerminator = pathTerminator
    self.isTurnDirectionValid = isTurnDirectionValid
    self.recommendedNavaid = recommendedNavaid
    self.recommendedNavaidICAO = recommendedNavaidICAO
    self.arcRadiusNM = arcRadiusNM
    self.thetaDeg = thetaDeg
    self.rhoNM = rhoNM
    self.magneticCourseDeg = magneticCourseDeg
    self.routeDistanceNMOrMinutes = routeDistanceNMOrMinutes
    self.altitudeConstraint = altitudeConstraint
    self.transitionAltitudeFt = transitionAltitudeFt
    self.speedConstraint = speedConstraint
    self.verticalAngleDeg = verticalAngleDeg
    self.centerFix = centerFix
    self.centerFixICAO = centerFixICAO
  }

  // MARK: - Equatable & Hashable

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.sequenceNumber == rhs.sequenceNumber && lhs.fixId == rhs.fixId
      && lhs.pathTerminator == rhs.pathTerminator
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(sequenceNumber)
    hasher.combine(fixId)
    hasher.combine(pathTerminator)
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case sequenceNumber, fixId, fixICAO, fixSectionCode
    case waypointDescription, turnDirection, rnpNM, pathTerminator
    case isTurnDirectionValid, recommendedNavaid, recommendedNavaidICAO
    case arcRadiusNM, thetaDeg, rhoNM, magneticCourseDeg
    case routeDistanceNMOrMinutes, altitudeConstraint
    case transitionAltitudeFt, speedConstraint
    case verticalAngleDeg, centerFix, centerFixICAO
    // Note: 'findFix', 'findNavaid', 'parentAirportId' are excluded
  }
}

// MARK: - Measurement Extensions

extension ProcedureLeg {
  /// Required navigation performance as a Measurement.
  public var rnp: Measurement<UnitLength>? {
    rnpNM.map { .init(value: $0, unit: .nauticalMiles) }
  }

  /// Arc radius as a Measurement.
  public var arcRadius: Measurement<UnitLength>? {
    arcRadiusNM.map { .init(value: $0, unit: .nauticalMiles) }
  }

  /// Theta (magnetic bearing to fix from navaid) as a Measurement.
  public var theta: Measurement<UnitAngle>? {
    thetaDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Rho (distance to fix from navaid) as a Measurement.
  public var rho: Measurement<UnitLength>? {
    rhoNM.map { .init(value: $0, unit: .nauticalMiles) }
  }

  /// Outbound magnetic course as a Measurement.
  public var magneticCourse: Measurement<UnitAngle>? {
    magneticCourseDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Transition altitude as a Measurement.
  public var transitionAltitude: Measurement<UnitLength>? {
    transitionAltitudeFt.map { .init(value: Double($0), unit: .feet) }
  }

  /// Speed limit as a Measurement.
  public var speedLimit: Measurement<UnitSpeed>? {
    speedConstraint?.speed
  }

  /// Vertical angle as a Measurement.
  public var verticalAngle: Measurement<UnitAngle>? {
    verticalAngleDeg.map { .init(value: $0, unit: .degrees) }
  }
}

// MARK: - Linked Properties

extension ProcedureLeg {
  /// The resolved fix for this leg.
  ///
  /// This property uses the injected resolver to find the actual fix object
  /// based on the `fixId`, `fixSectionCode`, and parent airport.
  public var fix: Fix? {
    get async {
      guard let fixId,
        let findFix
      else { return nil }
      return await findFix(fixId, fixSectionCode, parentAirportId)
    }
  }

  /// The resolved recommended navaid for this leg.
  ///
  /// This property uses the injected resolver to find the actual navaid object
  /// based on the `recommendedNavaid` identifier.
  public var navaid: Navaid? {
    get async {
      guard let recommendedNavaid,
        let findNavaid
      else { return nil }
      // Recommended navaids use section code "D" for VHF or "DB" for NDB
      return await findNavaid(recommendedNavaid, nil)
    }
  }

  /// The resolved center fix for RF legs.
  ///
  /// This property uses the injected resolver to find the actual center fix object
  /// used for radius-to-fix (RF) path terminators.
  public var centerFixObject: Fix? {
    get async {
      guard let centerFix,
        let findFix
      else { return nil }
      return await findFix(centerFix, nil, parentAirportId)
    }
  }
}

// MARK: - Comparable

extension ProcedureLeg: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.sequenceNumber < rhs.sequenceNumber
  }
}
