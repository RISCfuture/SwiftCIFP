import Foundation

// MARK: - Waypoint Parsing

extension CIFPByteParser {
  static func parseEnrouteWaypoint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let identifier = bytes.slice(13..<18).toString()
    let icaoRegion = bytes.slice(19..<21).toString()
    let waypointType = try CoordinateParser.parseWaypointType(
      bytes.slice(26..<29),
      function: WaypointType.Function.init(enrouteCode:),
      lineNumber: lineNumber
    )

    // Waypoint usage (positions 29-30)
    let rnavByte = bytes.count > 29 ? bytes[bytes.startIndex + 29] : ASCII.space
    let usageByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    guard let usage = EnrouteWaypoint.Usage(byte: usageByte) else {
      throw CIFPError.parseError(
        field: "waypoint usage",
        value: String(Character(UnicodeScalar(usageByte))),
        line: lineNumber
      )
    }

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
    guard let waypointType else {
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
        usage: usage,
        isRNAV: rnavByte == ASCII.R,
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

    let outboundCourse = try CoordinateParser.parseReferencedCourse(
      bytes.slice(70..<74),
      lineNumber: lineNumber
    )
    let distance = CoordinateParser.parseDistance(bytes.slice(74..<78))
    let inboundCourse = try CoordinateParser.parseReferencedCourse(
      bytes.slice(78..<82),
      lineNumber: lineNumber
    )
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
      outboundCourse: outboundCourse,
      distanceNM: distance,
      inboundCourse: inboundCourse,
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

    // Waypoint type (positions 26-28)
    let waypointType = try CoordinateParser.parseWaypointType(
      bytes.slice(26..<29),
      function: WaypointType.Function.init(terminalCode:),
      lineNumber: lineNumber
    )

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
        coordinate: coord,
        magneticVariation: magVar,
        name: name
      )
    )
  }
}
