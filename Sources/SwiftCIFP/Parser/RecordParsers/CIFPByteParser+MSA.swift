import Foundation

// MARK: - MSA Parsing

extension CIFPByteParser {
  private static let sectorOffsets = stride(from: 42, to: 119, by: 11)

  static func parseMSA(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let (sectors, radius) = try parseMSASectors(bytes, recordType: "MSA", lineNumber: lineNumber)

    // Bearing reference (ARINC column 120 = byte index 119)
    let bearingRefByte = bytes.count > 119 ? bytes[bytes.startIndex + 119] : ASCII.space
    let bearingReference: BearingReference? =
      bearingRefByte == ASCII.T ? .trueNorth : (bearingRefByte == ASCII.M ? .magnetic : nil)

    return .msa(
      MSARecord(
        airportId: bytes.slice(6..<10).toString(),
        icaoRegion: bytes.slice(10..<12).toString(),
        center: bytes.slice(13..<18).toString(),
        centerICAO: bytes.slice(18..<20).toString(),
        multipleCode: parseMSAMultipleCode(bytes),
        radius: radius,
        sectors: sectors,
        bearingReference: bearingReference
      )
    )
  }

  static func parseHeliportMSA(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let (sectors, radius) = try parseMSASectors(
      bytes,
      recordType: "HeliportMSA",
      lineNumber: lineNumber
    )

    return .heliportMSA(
      HeliportMSARecord(
        parentId: bytes.slice(6..<10).toString(),
        icaoRegion: bytes.slice(10..<12).toString(),
        center: bytes.slice(13..<18).toString(),
        multipleCode: parseMSAMultipleCode(bytes),
        radius: radius,
        sectors: sectors
      )
    )
  }

  /// Multiple code (ARINC column 23 = index 22).
  private static func parseMSAMultipleCode(_ bytes: ArraySlice<UInt8>) -> String? {
    let byte = bytes.count > 22 ? bytes[bytes.startIndex + 22] : ASCII.space
    return byte == ASCII.space ? nil : String(Character(UnicodeScalar(byte)))
  }

  /// Parse the up to seven sectors of an MSA record (ARINC columns 43-119), each an 11-column
  /// group: the sector's start and end bearings in whole degrees (3 columns each), its
  /// altitude in hundreds of feet (3), and its radius in nautical miles (2).
  ///
  /// - Returns: The sectors, and the radius of the first.
  private static func parseMSASectors(
    _ bytes: ArraySlice<UInt8>,
    recordType: String,
    lineNumber: Int
  ) throws -> (sectors: [MSA.Sector], radius: Double?) {
    func required(_ value: Int?, _ field: String) throws -> Int {
      guard let value else {
        throw CIFPError.missingRequiredField(field: field, recordType: recordType, line: lineNumber)
      }
      return value
    }

    var sectors: [MSA.Sector] = []
    var radius: Double?
    for offset in sectorOffsets where !bytes.slice(offset..<(offset + 11)).isBlank() {
      let from = try required(bytes.slice(offset..<(offset + 3)).parseInt(), "sectorBearingFrom"),
        to = try required(bytes.slice((offset + 3)..<(offset + 6)).parseInt(), "sectorBearingTo"),
        hundreds = try required(bytes.slice((offset + 6)..<(offset + 9)).parseInt(), "altitude")
      sectors.append(
        MSA.Sector(
          sectorBearings: BearingRange(from: Double(from), to: Double(to)),
          altitudeFt: hundreds * 100
        )
      )
      if radius == nil {
        radius = bytes.slice((offset + 9)..<(offset + 11)).parseInt().map(Double.init)
      }
    }

    guard !sectors.isEmpty else {
      throw CIFPError.missingRequiredField(
        field: "sector",
        recordType: recordType,
        line: lineNumber
      )
    }
    return (sectors, radius)
  }
}
