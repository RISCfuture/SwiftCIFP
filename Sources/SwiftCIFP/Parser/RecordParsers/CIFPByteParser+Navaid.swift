import Foundation

// MARK: - Navaid Parsing

extension CIFPByteParser {
  static func parseVHFNavaid(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let identifier = bytes.slice(13..<17).toString()
    let icaoRegion = bytes.slice(19..<21).toString()
    let frequency = CoordinateParser.parseVHFFrequency(bytes.slice(22..<27))

    // Parse navaid class from first 2 characters of class field (ARINC 424 5.35)
    let navaidClassStr = bytes.slice(27..<29).toRawString()
    guard let navaidClass = NavaidClass(rawValue: navaidClassStr) else {
      throw CIFPError.parseError(
        field: "navaidClass",
        value: navaidClassStr,
        line: lineNumber
      )
    }

    // Navaid usage class (second character of class field, position 28)
    let usageClassByte = bytes.count > 28 ? bytes[bytes.startIndex + 28] : ASCII.space
    let usageClass = NavaidUsageClass(byte: usageClassByte)

    let vorCoord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let dmeCoord = CoordinateParser.parseCoordinate(bytes.slice(55..<74))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))
    let dmeElev = bytes.slice(79..<84).parseInt()

    // Figure of merit (position 84, single digit 0-9)
    let fomByte = bytes.count > 84 ? bytes[bytes.startIndex + 84] : ASCII.space
    let figureOfMerit: Int? =
      (fomByte >= ASCII.zero && fomByte <= ASCII.nine)
      ? Int(fomByte - ASCII.zero)
      : nil

    // ILS/DME bias (position 85-87, tenths of NM)
    let biasSlice = bytes.slice(85..<88)
    let ilsDMEBias: Double? =
      biasSlice.isBlank() ? nil : biasSlice.parseUInt().map { Double($0) / 10.0 }

    let name = bytes.slice(93..<123).toString()

    guard let frequency else {
      throw CIFPError.missingRequiredField(
        field: "frequency",
        recordType: "VHFNavaid",
        line: lineNumber
      )
    }
    guard let stationDeclination = magVar?.signedValue else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "VHFNavaid",
        line: lineNumber
      )
    }

    return .vhfNavaid(
      VHFNavaid(
        identifier: identifier,
        icaoRegion: icaoRegion,
        frequencyMHz: frequency,
        navaidClass: navaidClass,
        usageClass: usageClass,
        vorCoordinate: vorCoord,
        dmeCoordinate: dmeCoord,
        stationDeclinationDeg: stationDeclination,
        dmeElevationFt: dmeElev,
        figureOfMerit: figureOfMerit,
        ilsDMEBiasNM: ilsDMEBias,
        name: name
      )
    )
  }

  static func parseNDBNavaid(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let identifier = bytes.slice(13..<17).toString()
    let icaoRegion = bytes.slice(19..<21).toString()
    let frequency = CoordinateParser.parseNDBFrequency(bytes.slice(22..<27))

    // Parse NDB class from first 2 characters of class field
    let ndbClassStr = bytes.slice(27..<29).toRawString()
    guard let ndbClass = NDBClass(rawValue: ndbClassStr) else {
      throw CIFPError.parseError(
        field: "ndbClass",
        value: ndbClassStr,
        line: lineNumber
      )
    }

    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))
    let name = bytes.slice(93..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "NDBNavaid",
        line: lineNumber
      )
    }
    guard let frequency else {
      throw CIFPError.missingRequiredField(
        field: "frequency",
        recordType: "NDBNavaid",
        line: lineNumber
      )
    }
    guard let magVar else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "NDBNavaid",
        line: lineNumber
      )
    }

    return .ndbNavaid(
      NDBNavaid(
        identifier: identifier,
        icaoRegion: icaoRegion,
        frequencyKHz: frequency,
        ndbClass: ndbClass,
        coordinate: coord,
        magneticVariation: magVar,
        name: name
      )
    )
  }

  static func parseTerminalNavaid(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let identifier = bytes.slice(13..<17).toString()
    let frequency = CoordinateParser.parseNDBFrequency(bytes.slice(22..<27))

    // Parse navaid class from first 2 characters of class field (NDB class for terminal navaids)
    let navaidClassStr = bytes.slice(27..<29).toRawString()
    guard let navaidClass = NDBClass(rawValue: navaidClassStr) else {
      throw CIFPError.parseError(
        field: "navaidClass",
        value: navaidClassStr,
        line: lineNumber
      )
    }

    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(74..<79))
    let name = bytes.slice(93..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "TerminalNavaid",
        line: lineNumber
      )
    }
    guard let magVar else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "TerminalNavaid",
        line: lineNumber
      )
    }

    return .terminalNavaid(
      TerminalNavaid(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        identifier: identifier,
        navaidICAO: icaoRegion,
        frequencyKHz: frequency,
        navaidClass: navaidClass,
        coordinate: coord,
        magneticVariation: magVar,
        name: name
      )
    )
  }
}
