import Foundation

// MARK: - Heliport Parsing

extension CIFPByteParser {
  static func parseHeliport(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let icaoIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))

    // Magnetic variation (position 51-56, format like "E0230" = East 23.0°)
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(51..<56))

    let elevation = bytes.slice(56..<61).parseInt()
    let name = bytes.slice(93..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "Heliport",
        line: lineNumber
      )
    }
    guard let elevation else {
      throw CIFPError.missingRequiredField(
        field: "elevation",
        recordType: "Heliport",
        line: lineNumber
      )
    }

    return .heliport(
      Heliport(
        id: icaoIdent,
        icaoRegion: icaoRegion,
        coordinate: coord,
        elevationFt: elevation,
        magneticVariation: magVar,
        name: name
      )
    )
  }

  static func parseHeliportWaypoint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let heliportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let identifier = bytes.slice(13..<18).toString()
    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))

    // Magnetic variation (position 74-79)
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))

    let name = bytes.slice(98..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "HeliportWaypoint",
        line: lineNumber
      )
    }

    return .heliportWaypoint(
      HeliportWaypoint(
        parentId: heliportIdent,
        icaoRegion: icaoRegion,
        identifier: identifier,
        coordinate: coord,
        magneticVariation: magVar,
        name: name.isEmpty ? nil : name
      )
    )
  }

  static func parseHeliportApproachLeg(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let heliportIdent = bytes.slice(6..<10).toString()
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

    // Altitudes
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
    let heliSpeedDescByte = bytes.count > 102 ? bytes[bytes.startIndex + 102] : ASCII.space
    let heliSpeedLimitDescription = SpeedLimitDescription(byte: heliSpeedDescByte)

    // Vertical angle
    let verticalAngle = CoordinateParser.parseVerticalAngle(bytes.slice(102..<106))

    // Center fix (for RF legs)
    let centerFixIdent = bytes.slice(106..<111).toString()
    let centerFixICAO = bytes.slice(112..<114).toString()

    // Check for missed approach indicator in waypoint description position 3 (position 41 in record)
    let heliMissedByte = bytes.count > 41 ? bytes[bytes.startIndex + 41] : ASCII.space
    let heliIsMissedApproach = heliMissedByte == ASCII.M

    guard let seqNum else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: "HeliportApproachLeg",
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
        description: heliSpeedLimitDescription
      ),
      verticalAngleDeg: verticalAngle,
      centerFix: centerFixIdent.isEmpty ? nil : centerFixIdent,
      centerFixICAO: centerFixICAO.isEmpty ? nil : centerFixICAO
    )

    return .heliportApproachLeg(
      ProcedureLegRecord(
        airportId: heliportIdent,
        icaoRegion: icaoRegion,
        procedureId: procedureIdent,
        routeType: routeTypeByte == ASCII.space ? nil : Character(UnicodeScalar(routeTypeByte)),
        transitionId: transitionIdent.isEmpty ? nil : transitionIdent,
        leg: leg,
        isMissedApproach: heliIsMissedApproach
      )
    )
  }
}
