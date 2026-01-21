import Foundation

// MARK: - Procedure Parsing

extension CIFPByteParser {
  static func parseSIDLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    return try parseProcedureLeg(bytes, lineNumber: lineNumber, type: .sid)
  }

  static func parseSTARLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    return try parseProcedureLeg(bytes, lineNumber: lineNumber, type: .star)
  }

  static func parseApproachLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    return try parseProcedureLeg(bytes, lineNumber: lineNumber, type: .approach)
  }

  static func parseHeliportSIDLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    return try parseProcedureLeg(bytes, lineNumber: lineNumber, type: .heliportSID)
  }

  static func parseHeliportSTARLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    return try parseProcedureLeg(bytes, lineNumber: lineNumber, type: .heliportSTAR)
  }

  static func parseProcedureLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int,
    type: ProcedureTypeParser
  ) throws -> ParsedRecord {
    // For approaches, check continuation number at position 38 (0-indexed)
    // Primary records have '0', '1', or blank; continuation records have '2'+
    if type == .approach {
      let contByte = bytes.count > 38 ? bytes[bytes.startIndex + 38] : ASCII.space
      if contByte >= ASCII.two && contByte <= ASCII.nine {
        return try parseApproachContinuation(bytes, lineNumber: lineNumber)
      }
    }

    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let procedureIdent = bytes.slice(13..<19).toString()
    let routeTypeByte = bytes.count > 19 ? bytes[bytes.startIndex + 19] : ASCII.space
    let transitionIdent = bytes.slice(20..<25).toString()
    let seqNum = bytes.slice(26..<29).parseInt()

    // Fix identification
    let fixIdent = bytes.slice(29..<34).toString()
    let fixICAO = bytes.slice(34..<36).toString()
    let fixSectionCode = CoordinateParser.parseSectionCode(bytes.slice(36..<38))

    // Waypoint description (4 positions)
    let waypointDesc = CoordinateParser.parseWaypointDescription(bytes.slice(39..<43))

    // Turn direction and RNP
    let turnDirByte = bytes.count > 43 ? bytes[bytes.startIndex + 43] : ASCII.space
    let turnDirection = TurnDirection(byte: turnDirByte)
    let rnp = CoordinateParser.parseRNP(bytes.slice(44..<47))

    // Path terminator
    let pathTermStr = bytes.slice(47..<49).toString()

    // Turn direction valid indicator
    let tdvByte = bytes.count > 49 ? bytes[bytes.startIndex + 49] : ASCII.space
    let isTurnDirectionValid = tdvByte == ASCII.Y

    // Recommended navaid
    let recNavaid = bytes.slice(50..<54).toString()
    let recNavaidICAO = bytes.slice(54..<56).toString()

    // Arc radius (for RF legs) - 6 characters
    let arcRadius = CoordinateParser.parseArcRadius(bytes.slice(56..<62))

    // Theta and Rho (bearing/distance from navaid)
    let theta = CoordinateParser.parseCourse(bytes.slice(62..<66))
    let rho = CoordinateParser.parseDistance(bytes.slice(66..<70))

    // Course and distance
    let course = CoordinateParser.parseCourse(bytes.slice(70..<74))
    let distance = CoordinateParser.parseDistance(bytes.slice(74..<78))

    // Altitude description (position 82)
    let altDescByte = bytes.count > 82 ? bytes[bytes.startIndex + 82] : ASCII.space
    let altitudeDesc = AltitudeDescription(byte: altDescByte)

    // Altitudes (corrected positions)
    let alt1 = try CoordinateParser.parseAltitude(bytes.slice(84..<89), lineNumber: lineNumber)
    let alt2 = try CoordinateParser.parseAltitude(bytes.slice(89..<94), lineNumber: lineNumber)

    // Build altitude constraint from description and altitudes
    let altitudeConstraint: AltitudeConstraint?
    if let altitudeDesc {
      altitudeConstraint = AltitudeConstraint.from(
        description: altitudeDesc,
        altitude1: alt1,
        altitude2: alt2
      )
    } else {
      altitudeConstraint = nil
    }

    // Transition altitude
    let transAlt = CoordinateParser.parseTransitionAltitude(bytes.slice(94..<99))

    // Speed limit
    let speedLimit = CoordinateParser.parseSpeedLimit(bytes.slice(99..<102))

    // Speed limit description (position 102)
    let speedDescByte = bytes.count > 102 ? bytes[bytes.startIndex + 102] : ASCII.space
    let speedLimitDescription = SpeedLimitDescription(byte: speedDescByte)

    // Vertical angle (position 103-106, but may be affected by speed description position)
    let verticalAngle = CoordinateParser.parseVerticalAngle(bytes.slice(102..<106))

    // Center fix (for RF legs)
    let centerFixIdent = bytes.slice(106..<111).toString()
    let centerFixICAO = bytes.slice(112..<114).toString()

    // Check for missed approach indicator in waypoint description position 3 (position 41 in record)
    let missedApproachByte = bytes.count > 41 ? bytes[bytes.startIndex + 41] : ASCII.space
    let isMissedApproach = missedApproachByte == ASCII.M

    guard let seqNum else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: "ProcedureLeg",
        line: lineNumber
      )
    }

    let leg = ProcedureLeg(
      sequenceNumber: seqNum,
      fixId: fixIdent.isEmpty ? nil : fixIdent,
      fixICAO: fixICAO.isEmpty ? nil : fixICAO,
      fixSectionCode: fixSectionCode,
      waypointDescription: waypointDesc,
      turnDirection: turnDirection,
      rnpNM: rnp,
      pathTerminator: PathTerminator(rawValue: pathTermStr),
      isTurnDirectionValid: isTurnDirectionValid,
      recommendedNavaid: recNavaid.isEmpty ? nil : recNavaid,
      recommendedNavaidICAO: recNavaidICAO.isEmpty ? nil : recNavaidICAO,
      arcRadiusNM: arcRadius,
      thetaDeg: theta,
      rhoNM: rho,
      magneticCourseDeg: course,
      routeDistanceNMOrMinutes: distance,
      altitudeConstraint: altitudeConstraint,
      transitionAltitudeFt: transAlt,
      speedConstraint: SpeedConstraint.from(
        speedKnots: speedLimit,
        description: speedLimitDescription
      ),
      verticalAngleDeg: verticalAngle,
      centerFix: centerFixIdent.isEmpty ? nil : centerFixIdent,
      centerFixICAO: centerFixICAO.isEmpty ? nil : centerFixICAO
    )

    let record = ProcedureLegRecord(
      airportId: airportIdent,
      icaoRegion: icaoRegion,
      procedureId: procedureIdent,
      routeType: routeTypeByte == ASCII.space ? nil : Character(UnicodeScalar(routeTypeByte)),
      transitionId: transitionIdent.isEmpty ? nil : transitionIdent,
      leg: leg,
      isMissedApproach: isMissedApproach
    )

    switch type {
      case .sid: return .sidLeg(record)
      case .star: return .starLeg(record)
      case .approach: return .approachLeg(record)
      case .heliportSID: return .heliportSIDLeg(record)
      case .heliportSTAR: return .heliportSTARLeg(record)
    }
  }

  /// Parse approach continuation record containing SBAS/LPV data.
  static func parseApproachContinuation(
    _ bytes: ArraySlice<UInt8>,
    lineNumber _: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let procedureIdent = bytes.slice(13..<19).toString()
    let transitionIdent = bytes.slice(20..<25).toString()

    // Reference fix (position 30-34, 0-indexed 29-33)
    let fixIdent = bytes.slice(29..<34).toString()

    // SBAS service level (positions 41-50, 0-indexed 40-49)
    let sbasSlice = bytes.slice(40..<50)
    let sbasServiceLevel = SBASServiceLevel(string: sbasSlice.toString())

    // Required nav performance (positions 51-60, 0-indexed 50-59)
    let rnpSlice = bytes.slice(50..<60)
    let requiredNavPerformance = RequiredNavPerformance(string: rnpSlice.toString())

    // Lateral nav capability (positions 61-70, 0-indexed 60-69)
    let latNavSlice = bytes.slice(60..<70)
    let lateralNavCapability = LateralNavCapability(string: latNavSlice.toString())

    return .approachContinuation(
      ApproachContinuationRecord(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        procedureId: procedureIdent,
        transitionId: transitionIdent.isEmpty ? nil : transitionIdent,
        fixId: fixIdent.isEmpty ? nil : fixIdent,
        sbasServiceLevel: sbasServiceLevel,
        requiredNavPerformance: requiredNavPerformance,
        lateralNavCapability: lateralNavCapability
      )
    )
  }

  /// Procedure type for internal parsing dispatch.
  enum ProcedureTypeParser { case sid, star, approach, heliportSID, heliportSTAR }
}
