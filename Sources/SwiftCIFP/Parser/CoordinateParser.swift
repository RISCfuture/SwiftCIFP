import Foundation

/// Parser for CIFP coordinate formats.
///
/// CIFP uses the HDDDMMSSSS format:
/// - H: Hemisphere (N/S for latitude, E/W for longitude)
/// - DD or DDD: Degrees (2 digits for lat, 3 for lon)
/// - MM: Minutes (2 digits)
/// - SSSS: Seconds × 100 (4 digits, hundredths of seconds)
enum CoordinateParser {

  /// Parse a latitude from CIFP format (NDDMMSSSS or SDDMMSSSS).
  ///
  /// - Parameter bytes: 9-byte sequence containing the latitude.
  /// - Returns: Latitude in decimal degrees, or nil if invalid.
  static func parseLatitude<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 9 else { return nil }

    let hemisphere = bytes[bytes.startIndex]
    guard hemisphere == ASCII.N || hemisphere == ASCII.S else { return nil }

    let degSlice = bytes.slice(1..<3)
    let minSlice = bytes.slice(3..<5)
    let secSlice = bytes.slice(5..<9)

    guard let degrees = degSlice.parseUInt(),
      let minutes = minSlice.parseUInt(),
      let secondsHundredths = secSlice.parseUInt()
    else {
      return nil
    }

    let seconds = Double(secondsHundredths) / 100.0
    let decimal = Double(degrees) + Double(minutes) / 60.0 + seconds / 3600.0

    return hemisphere == ASCII.N ? decimal : -decimal
  }

  /// Parse a longitude from CIFP format (EDDDMMSSSS or WDDDMMSSSS).
  ///
  /// - Parameter bytes: 10-byte sequence containing the longitude.
  /// - Returns: Longitude in decimal degrees, or nil if invalid.
  static func parseLongitude<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 10 else { return nil }

    let hemisphere = bytes[bytes.startIndex]
    guard hemisphere == ASCII.E || hemisphere == ASCII.W else { return nil }

    let degSlice = bytes.slice(1..<4)
    let minSlice = bytes.slice(4..<6)
    let secSlice = bytes.slice(6..<10)

    guard let degrees = degSlice.parseUInt(),
      let minutes = minSlice.parseUInt(),
      let secondsHundredths = secSlice.parseUInt()
    else {
      return nil
    }

    let seconds = Double(secondsHundredths) / 100.0
    let decimal = Double(degrees) + Double(minutes) / 60.0 + seconds / 3600.0

    return hemisphere == ASCII.E ? decimal : -decimal
  }

  /// Parse a full coordinate (latitude + longitude).
  ///
  /// - Parameter bytes: 19-byte sequence containing lat (9) + lon (10).
  /// - Returns: Coordinate, or nil if invalid.
  static func parseCoordinate<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Coordinate? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 19 else { return nil }

    guard let lat = parseLatitude(bytes.slice(0..<9)),
      let lon = parseLongitude(bytes.slice(9..<19))
    else {
      return nil
    }

    return Coordinate(latitudeDeg: lat, longitudeDeg: lon)
  }

  /// Parse a high-precision latitude (NDDMMSSSSSS or SDDMMSSSSSS).
  ///
  /// Used for path points which have ten-thousandths of arcseconds precision.
  /// - Parameter bytes: 11-byte sequence containing the latitude.
  /// - Returns: Latitude in decimal degrees, or nil if invalid.
  static func parseHighPrecisionLatitude<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 11 else { return nil }

    let hemisphere = bytes[bytes.startIndex]
    guard hemisphere == ASCII.N || hemisphere == ASCII.S else { return nil }

    let degSlice = bytes.slice(1..<3)
    let minSlice = bytes.slice(3..<5)
    let secSlice = bytes.slice(5..<11)

    guard let degrees = degSlice.parseUInt(),
      let minutes = minSlice.parseUInt(),
      let secondsTenThousandths = secSlice.parseUInt()
    else {
      return nil
    }

    let seconds = Double(secondsTenThousandths) / 10000.0
    let decimal = Double(degrees) + Double(minutes) / 60.0 + seconds / 3600.0

    return hemisphere == ASCII.N ? decimal : -decimal
  }

  /// Parse a high-precision longitude (EDDDMMSSSSSS or WDDDMMSSSSSS).
  ///
  /// Used for path points which have ten-thousandths of arcseconds precision.
  /// - Parameter bytes: 12-byte sequence containing the longitude.
  /// - Returns: Longitude in decimal degrees, or nil if invalid.
  static func parseHighPrecisionLongitude<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 12 else { return nil }

    let hemisphere = bytes[bytes.startIndex]
    guard hemisphere == ASCII.E || hemisphere == ASCII.W else { return nil }

    let degSlice = bytes.slice(1..<4)
    let minSlice = bytes.slice(4..<6)
    let secSlice = bytes.slice(6..<12)

    guard let degrees = degSlice.parseUInt(),
      let minutes = minSlice.parseUInt(),
      let secondsTenThousandths = secSlice.parseUInt()
    else {
      return nil
    }

    let seconds = Double(secondsTenThousandths) / 10000.0
    let decimal = Double(degrees) + Double(minutes) / 60.0 + seconds / 3600.0

    return hemisphere == ASCII.E ? decimal : -decimal
  }

  /// Parse a high-precision coordinate (latitude + longitude).
  ///
  /// Used for path points which have ten-thousandths of arcseconds precision.
  /// - Parameter bytes: 23-byte sequence containing lat (11) + lon (12).
  /// - Returns: Coordinate, or nil if invalid.
  static func parseHighPrecisionCoordinate<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Coordinate? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 23 else { return nil }

    guard let lat = parseHighPrecisionLatitude(bytes.slice(0..<11)),
      let lon = parseHighPrecisionLongitude(bytes.slice(11..<23))
    else {
      return nil
    }

    return Coordinate(latitudeDeg: lat, longitudeDeg: lon)
  }

  /// Parse a magnetic variation (DNNNN format).
  ///
  /// - Parameter bytes: 5-byte sequence (direction + 4-digit value).
  /// - Returns: MagneticVariation, or nil if blank/invalid.
  static func parseMagneticVariation<T: RandomAccessCollection>(
    _ bytes: T
  ) -> MagneticVariation? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 5, !bytes.isBlank() else { return nil }

    let dirByte = bytes[bytes.startIndex]
    guard let dir = MagVarDirection(byte: dirByte) else { return nil }

    let valueSlice = bytes.slice(1..<5)
    guard let value = valueSlice.parseUInt() else { return nil }

    // Value is in tenths of degrees
    return MagneticVariation(direction: dir, degrees: Double(value) / 10.0)
  }

  /// Parse an altitude value.
  ///
  /// - Parameters:
  ///   - bytes: 5-byte altitude field.
  ///   - datum: The altitude datum (MSL or AGL) for feet-based altitudes. Defaults to MSL.
  ///   - lineNumber: Line number for error reporting.
  /// - Returns: Altitude enum value, or nil if the field is blank.
  /// - Throws: `CIFPError.parseError` if the altitude value cannot be parsed.
  static func parseAltitude<T: RandomAccessCollection>(
    _ bytes: T,
    datum: Altitude.Datum = .msl,
    lineNumber: Int = 0
  ) throws -> Altitude? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 5 else {
      throw CIFPError.parseError(field: "altitude", value: "(too short)", line: lineNumber)
    }

    if bytes.isBlank() {
      return nil
    }

    let str = bytes.toString()

    // Check for flight level (FLnnn)
    if str.hasPrefix("FL") {
      if let fl = Int(str.dropFirst(2)) {
        return .flightLevel(fl)
      }
      throw CIFPError.parseError(field: "altitude", value: str, line: lineNumber)
    }

    // Check for ground
    if str.hasPrefix("GND") || str == "SFC" {
      return .ground
    }

    // Check for unknown altitude
    if str == "UNKNN" {
      return .unknown
    }

    // Check for unlimited altitude
    if str == "UNLTD" {
      return .unlimited
    }

    // Otherwise parse as feet with the specified datum
    if let feet = Int(str) {
      return .feet(feet, datum)
    }

    throw CIFPError.parseError(field: "altitude", value: str, line: lineNumber)
  }

  /// Parse a frequency value (VHF navaid format).
  ///
  /// - Parameter bytes: 5-byte frequency field.
  /// - Returns: Frequency in MHz, or nil if invalid.
  static func parseVHFFrequency<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard let raw = bytes.parseUInt() else { return nil }
    // VHF frequency is stored as xxxxx = xxx.xx MHz
    return Double(raw) / 100.0
  }

  /// Parse an NDB frequency value.
  ///
  /// - Parameter bytes: Frequency field (value in tenths of kHz).
  /// - Returns: Frequency in kHz, or nil if invalid.
  static func parseNDBFrequency<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard let raw = bytes.parseUInt() else { return nil }
    // NDB frequency is stored as tenths of kHz (e.g., 02770 = 277.0 kHz)
    return Double(raw) / 10.0
  }

  /// Parse a course value (magnetic bearing × 10).
  ///
  /// - Parameter bytes: 4-byte course field.
  /// - Returns: Course in degrees, or nil if blank.
  static func parseCourse<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank(), let raw = bytes.parseUInt() else { return nil }
    return Double(raw) / 10.0
  }

  /// Parse a distance value (nm × 10).
  ///
  /// - Parameter bytes: 4-byte distance field.
  /// - Returns: Distance in nautical miles, or nil if blank.
  static func parseDistance<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank(), let raw = bytes.parseUInt() else { return nil }
    return Double(raw) / 10.0
  }

  /// Parse a runway gradient value.
  ///
  /// ARINC 424 runway gradient is stored as a 5-character field:
  /// - Format: SNNNN where S is sign (+/-) and NNNN is gradient × 1000
  /// - Or: NNNNS where NNNN is value and S is sign
  /// - Positive = uphill landing direction
  ///
  /// - Parameter bytes: 5-byte gradient field.
  /// - Returns: Gradient in percent, or nil if blank/invalid.
  static func parseGradient<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 5, !bytes.isBlank() else { return nil }

    let str = bytes.toString()

    // Check for sign at start
    if str.hasPrefix("+") || str.hasPrefix("-") {
      let sign: Double = str.hasPrefix("-") ? -1 : 1
      if let value = Int(str.dropFirst()) {
        return sign * Double(value) / 1000.0
      }
    }

    // Check for sign at end
    if str.hasSuffix("+") || str.hasSuffix("-") {
      let sign: Double = str.hasSuffix("-") ? -1 : 1
      if let value = Int(str.dropLast()) {
        return sign * Double(value) / 1000.0
      }
    }

    // Try parsing as unsigned
    if let value = Int(str) {
      return Double(value) / 1000.0
    }

    return nil
  }

  /// Parse an RNP (Required Navigation Performance) value.
  ///
  /// RNP is stored as a 3-digit value in tenths of NM (e.g., "010" = 1.0 NM).
  /// - Parameter bytes: 3-byte RNP field.
  /// - Returns: RNP in nautical miles, or nil if blank.
  static func parseRNP<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank(), let raw = bytes.parseUInt() else { return nil }
    return Double(raw) / 10.0
  }

  /// Parse an arc radius value for RF legs.
  ///
  /// Arc radius is stored as a 6-digit value in thousandths of NM (e.g., "002920" = 2.92 NM).
  /// - Parameter bytes: 6-byte arc radius field.
  /// - Returns: Arc radius in nautical miles, or nil if blank.
  static func parseArcRadius<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank(), let raw = bytes.parseUInt() else { return nil }
    return Double(raw) / 1000.0
  }

  /// Parse a vertical angle value.
  ///
  /// Vertical angle is stored as a 4-character field in hundredths of degrees.
  /// Can be negative (e.g., "-300" = -3.00°).
  /// - Parameter bytes: 4-byte vertical angle field.
  /// - Returns: Vertical angle in degrees, or nil if blank.
  static func parseVerticalAngle<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Double? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank(), let raw = bytes.parseInt() else { return nil }
    return Double(raw) / 100.0
  }

  /// Parse a speed limit value.
  ///
  /// - Parameter bytes: 3-byte speed limit field.
  /// - Returns: Speed limit in knots, or nil if blank.
  static func parseSpeedLimit<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Int? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank() else { return nil }
    return bytes.parseInt()
  }

  /// Parse a transition altitude value.
  ///
  /// - Parameter bytes: 5-byte transition altitude field.
  /// - Returns: Transition altitude in feet, or nil if blank.
  static func parseTransitionAltitude<T: RandomAccessCollection>(
    _ bytes: T
  ) -> Int? where T.Element == UInt8, T.Index == Int {
    guard !bytes.isBlank() else { return nil }
    return bytes.parseInt()
  }

  /// Parse a waypoint description code (4 positions).
  ///
  /// - Parameter bytes: 4-byte waypoint description field.
  /// - Returns: WaypointDescriptionCode, or nil if all positions are blank/unknown.
  static func parseWaypointDescription<T: RandomAccessCollection>(
    _ bytes: T
  ) -> WaypointDescriptionCode? where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= 4 else { return nil }

    let pos1 = WaypointDescPosition1(byte: bytes[bytes.startIndex])
    let pos2 = WaypointDescPosition2(byte: bytes[bytes.startIndex + 1])
    let pos3 = WaypointDescPosition3(byte: bytes[bytes.startIndex + 2])
    let pos4 = WaypointDescPosition4(byte: bytes[bytes.startIndex + 3])

    // Return nil if all positions are blank
    if pos1 == nil && pos2 == nil && pos3 == nil && pos4 == nil {
      return nil
    }

    return WaypointDescriptionCode(
      position1: pos1,
      position2: pos2,
      position3: pos3,
      position4: pos4
    )
  }

  /// Parse a section code from a 2-byte field.
  ///
  /// - Parameter bytes: 2-byte section code field.
  /// - Returns: SectionCode enum value, or nil if not recognized.
  static func parseSectionCode<T: RandomAccessCollection>(
    _ bytes: T
  ) -> SectionCode? where T.Element == UInt8, T.Index == Int {
    let rawString = bytes.toRawString()
    return SectionCode(rawValue: rawString)
  }
}
