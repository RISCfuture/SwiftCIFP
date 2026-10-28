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
          .map(ParsedRecord.approachContinuation) ?? .ignoredContinuation
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
    let waypointDesc = try CoordinateParser.parseWaypointDescription(
      bytes.slice(39..<43),
      lineNumber: lineNumber
    )

    // Turn direction and RNP
    let turnDirByte = bytes.count > 43 ? bytes[bytes.startIndex + 43] : ASCII.space
    let turnDirection = TurnDirection(byte: turnDirByte)
    let rnp = try CoordinateParser.parseRNP(bytes.slice(44..<47), lineNumber: lineNumber)

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

    // Course and length
    let course = CoordinateParser.parseCourse(bytes.slice(70..<74))
    let length = try CoordinateParser.parseLegLength(bytes.slice(74..<78), lineNumber: lineNumber)

    let altitudeConstraint = try parseAltitudeConstraint(bytes, lineNumber: lineNumber)

    // Transition altitude
    let transAlt = CoordinateParser.parseTransitionAltitude(bytes.slice(94..<99))

    let speedConstraint = try parseSpeedConstraint(bytes, lineNumber: lineNumber)

    // Vertical angle (positions 102-105)
    let verticalAngle = CoordinateParser.parseVerticalAngle(bytes.slice(102..<106))

    // Center fix (for RF legs)
    let centerFixIdent = bytes.slice(106..<111).toString()
    let centerFixICAO = bytes.slice(112..<114).toString()

    let isMissedApproach = waypointDesc?.isFirstMissedApproachLeg ?? false

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
      recommendedNavaidId: recNavaid.isEmpty ? nil : recNavaid,
      recommendedNavaidICAO: recNavaidICAO.isEmpty ? nil : recNavaidICAO,
      arcRadiusNM: arcRadius,
      thetaDeg: theta,
      rhoNM: rho,
      magneticCourseDeg: course,
      length: length,
      altitudeConstraint: altitudeConstraint,
      transitionAltitudeFt: transAlt,
      speedConstraint: speedConstraint,
      verticalAngleDeg: verticalAngle,
      centerFixId: centerFixIdent.isEmpty ? nil : centerFixIdent,
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

  /// Parse a procedure leg's altitude constraint from its description (position 82) and
  /// altitudes (positions 84-93).
  ///
  /// A blank description is the "at" restriction, so an altitude published with one is
  /// kept as an "at" constraint.
  static func parseAltitudeConstraint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> AltitudeConstraint? {
    let descriptionByte = bytes.count > 82 ? bytes[bytes.startIndex + 82] : ASCII.space
    let description: AltitudeDescription? = try CoordinateParser.parseCode(
      descriptionByte,
      field: "altitude description",
      value: String(Character(UnicodeScalar(descriptionByte))),
      lineNumber: lineNumber
    )
    return AltitudeConstraint.from(
      description: description ?? .at,
      altitude1: try CoordinateParser.parseAltitude(bytes.slice(84..<89), lineNumber: lineNumber),
      altitude2: try CoordinateParser.parseAltitude(bytes.slice(89..<94), lineNumber: lineNumber)
    )
  }

  /// Parse a procedure leg's speed constraint from its speed limit (positions 99-101) and
  /// speed limit description (position 117).
  ///
  /// A blank description is the mandatory "at" speed.
  static func parseSpeedConstraint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> SpeedConstraint? {
    let descriptionByte = bytes.count > 117 ? bytes[bytes.startIndex + 117] : ASCII.space
    let description: SpeedLimitDescription? = try CoordinateParser.parseCode(
      descriptionByte,
      field: "speed limit description",
      value: String(Character(UnicodeScalar(descriptionByte))),
      lineNumber: lineNumber
    )
    return SpeedConstraint.from(
      speedKnots: CoordinateParser.parseSpeedLimit(bytes.slice(99..<102)),
      description: description ?? .at
    )
  }

  /// Parse an approach continuation record. Only level of service records (application
  /// type "W") are decoded.
  static func parseApproachContinuation(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ApproachContinuationRecord? {
    let applicationType = bytes.count > 39 ? bytes[bytes.startIndex + 39] : ASCII.space
    guard applicationType == ASCII.W else { return nil }

    return ApproachContinuationRecord(
      airportId: bytes.slice(6..<10).toString(),
      procedureId: bytes.slice(13..<19).toString(),
      levelsOfService: try parseLevelsOfService(bytes, lineNumber: lineNumber)
    )
  }

  /// Parse a level of service record: SBAS, LNAV/VNAV, and LNAV authorizations and names
  /// (positions 40-72, ARINC 424 fields 5.275 and 5.276), then RNP AR authorizations and
  /// values (from position 88).
  private static func parseLevelsOfService(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> Approach.LevelsOfService {
    func authorization(at offset: Int) throws -> Bool? {
      let byte = bytes.count > offset ? bytes[bytes.startIndex + offset] : ASCII.space
      switch byte {
        case ASCII.A: return true
        case ASCII.N: return false
        case ASCII.space: return nil
        default:
          throw CIFPError.parseError(
            field: "level of service authorization",
            value: String(Character(UnicodeScalar(byte))),
            line: lineNumber
          )
      }
    }

    func name(_ range: Range<Int>) -> String { bytes.slice(range).toString() }

    var sbasServiceLevel: Approach.SBASServiceLevel?
    if try authorization(at: 40) == true {
      guard let level = Approach.SBASServiceLevel(rawValue: name(41..<51)) else {
        throw CIFPError.parseError(
          field: "SBAS level of service",
          value: name(41..<51),
          line: lineNumber
        )
      }
      sbasServiceLevel = level
    }

    var authorizedRNP: [Measurement<UnitLength>] = []
    for offset in stride(from: 88, to: 116, by: 4) {
      guard let isAuthorized = try authorization(at: offset) else { break }
      let rnp = try CoordinateParser.parseRNP(
        bytes.slice((offset + 1)..<(offset + 4)),
        lineNumber: lineNumber
      )
      if isAuthorized, let rnp { authorizedRNP.append(.init(value: rnp, unit: .nauticalMiles)) }
    }

    return Approach.LevelsOfService(
      sbasServiceLevel: sbasServiceLevel,
      isLNAVVNAVAuthorized: try authorization(at: 51),
      isLNAVAuthorized: try authorization(at: 62),
      authorizedRNP: authorizedRNP
    )
  }

  /// Procedure type for internal parsing dispatch.
  enum ProcedureTypeParser { case sid, star, approach, heliportSID, heliportSTAR }
}
