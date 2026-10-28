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

    // Boundary code (position 43) - for FIR/UIR boundary fixes
    let boundarySlice = bytes.slice(43..<44)
    let boundaryCode = boundarySlice.isBlank() ? nil : boundarySlice.toString()

    let routeType: Airway.RouteType? = try parseAirwayCode(
      bytes,
      at: 44,
      field: "route type",
      lineNumber: lineNumber
    )
    let level: Airway.Level? = try parseAirwayCode(
      bytes,
      at: 45,
      field: "level",
      lineNumber: lineNumber
    )
    let directionRestriction: AirwayFix.DirectionRestriction? = try parseAirwayCode(
      bytes,
      at: 46,
      field: "direction restriction",
      lineNumber: lineNumber
    )

    let outboundCourse = CoordinateParser.parseCourse(bytes.slice(70..<74))
    let distance = CoordinateParser.parseDistance(bytes.slice(74..<78))
    let inboundCourse = CoordinateParser.parseCourse(bytes.slice(78..<82))
    let minAlt = try CoordinateParser.parseAltitude(bytes.slice(83..<88), lineNumber: lineNumber)
    let alternateMinAlt = try CoordinateParser.parseAltitude(
      bytes.slice(88..<93),
      lineNumber: lineNumber
    )
    let maxAlt = try CoordinateParser.parseAltitude(bytes.slice(93..<98), lineNumber: lineNumber)

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
        routeType: routeType,
        level: level,
        fix: fix
      )
    )
  }

  /// Parse a one-character airway code, nil if blank.
  private static func parseAirwayCode<Code: ByteInitializable>(
    _ bytes: ArraySlice<UInt8>,
    at offset: Int,
    field: String,
    lineNumber: Int
  ) throws -> Code? {
    let byte = bytes.count > offset ? bytes[bytes.startIndex + offset] : ASCII.space
    return try CoordinateParser.parseCode(
      byte,
      field: field,
      value: String(Character(UnicodeScalar(byte))),
      lineNumber: lineNumber
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
