import Foundation

/// Parsed record result from a single line.
enum ParsedRecord: Sendable {
  case header(HeaderRecord)
  case gridMORAs([GridMORA])
  case vhfNavaid(VHFNavaid)
  case ndbNavaid(NDBNavaid)
  case enrouteWaypoint(EnrouteWaypoint)
  case airwayFix(AirwayFixRecord)
  case airport(Airport)
  case terminalWaypoint(TerminalWaypoint)
  case terminalNavaid(TerminalNavaid)
  case runway(Runway)
  case localizer(LocalizerGlideSlope)
  case pathPoint(PathPoint)
  case pathPointContinuation(PathPointContinuationRecord)
  case msa(MSARecord)
  case sidLeg(ProcedureLegRecord)
  case starLeg(ProcedureLegRecord)
  case approachLeg(ProcedureLegRecord)
  case controlledAirspace(AirspaceBoundaryRecord)
  case specialUseAirspace(AirspaceBoundaryRecord)
  case heliport(Heliport)
  case heliportWaypoint(HeliportWaypoint)
  case heliportSIDLeg(ProcedureLegRecord)
  case heliportSTARLeg(ProcedureLegRecord)
  case heliportApproachLeg(ProcedureLegRecord)
  case heliportMSA(HeliportMSARecord)
  case approachContinuation(ApproachContinuationRecord)
}

/// Intermediate header record during parsing.
struct HeaderRecord: Sendable {
  let lineNumber: Int
  let text: String
}

/// Intermediate airway fix record for aggregation.
struct AirwayFixRecord: Sendable {
  let airwayId: String
  let routeType: AirwayRouteType?
  let level: AirwayLevel?
  let fix: AirwayFix
}

/// Intermediate MSA record for aggregation.
struct MSARecord: Sendable {
  let airportId: String
  let icaoRegion: String
  let center: String
  let centerICAO: String
  let multipleCode: String?
  let radius: Double?
  let sector: MSASector
  let bearingReference: BearingReference?
}

/// Intermediate procedure leg record for aggregation.
struct ProcedureLegRecord: Sendable {
  let airportId: String
  let icaoRegion: String
  let procedureId: String
  let routeType: Character?
  let transitionId: String?
  let leg: ProcedureLeg
  let isMissedApproach: Bool
}

/// Intermediate heliport MSA record.
struct HeliportMSARecord: Sendable {
  let parentId: String
  let icaoRegion: String
  let center: String
  let radius: Double?
  let sector: MSASector
}

/// Intermediate path point continuation record for aggregation.
struct PathPointContinuationRecord: Sendable {
  let airportId: String
  let icaoRegion: String
  let approachId: String
  let runwayId: String
  let fpapEllipsoidHeightFt: Double?
  let fpapOrthometricHeightFt: Double?
  let ltpOrthometricHeightFt: Double?
  let approachTypeIdentifier: String?
  let gnssChannelNumber: Int?
  let helicopterProcedureCourse: Double?
}

/// Intermediate airspace boundary record.
struct AirspaceBoundaryRecord: Sendable {
  let icaoRegion: String
  let centerOrDesignation: String
  let airspaceClass: AirspaceClass?
  let restrictiveType: RestrictiveAirspaceType?
  let multipleCode: String?
  let name: String
  let boundary: AirspaceBoundary
  let lowerLimit: Altitude?
  let upperLimit: Altitude?
}

/// Intermediate approach continuation record for SBAS/LPV data.
struct ApproachContinuationRecord: Sendable {
  let airportId: String
  let icaoRegion: String
  let procedureId: String
  let transitionId: String?
  let fixId: String?
  let sbasServiceLevel: SBASServiceLevel?
  let requiredNavPerformance: RequiredNavPerformance?
  let lateralNavCapability: LateralNavCapability?
}

/// Parser for CIFP fixed-width records.
struct CIFPByteParser: Sendable {
  /// Standard CIFP record length.
  static let recordLength = 132

  /// Common field positions (0-indexed).
  private static let fields = (
    recordType: 0..<1,
    customerArea: 1..<4,
    sectionCode: 4..<6,
    airportIdent: 6..<10,
    icaoRegion: 10..<12,
    fileRecordNumber: 123..<128,
    cycleDate: 128..<132
  )

  /// Parse a single record line.
  static func parseRecord(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    // Header records start with 'H'
    if bytes.first == ASCII.H {
      return .header(HeaderRecord(lineNumber: lineNumber, text: bytes.toString()))
    }

    // Standard records need minimum length
    guard bytes.count >= 12 else {
      throw CIFPError.lineTooShort(expected: 12, actual: bytes.count, line: lineNumber)
    }

    // Get section code (positions 5-6, 0-indexed: 4-5)
    let sectionCode = bytes.slice(4..<6).toRawString()

    switch sectionCode {
      case "AS":
        return try parseGridMORA(bytes, lineNumber: lineNumber)
      case "D ":
        return try parseVHFNavaid(bytes, lineNumber: lineNumber)
      case "DB":
        return try parseNDBNavaid(bytes, lineNumber: lineNumber)
      case "EA":
        return try parseEnrouteWaypoint(bytes, lineNumber: lineNumber)
      case "ER":
        return try parseAirwayFix(bytes, lineNumber: lineNumber)
      case "P ":
        // Airport section - subsection at position 12 (0-indexed)
        guard bytes.count >= 13 else {
          throw CIFPError.lineTooShort(expected: 13, actual: bytes.count, line: lineNumber)
        }
        let subsection = bytes[bytes.startIndex + 12]
        switch subsection {
          case ASCII.A: return try parseAirport(bytes, lineNumber: lineNumber)
          case ASCII.C: return try parseTerminalWaypoint(bytes, lineNumber: lineNumber)
          case ASCII.D: return try parseSIDLeg(bytes, lineNumber: lineNumber)
          case ASCII.E: return try parseSTARLeg(bytes, lineNumber: lineNumber)
          case ASCII.F: return try parseApproachLeg(bytes, lineNumber: lineNumber)
          case ASCII.G: return try parseRunway(bytes, lineNumber: lineNumber)
          case ASCII.I: return try parseLocalizer(bytes, lineNumber: lineNumber)
          case ASCII.N: return try parseTerminalNavaid(bytes, lineNumber: lineNumber)
          case ASCII.P: return try parsePathPoint(bytes, lineNumber: lineNumber)
          case ASCII.S: return try parseMSA(bytes, lineNumber: lineNumber)
          default:
            throw CIFPError.unknownSubsectionCode(
              section: "P",
              subsection: Character(UnicodeScalar(subsection)),
              line: lineNumber
            )
        }
      case "PN":
        return try parseTerminalNavaid(bytes, lineNumber: lineNumber)
      case "UC":
        return try parseControlledAirspace(bytes, lineNumber: lineNumber)
      case "UR":
        return try parseSpecialUseAirspace(bytes, lineNumber: lineNumber)
      case "H ":
        // Heliport section - subsection at position 12 (0-indexed)
        guard bytes.count >= 13 else {
          throw CIFPError.lineTooShort(expected: 13, actual: bytes.count, line: lineNumber)
        }
        let heliSubsection = bytes[bytes.startIndex + 12]
        switch heliSubsection {
          case ASCII.A: return try parseHeliport(bytes, lineNumber: lineNumber)
          case ASCII.C: return try parseHeliportWaypoint(bytes, lineNumber: lineNumber)
          case ASCII.D: return try parseHeliportSIDLeg(bytes, lineNumber: lineNumber)
          case ASCII.E: return try parseHeliportSTARLeg(bytes, lineNumber: lineNumber)
          case ASCII.F: return try parseHeliportApproachLeg(bytes, lineNumber: lineNumber)
          case ASCII.S: return try parseHeliportMSA(bytes, lineNumber: lineNumber)
          default:
            throw CIFPError.unknownSubsectionCode(
              section: "H",
              subsection: Character(UnicodeScalar(heliSubsection)),
              line: lineNumber
            )
        }
      default:
        throw CIFPError.unknownSectionCode(sectionCode, line: lineNumber)
    }
  }
}
