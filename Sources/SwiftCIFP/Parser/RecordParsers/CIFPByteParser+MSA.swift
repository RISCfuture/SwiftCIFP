import Foundation

// MARK: - MSA Parsing

extension CIFPByteParser {
  static func parseMSA(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let msaCenter = bytes.slice(13..<17).toString()

    // Multiple code (ARINC column 23 = index 22)
    let multipleCodeByte = bytes.count > 22 ? bytes[bytes.startIndex + 22] : ASCII.space
    let multipleCode: String? =
      multipleCodeByte == ASCII.space ? nil : String(Character(UnicodeScalar(multipleCodeByte)))

    // Parse first sector (ARINC columns 43-53):
    // - Sector Bearing (6 chars, cols 43-48, index 42-47): first 3 = from, last 3 = to (whole degrees)
    // - Sector Altitude (3 chars, cols 49-51, index 48-50): hundreds of feet
    // - Sector Radius (2 chars, cols 52-53, index 51-52): nautical miles
    let sectorBearingFrom = bytes.slice(42..<45).parseInt().map { Double($0) }
    let sectorBearingTo = bytes.slice(45..<48).parseInt().map { Double($0) }
    let altitudeHundreds = bytes.slice(48..<51).parseInt()
    let radius = bytes.slice(51..<53).parseInt().map { Double($0) }

    // Bearing reference (ARINC column 120 = byte index 119)
    let bearingRefByte = bytes.count > 119 ? bytes[bytes.startIndex + 119] : ASCII.space
    let bearingReference: BearingReference? =
      bearingRefByte == ASCII.T ? .trueNorth : (bearingRefByte == ASCII.M ? .magnetic : nil)

    // Create sector bearings only if both values are present
    guard let sectorBearingFrom else {
      throw CIFPError.missingRequiredField(
        field: "sectorBearingFrom",
        recordType: "MSA",
        line: lineNumber
      )
    }
    guard let sectorBearingTo else {
      throw CIFPError.missingRequiredField(
        field: "sectorBearingTo",
        recordType: "MSA",
        line: lineNumber
      )
    }
    guard let altitudeHundreds else {
      throw CIFPError.missingRequiredField(
        field: "altitude",
        recordType: "MSA",
        line: lineNumber
      )
    }

    // Altitude is in hundreds of feet
    let altitudeFt = altitudeHundreds * 100

    let sectorBearings = BearingRange(from: sectorBearingFrom, to: sectorBearingTo)

    return .msa(
      MSARecord(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        center: msaCenter,
        centerICAO: icaoRegion,
        multipleCode: multipleCode,
        radius: radius,
        sector: MSASector(
          sectorBearings: sectorBearings,
          altitudeFt: altitudeFt
        ),
        bearingReference: bearingReference
      )
    )
  }

  static func parseHeliportMSA(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let heliportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let msaCenter = bytes.slice(13..<17).toString()
    let radius = CoordinateParser.parseDistance(bytes.slice(22..<26))

    // Parse sector
    let sectorBearingFrom = CoordinateParser.parseCourse(bytes.slice(42..<46))
    let sectorBearingTo = CoordinateParser.parseCourse(bytes.slice(46..<50))
    let altitude = bytes.slice(50..<55).parseInt()

    // Create sector bearings only if both values are present
    guard let sectorBearingFrom else {
      throw CIFPError.missingRequiredField(
        field: "sectorBearingFrom",
        recordType: "HeliportMSA",
        line: lineNumber
      )
    }
    guard let sectorBearingTo else {
      throw CIFPError.missingRequiredField(
        field: "sectorBearingTo",
        recordType: "HeliportMSA",
        line: lineNumber
      )
    }
    guard let altitude else {
      throw CIFPError.missingRequiredField(
        field: "altitude",
        recordType: "HeliportMSA",
        line: lineNumber
      )
    }

    let sectorBearings = BearingRange(from: sectorBearingFrom, to: sectorBearingTo)

    return .heliportMSA(
      HeliportMSARecord(
        parentId: heliportIdent,
        icaoRegion: icaoRegion,
        center: msaCenter,
        radius: radius,
        sector: MSASector(
          sectorBearings: sectorBearings,
          altitudeFt: altitude
        )
      )
    )
  }
}
