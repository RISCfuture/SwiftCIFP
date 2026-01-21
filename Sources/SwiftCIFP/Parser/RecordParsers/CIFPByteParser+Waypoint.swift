import Foundation

// MARK: - Waypoint Parsing

extension CIFPByteParser {
  static func parseEnrouteWaypoint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let identifier = bytes.slice(13..<18).toString()
    let icaoRegion = bytes.slice(19..<21).toString()
    let waypointTypeByte = bytes.count > 26 ? bytes[bytes.startIndex + 26] : ASCII.space

    // Waypoint usage class (position 30)
    let usageClassByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let usageClass = WaypointUsage(byte: usageClassByte)

    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))
    let name = bytes.slice(98..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "EnrouteWaypoint",
        line: lineNumber
      )
    }
    guard let waypointType = WaypointType(byte: waypointTypeByte) else {
      throw CIFPError.missingRequiredField(
        field: "waypointType",
        recordType: "EnrouteWaypoint",
        line: lineNumber
      )
    }
    guard let magVar else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "EnrouteWaypoint",
        line: lineNumber
      )
    }

    return .enrouteWaypoint(
      EnrouteWaypoint(
        identifier: identifier,
        icaoRegion: icaoRegion,
        waypointType: waypointType,
        usageClass: usageClass,
        coordinate: coord,
        magneticVariation: magVar,
        name: name
      )
    )
  }

  static func parseAirwayFix(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let routeIdent = bytes.slice(13..<18).toString()
    let seqNum = bytes.slice(25..<29).parseInt()
    let fixIdent = bytes.slice(29..<34).toString()
    let fixICAO = bytes.slice(34..<36).toString()

    // Fix section code (position 36-38)
    let fixSectionCode = CoordinateParser.parseSectionCode(bytes.slice(36..<38))

    // Boundary code (position 41-42) - for FIR/UIR boundary fixes
    let boundarySlice = bytes.slice(41..<43)
    let boundaryCode = boundarySlice.isBlank() ? nil : boundarySlice.toString()

    // Direction restriction (position 43)
    let dirRestrByte = bytes.count > 43 ? bytes[bytes.startIndex + 43] : ASCII.space
    let directionRestriction = DirectionRestriction(byte: dirRestrByte)

    let outboundCourse = CoordinateParser.parseCourse(bytes.slice(70..<74))
    let inboundCourse = CoordinateParser.parseCourse(bytes.slice(74..<78))
    let distance = CoordinateParser.parseDistance(bytes.slice(78..<82))
    let minAlt = try CoordinateParser.parseAltitude(bytes.slice(83..<88), lineNumber: lineNumber)
    let alternateMinAlt = try CoordinateParser.parseAltitude(
      bytes.slice(88..<93),
      lineNumber: lineNumber
    )
    let maxAlt = try CoordinateParser.parseAltitude(bytes.slice(93..<98), lineNumber: lineNumber)

    let routeTypeByte = bytes.count > 19 ? bytes[bytes.startIndex + 19] : ASCII.space
    let levelByte = bytes.count > 20 ? bytes[bytes.startIndex + 20] : ASCII.space

    guard let seqNum else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: "AirwayFix",
        line: lineNumber
      )
    }

    let fix = AirwayFix(
      sequenceNumber: seqNum,
      fixId: fixIdent,
      fixICAO: fixICAO,
      fixSectionCode: fixSectionCode,
      boundaryCode: boundaryCode,
      directionRestriction: directionRestriction,
      outboundCourseDeg: outboundCourse,
      distanceNM: distance,
      inboundCourseDeg: inboundCourse,
      minimumAltitude: minAlt,
      alternateMinimumAltitude: alternateMinAlt,
      maximumAltitude: maxAlt
    )

    return .airwayFix(
      AirwayFixRecord(
        airwayId: routeIdent,
        routeType: AirwayRouteType(byte: routeTypeByte),
        level: AirwayLevel(byte: levelByte),
        fix: fix
      )
    )
  }

  static func parseTerminalWaypoint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let identifier = bytes.slice(13..<18).toString()

    // Waypoint type (position 26)
    let waypointTypeByte = bytes.count > 26 ? bytes[bytes.startIndex + 26] : ASCII.space
    let waypointType = WaypointType(byte: waypointTypeByte)

    // Waypoint usage (position 30)
    let waypointUsageByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let waypointUsage = WaypointUsage(byte: waypointUsageByte)

    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))
    let name = bytes.slice(98..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "TerminalWaypoint",
        line: lineNumber
      )
    }
    guard let magVar else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "TerminalWaypoint",
        line: lineNumber
      )
    }

    return .terminalWaypoint(
      TerminalWaypoint(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        identifier: identifier,
        waypointICAO: icaoRegion,
        waypointType: waypointType,
        waypointUsage: waypointUsage,
        coordinate: coord,
        magneticVariation: magVar,
        name: name
      )
    )
  }
}
