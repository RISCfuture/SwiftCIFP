import Foundation

// MARK: - Airspace Parsing

extension CIFPByteParser {
  static func parseControlledAirspace(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    if isAirspaceContinuation(bytes) { return .ignoredContinuation }

    let icaoRegion = bytes.slice(6..<8).toString()
    let typeByte = bytes.count > 8 ? bytes[bytes.startIndex + 8] : ASCII.space
    let center = bytes.slice(9..<14).toString()
    let classByte = bytes.count > 16 ? bytes[bytes.startIndex + 16] : ASCII.space
    let (lowerLimit, upperLimit) = try parseAirspaceLimits(bytes, lineNumber: lineNumber)

    return .controlledAirspace(
      AirspaceBoundaryRecord(
        icaoRegion: icaoRegion,
        airspaceType: typeByte == ASCII.space ? nil : Character(UnicodeScalar(typeByte)),
        centerOrDesignation: center,
        airspaceClass: ControlledAirspace.Class(byte: classByte),
        restrictiveType: nil,
        multipleCode: parseAirspaceMultipleCode(bytes),
        name: bytes.slice(93..<123).toString(),
        boundary: try parseAirspaceBoundary(
          bytes,
          recordType: "ControlledAirspace",
          lineNumber: lineNumber
        ),
        lowerLimit: lowerLimit,
        upperLimit: upperLimit
      )
    )
  }

  static func parseSpecialUseAirspace(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    if isAirspaceContinuation(bytes) { return .ignoredContinuation }

    let icaoRegion = bytes.slice(6..<8).toString()
    let typeByte = bytes.count > 8 ? bytes[bytes.startIndex + 8] : ASCII.space
    let designation = bytes.slice(9..<19).toString()
    let (lowerLimit, upperLimit) = try parseAirspaceLimits(bytes, lineNumber: lineNumber)

    return .specialUseAirspace(
      AirspaceBoundaryRecord(
        icaoRegion: icaoRegion,
        airspaceType: nil,
        centerOrDesignation: designation,
        airspaceClass: nil,
        restrictiveType: SpecialUseAirspace.Kind(byte: typeByte),
        multipleCode: parseAirspaceMultipleCode(bytes),
        name: bytes.slice(93..<123).toString(),
        boundary: try parseAirspaceBoundary(
          bytes,
          recordType: "SpecialUseAirspace",
          lineNumber: lineNumber
        ),
        lowerLimit: lowerLimit,
        upperLimit: upperLimit
      )
    )
  }

  /// Whether the record continues a primary record (continuation number at position 24).
  private static func isAirspaceContinuation(_ bytes: ArraySlice<UInt8>) -> Bool {
    let continuationByte = bytes.count > 24 ? bytes[bytes.startIndex + 24] : ASCII.space
    return ![ASCII.zero, ASCII.one, ASCII.space].contains(continuationByte)
  }

  /// Multiple code (position 19), distinguishing volumes that share a center or designation.
  private static func parseAirspaceMultipleCode(_ bytes: ArraySlice<UInt8>) -> String? {
    let multipleCodeByte = bytes.count > 19 ? bytes[bytes.startIndex + 19] : ASCII.space
    return multipleCodeByte == ASCII.space
      ? nil : String(Character(UnicodeScalar(multipleCodeByte)))
  }

  /// Boundary segment: sequence number (positions 20-23), boundary via (30-31), point
  /// (32-50), and arc origin, distance, and bearing (51-77).
  private static func parseAirspaceBoundary(
    _ bytes: ArraySlice<UInt8>,
    recordType: String,
    lineNumber: Int
  ) throws -> AirspaceBoundary {
    guard let sequenceNumber = bytes.slice(20..<24).parseInt() else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: recordType,
        line: lineNumber
      )
    }

    let viaByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let boundaryVia: BoundaryVia? = try CoordinateParser.parseCode(
      viaByte,
      field: "boundary via",
      value: bytes.slice(30..<32).toRawString(),
      lineNumber: lineNumber
    )
    let endByte = bytes.count > 31 ? bytes[bytes.startIndex + 31] : ASCII.space

    var arcOrigin: Coordinate?
    var arcDistanceNM: Double?
    var arcBearingDeg: Double?
    if boundaryVia?.hasArcDefinition ?? false {
      arcOrigin = CoordinateParser.parseCoordinate(bytes.slice(51..<70))
      arcDistanceNM = CoordinateParser.parseDistance(bytes.slice(70..<74))
      arcBearingDeg = CoordinateParser.parseCourse(bytes.slice(74..<78))
    }

    return AirspaceBoundary(
      sequenceNumber: sequenceNumber,
      boundaryVia: boundaryVia,
      isEndOfDescription: endByte == ASCII.E,
      coordinate: CoordinateParser.parseCoordinate(bytes.slice(32..<51)),
      arcOrigin: arcOrigin,
      arcBearingDeg: arcBearingDeg,
      arcDistanceNM: arcDistanceNM
    )
  }

  /// Lower (positions 81-85) and upper (87-91) limits, each followed by its unit indicator.
  private static func parseAirspaceLimits(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> (lower: Altitude?, upper: Altitude?) {
    let lowerDatumByte = bytes.count > 86 ? bytes[bytes.startIndex + 86] : ASCII.space
    let upperDatumByte = bytes.count > 92 ? bytes[bytes.startIndex + 92] : ASCII.space
    return (
      try CoordinateParser.parseAltitude(
        bytes.slice(81..<86),
        datum: Altitude.Datum(byte: lowerDatumByte) ?? .msl,
        lineNumber: lineNumber
      ),
      try CoordinateParser.parseAltitude(
        bytes.slice(87..<92),
        datum: Altitude.Datum(byte: upperDatumByte) ?? .msl,
        lineNumber: lineNumber
      )
    )
  }
}
