import Foundation

// MARK: - Airspace Parsing

extension CIFPByteParser {
  static func parseControlledAirspace(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let icaoRegion = bytes.slice(6..<8).toString()
    let center = bytes.slice(9..<14).toString()
    let classByte = bytes.count > 14 ? bytes[bytes.startIndex + 14] : ASCII.space
    let name = bytes.slice(93..<123).toString()
    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let seqNum = bytes.slice(24..<28).parseInt()

    // Boundary via (position 30)
    let boundaryViaByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let boundaryVia = BoundaryVia(byte: boundaryViaByte)

    // Altitudes and units
    let lowerDatumByte = bytes.count > 86 ? bytes[bytes.startIndex + 86] : ASCII.space
    let lowerDatum = Altitude.Datum(byte: lowerDatumByte) ?? .msl
    let lowerAlt = try CoordinateParser.parseAltitude(
      bytes.slice(81..<86),
      datum: lowerDatum,
      lineNumber: lineNumber
    )
    let upperDatumByte = bytes.count > 92 ? bytes[bytes.startIndex + 92] : ASCII.space
    let upperDatum = Altitude.Datum(byte: upperDatumByte) ?? .msl
    let upperAlt = try CoordinateParser.parseAltitude(
      bytes.slice(87..<92),
      datum: upperDatum,
      lineNumber: lineNumber
    )

    // Arc properties for arc boundaries (positions 51-69 for origin, 70-73 distance, 74-77 bearing)
    var arcOrigin: Coordinate?
    var arcDistanceNM: Double?
    var arcBearingDeg: Double?
    if boundaryVia == .arcClockwise || boundaryVia == .arcCounterClockwise || boundaryVia == .circle
    {
      arcOrigin = CoordinateParser.parseCoordinate(bytes.slice(51..<70))
      let distSlice = bytes.slice(70..<74)
      if !distSlice.isBlank(), let dist = distSlice.parseUInt() {
        arcDistanceNM = Double(dist) / 10.0
      }
      let bearingSlice = bytes.slice(74..<78)
      if !bearingSlice.isBlank(), let bearing = bearingSlice.parseUInt() {
        arcBearingDeg = Double(bearing) / 10.0
      }
    }

    guard let seqNum else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: "ControlledAirspace",
        line: lineNumber
      )
    }

    return .controlledAirspace(
      AirspaceBoundaryRecord(
        icaoRegion: icaoRegion,
        centerOrDesignation: center,
        airspaceClass: AirspaceClass(byte: classByte),
        restrictiveType: nil,
        multipleCode: nil,
        name: name,
        boundary: AirspaceBoundary(
          sequenceNumber: seqNum,
          boundaryVia: boundaryVia,
          coordinate: coord,
          arcOrigin: arcOrigin,
          arcBearingDeg: arcBearingDeg,
          arcDistanceNM: arcDistanceNM
        ),
        lowerLimit: lowerAlt,
        upperLimit: upperAlt
      )
    )
  }

  static func parseSpecialUseAirspace(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let icaoRegion = bytes.slice(6..<8).toString()
    let typeByte = bytes.count > 8 ? bytes[bytes.startIndex + 8] : ASCII.space
    let designation = bytes.slice(9..<19).toString()
    let name = bytes.slice(93..<123).toString()
    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let seqNum = bytes.slice(24..<28).parseInt()

    // Multiple code (position 25)
    let multipleCodeByte = bytes.count > 25 ? bytes[bytes.startIndex + 25] : ASCII.space
    let multipleCode: String? =
      multipleCodeByte == ASCII.space ? nil : String(Character(UnicodeScalar(multipleCodeByte)))

    // Boundary via (position 30)
    let boundaryViaByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let boundaryVia = BoundaryVia(byte: boundaryViaByte)

    // Altitudes and units
    let lowerDatumByte = bytes.count > 86 ? bytes[bytes.startIndex + 86] : ASCII.space
    let lowerDatum = Altitude.Datum(byte: lowerDatumByte) ?? .msl
    let lowerAlt = try CoordinateParser.parseAltitude(
      bytes.slice(81..<86),
      datum: lowerDatum,
      lineNumber: lineNumber
    )
    let upperDatumByte = bytes.count > 92 ? bytes[bytes.startIndex + 92] : ASCII.space
    let upperDatum = Altitude.Datum(byte: upperDatumByte) ?? .msl
    let upperAlt = try CoordinateParser.parseAltitude(
      bytes.slice(87..<92),
      datum: upperDatum,
      lineNumber: lineNumber
    )

    // Arc properties for arc boundaries (positions 51-69 for origin, 70-73 distance, 74-77 bearing)
    var arcOrigin: Coordinate?
    var arcDistanceNM: Double?
    var arcBearingDeg: Double?
    if boundaryVia == .arcClockwise || boundaryVia == .arcCounterClockwise || boundaryVia == .circle
    {
      arcOrigin = CoordinateParser.parseCoordinate(bytes.slice(51..<70))
      let distSlice = bytes.slice(70..<74)
      if !distSlice.isBlank(), let dist = distSlice.parseUInt() {
        arcDistanceNM = Double(dist) / 10.0
      }
      let bearingSlice = bytes.slice(74..<78)
      if !bearingSlice.isBlank(), let bearing = bearingSlice.parseUInt() {
        arcBearingDeg = Double(bearing) / 10.0
      }
    }

    guard let seqNum else {
      throw CIFPError.missingRequiredField(
        field: "sequenceNumber",
        recordType: "SpecialUseAirspace",
        line: lineNumber
      )
    }

    return .specialUseAirspace(
      AirspaceBoundaryRecord(
        icaoRegion: icaoRegion,
        centerOrDesignation: designation,
        airspaceClass: nil,
        restrictiveType: RestrictiveAirspaceType(byte: typeByte),
        multipleCode: multipleCode,
        name: name,
        boundary: AirspaceBoundary(
          sequenceNumber: seqNum,
          boundaryVia: boundaryVia,
          coordinate: coord,
          arcOrigin: arcOrigin,
          arcBearingDeg: arcBearingDeg,
          arcDistanceNM: arcDistanceNM
        ),
        lowerLimit: lowerAlt,
        upperLimit: upperAlt
      )
    )
  }
}
