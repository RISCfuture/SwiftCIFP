import Foundation

// MARK: - Path Point Parsing

extension CIFPByteParser {
  static func parsePathPoint(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    // Check continuation number at position 26 (0-indexed)
    // Primary records have '0', '1', or blank; continuation records have '2'+
    let continuationByte = bytes.count > 26 ? bytes[bytes.startIndex + 26] : ASCII.space
    let isContinuationRecord =
      continuationByte >= ASCII.two && continuationByte <= ASCII.nine

    if isContinuationRecord {
      return try parsePathPointContinuation(bytes, lineNumber: lineNumber)
    }

    return try parsePathPointPrimary(bytes, lineNumber: lineNumber)
  }

  static func parsePathPointPrimary(
    _ bytes: ArraySlice<UInt8>,
    lineNumber _: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let approachIdent = bytes.slice(13..<19).toString()
    let runwayIdent = bytes.slice(19..<24).toString().trimmingCharacters(in: .whitespaces)

    // Path point type (position 35)
    let pathPointTypeByte = bytes.count > 35 ? bytes[bytes.startIndex + 35] : ASCII.space
    let pathPointType = PathPointType(byte: pathPointTypeByte)

    // Path points use high-precision coordinates (11 + 12 = 23 bytes) starting at position 37
    let coord = CoordinateParser.parseHighPrecisionCoordinate(bytes.slice(37..<60))

    // Parse ellipsoid height (6 chars at position 60-66, in tenths of feet, can be negative)
    let heightSlice = bytes.slice(60..<66)
    var ellipsoidHeight: Double?
    if !heightSlice.isBlank() {
      if let heightValue = heightSlice.parseInt() {
        ellipsoidHeight = Double(heightValue) / 10.0
      }
    }

    // Glidepath angle (4 chars at position 66-70, in hundredths of degrees)
    let gpaSlice = bytes.slice(66..<70)
    var glidepathAngle: Double?
    if !gpaSlice.isBlank() {
      if let gpaValue = gpaSlice.parseUInt() {
        glidepathAngle = Double(gpaValue) / 100.0
      }
    }

    // Parse FPAP coordinate (23 bytes at position 70-93)
    let fpapCoord = CoordinateParser.parseHighPrecisionCoordinate(bytes.slice(70..<93))

    // Course width (5 chars at position 93-98, in hundredths of meters)
    let courseWidthSlice = bytes.slice(93..<98)
    let courseWidthM: Double? =
      courseWidthSlice.isBlank() ? nil : courseWidthSlice.parseUInt().map { Double($0) / 100.0 }

    // Length offset (4 chars at position 98-102, in meters)
    let lengthOffsetSlice = bytes.slice(98..<102)
    let lengthOffsetM: Double? =
      lengthOffsetSlice.isBlank() ? nil : lengthOffsetSlice.parseUInt().map { Double($0) }

    // Reference path identifier (6 chars at position 117-123)
    let refPathSlice = bytes.slice(117..<123)
    let referencePathId = refPathSlice.isBlank() ? nil : refPathSlice.toString()

    return .pathPoint(
      PathPoint(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        approachId: approachIdent,
        runwayId: runwayIdent,
        pathPointType: pathPointType,
        coordinate: coord,
        ellipsoidHeightFt: ellipsoidHeight,
        glidepathAngleDeg: glidepathAngle,
        flightPathAlignmentPoint: fpapCoord,
        courseWidthM: courseWidthM,
        lengthOffsetM: lengthOffsetM,
        referencePathId: referencePathId,
        fpapEllipsoidHeightFt: nil,
        fpapOrthometricHeightFt: nil,
        ltpOrthometricHeightFt: nil,
        approachTypeIdentifier: nil,
        gnssChannelNumber: nil,
        helicopterProcedureCourse: nil
      )
    )
  }

  static func parsePathPointContinuation(
    _ bytes: ArraySlice<UInt8>,
    lineNumber _: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let approachIdent = bytes.slice(13..<19).toString()
    let runwayIdent = bytes.slice(19..<24).toString().trimmingCharacters(in: .whitespaces)

    // FPAP Ellipsoid Height (columns 29-34, index 28-33, 6 chars, in tenths of feet)
    let fpapEllipsoidSlice = bytes.slice(28..<34)
    let fpapEllipsoidHeightFt: Double? =
      fpapEllipsoidSlice.isBlank() ? nil : fpapEllipsoidSlice.parseInt().map { Double($0) / 10.0 }

    // FPAP Orthometric Height (columns 35-40, index 34-39, 6 chars, in tenths of feet)
    let fpapOrthometricSlice = bytes.slice(34..<40)
    let fpapOrthometricHeightFt: Double? =
      fpapOrthometricSlice.isBlank()
      ? nil : fpapOrthometricSlice.parseInt().map { Double($0) / 10.0 }

    // LTP Orthometric Height (columns 41-46, index 40-45, 6 chars, in tenths of feet)
    let ltpOrthometricSlice = bytes.slice(40..<46)
    let ltpOrthometricHeightFt: Double? =
      ltpOrthometricSlice.isBlank() ? nil : ltpOrthometricSlice.parseInt().map { Double($0) / 10.0 }

    // Approach Type Identifier (columns 47-56, index 46-55, 10 chars)
    let approachTypeSlice = bytes.slice(46..<56)
    let approachTypeIdentifier = approachTypeSlice.isBlank() ? nil : approachTypeSlice.toString()

    // GNSS Channel Number (columns 57-61, index 56-60, 5 chars)
    let gnssChannelSlice = bytes.slice(56..<61)
    let gnssChannelNumber = gnssChannelSlice.isBlank() ? nil : gnssChannelSlice.parseInt()

    // Helicopter Procedure Course (columns 72-74, index 71-73, 3 chars, whole degrees)
    let heliCourseSlice = bytes.slice(71..<74)
    let helicopterProcedureCourse: Double? =
      heliCourseSlice.isBlank() ? nil : heliCourseSlice.parseInt().map { Double($0) }

    return .pathPointContinuation(
      PathPointContinuationRecord(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        approachId: approachIdent,
        runwayId: runwayIdent,
        fpapEllipsoidHeightFt: fpapEllipsoidHeightFt,
        fpapOrthometricHeightFt: fpapOrthometricHeightFt,
        ltpOrthometricHeightFt: ltpOrthometricHeightFt,
        approachTypeIdentifier: approachTypeIdentifier,
        gnssChannelNumber: gnssChannelNumber,
        helicopterProcedureCourse: helicopterProcedureCourse
      )
    )
  }
}
