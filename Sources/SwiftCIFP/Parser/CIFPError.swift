import Foundation

/// Reasons why record aggregation can fail during CIFP building.
public enum AggregationErrorReason: Sendable {
  /// The airway is missing its route type or level metadata.
  case missingAirwayMetadata

  /// The MSA record is missing its radius.
  case missingMSARadius

  /// The procedure has an invalid route type character.
  case invalidRouteType(Character)

  /// The procedure is missing its route type.
  case missingRouteType

  /// The approach has an invalid approach type character.
  case invalidApproachType(Character)

  /// The approach is missing its approach type.
  case missingApproachType

  /// The airspace has no boundary records.
  case noBoundaryRecords

  /// The special use airspace is missing its restrictive type.
  case missingRestrictiveType

  /// The procedure has no leg records.
  case noLegRecords
}

/// Specific format errors that can occur during CIFP parsing.
public enum CIFPFormatError: Sendable {
  /// The header records were not found.
  case missingHeader

  /// The cycle date could not be parsed from the header.
  case invalidCycleDate

  /// An invalid coordinate format was encountered.
  case invalidCoordinate(String)

  /// An invalid altitude format was encountered.
  case invalidAltitude(String)

  /// The latitude direction is not N or S.
  case invalidLatitudeDirection(Character)

  /// The longitude direction is not E or W.
  case invalidLongitudeDirection(Character)
}

/// Errors that can occur during CIFP parsing.
public enum CIFPError: Error, LocalizedError, Sendable {
  /// The file data is not valid ASCII encoding.
  case invalidEncoding

  /// The file format is invalid.
  case invalidFormat(CIFPFormatError)

  /// A field could not be parsed.
  case parseError(field: String, value: String, line: Int)

  /// The file was not found.
  case fileNotFound(URL)

  /// An error occurred while reading the stream.
  case streamError(Error)

  /// The line is too short to parse.
  case lineTooShort(expected: Int, actual: Int, line: Int)

  /// An unknown section code was encountered.
  case unknownSectionCode(String, line: Int)

  /// An unknown record type was encountered.
  case unknownRecordType(Character, line: Int)

  /// A required field was missing.
  case missingRequiredField(field: String, recordType: String, line: Int)

  /// An unknown subsection code was encountered.
  case unknownSubsectionCode(section: String, subsection: Character, line: Int)

  /// Record aggregation failed during building.
  case aggregationError(recordType: String, identifier: String, reason: AggregationErrorReason)

  public var errorDescription: String? {
    switch self {
      case .invalidEncoding:
        #if canImport(Darwin)
          String(localized: "File encoding was invalid.", bundle: .module)
        #else
          "File encoding was invalid."
        #endif
      case .invalidFormat:
        #if canImport(Darwin)
          String(localized: "CIFP data format was invalid.", bundle: .module)
        #else
          "CIFP data format was invalid."
        #endif
      case .parseError:
        #if canImport(Darwin)
          String(localized: "CIFP data could not be parsed.", bundle: .module)
        #else
          "CIFP data could not be parsed."
        #endif
      case .fileNotFound:
        #if canImport(Darwin)
          String(localized: "CIFP file was not found.", bundle: .module)
        #else
          "CIFP file was not found."
        #endif
      case .streamError:
        #if canImport(Darwin)
          String(localized: "A stream error occurred.", bundle: .module)
        #else
          "A stream error occurred."
        #endif
      case .lineTooShort:
        #if canImport(Darwin)
          String(localized: "Line was too short.", bundle: .module)
        #else
          "Line was too short."
        #endif
      case .unknownSectionCode:
        #if canImport(Darwin)
          String(localized: "Unknown section code.", bundle: .module)
        #else
          "Unknown section code."
        #endif
      case .unknownRecordType:
        #if canImport(Darwin)
          String(localized: "Unknown record type.", bundle: .module)
        #else
          "Unknown record type."
        #endif
      case .missingRequiredField:
        #if canImport(Darwin)
          String(localized: "Required field was missing.", bundle: .module)
        #else
          "Required field was missing."
        #endif
      case .unknownSubsectionCode:
        #if canImport(Darwin)
          String(localized: "Unknown subsection code.", bundle: .module)
        #else
          "Unknown subsection code."
        #endif
      case .aggregationError:
        #if canImport(Darwin)
          String(localized: "Record aggregation failed.", bundle: .module)
        #else
          "Record aggregation failed."
        #endif
    }
  }

  public var failureReason: String? {
    switch self {
      case .invalidEncoding:
        #if canImport(Darwin)
          return String(localized: "The file is not valid ASCII encoding.", bundle: .module)
        #else
          return "The file is not valid ASCII encoding."
        #endif
      case .invalidFormat(let error):
        return switch error {
          case .missingHeader:
            #if canImport(Darwin)
              String(
                localized: "The CIFP file does not contain valid header records.",
                bundle: .module
              )
            #else
              "The CIFP file does not contain valid header records."
            #endif
          case .invalidCycleDate:
            #if canImport(Darwin)
              String(localized: "The cycle date in the header could not be parsed.", bundle: .module)
            #else
              "The cycle date in the header could not be parsed."
            #endif
          case .invalidCoordinate(let value):
            #if canImport(Darwin)
              String(
                localized: "Coordinate value “\(value)” is not in valid HDDDMMSSSS format.",
                bundle: .module
              )
            #else
              "Coordinate value “\(value)” is not in valid HDDDMMSSSS format."
            #endif
          case .invalidAltitude(let value):
            #if canImport(Darwin)
              String(localized: "Altitude value “\(value)” could not be parsed.", bundle: .module)
            #else
              "Altitude value “\(value)” could not be parsed."
            #endif
          case .invalidLatitudeDirection(let char):
            #if canImport(Darwin)
              String(
                localized: "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”.",
                bundle: .module
              )
            #else
              "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”."
            #endif
          case .invalidLongitudeDirection(let char):
            #if canImport(Darwin)
              String(
                localized: "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”.",
                bundle: .module
              )
            #else
              "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”."
            #endif
        }
      case let .parseError(field, value, line):
        #if canImport(Darwin)
          return String(
            localized: "Failed to parse \(field) “\(value)” at line \(line, format: .number).",
            bundle: .module
          )
        #else
          return "Failed to parse \(field) “\(value)” at line \(line)."
        #endif
      case .fileNotFound(let url):
        #if canImport(Darwin)
          return String(localized: "The file at “\(url.path)” could not be found.", bundle: .module)
        #else
          return "The file at “\(url.path)” could not be found."
        #endif
      case .streamError(let error):
        #if canImport(Darwin)
          return String(
            localized: "An error occurred while reading: \(error.localizedDescription)",
            bundle: .module
          )
        #else
          return "An error occurred while reading: \(error.localizedDescription)"
        #endif
      case let .lineTooShort(expected, actual, line):
        #if canImport(Darwin)
          return String(
            localized:
              "Line \(line, format: .number) has \(actual, format: .number) characters but \(expected, format: .number) are required.",
            bundle: .module
          )
        #else
          return "Line \(line) has \(actual) characters but \(expected) are required."
        #endif
      case let .unknownSectionCode(code, line):
        #if canImport(Darwin)
          return String(
            localized: "Unknown section code “\(code)” at line \(line, format: .number).",
            bundle: .module
          )
        #else
          return "Unknown section code “\(code)” at line \(line)."
        #endif
      case let .unknownRecordType(type, line):
        #if canImport(Darwin)
          return String(
            localized: "Unknown record type “\(String(type))” at line \(line, format: .number).",
            bundle: .module
          )
        #else
          return "Unknown record type “\(String(type))” at line \(line)."
        #endif
      case let .missingRequiredField(field, recordType, line):
        #if canImport(Darwin)
          return String(
            localized:
              "Field “\(field)” is required for \(recordType) at line \(line, format: .number).",
            bundle: .module
          )
        #else
          return "Field “\(field)” is required for \(recordType) at line \(line)."
        #endif
      case let .unknownSubsectionCode(section, subsection, line):
        #if canImport(Darwin)
          return String(
            localized:
              "Unknown subsection “\(String(subsection))” in section “\(section)” at line \(line, format: .number).",
            bundle: .module
          )
        #else
          return "Unknown subsection “\(String(subsection))” in section “\(section)” at line \(line)."
        #endif
      case let .aggregationError(recordType, identifier, reason):
        let reasonString: String =
          switch reason {
            case .missingAirwayMetadata:
              #if canImport(Darwin)
                String(localized: "missing route type or level", bundle: .module)
              #else
                "missing route type or level"
              #endif
            case .missingMSARadius:
              #if canImport(Darwin)
                String(localized: "missing radius", bundle: .module)
              #else
                "missing radius"
              #endif
            case .invalidRouteType(let char):
              #if canImport(Darwin)
                String(localized: "invalid route type “\(String(char))”", bundle: .module)
              #else
                "invalid route type “\(String(char))”"
              #endif
            case .missingRouteType:
              #if canImport(Darwin)
                String(localized: "missing route type", bundle: .module)
              #else
                "missing route type"
              #endif
            case .invalidApproachType(let char):
              #if canImport(Darwin)
                String(localized: "invalid approach type “\(String(char))”", bundle: .module)
              #else
                "invalid approach type “\(String(char))”"
              #endif
            case .missingApproachType:
              #if canImport(Darwin)
                String(localized: "missing approach type", bundle: .module)
              #else
                "missing approach type"
              #endif
            case .noBoundaryRecords:
              #if canImport(Darwin)
                String(localized: "no boundary records", bundle: .module)
              #else
                "no boundary records"
              #endif
            case .missingRestrictiveType:
              #if canImport(Darwin)
                String(localized: "missing restrictive type", bundle: .module)
              #else
                "missing restrictive type"
              #endif
            case .noLegRecords:
              #if canImport(Darwin)
                String(localized: "no leg records", bundle: .module)
              #else
                "no leg records"
              #endif
          }
        #if canImport(Darwin)
          return String(
            localized: "\(recordType) “\(identifier)” could not be built: \(reasonString).",
            bundle: .module
          )
        #else
          return "\(recordType) “\(identifier)” could not be built: \(reasonString)."
        #endif
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidEncoding, .invalidFormat:
        #if canImport(Darwin)
          String(localized: "Verify the file is a valid FAA CIFP file.", bundle: .module)
        #else
          "Verify the file is a valid FAA CIFP file."
        #endif
      case .fileNotFound:
        #if canImport(Darwin)
          String(
            localized: "Verify that the file exists and has not been moved or deleted.",
            bundle: .module
          )
        #else
          "Verify that the file exists and has not been moved or deleted."
        #endif
      case .parseError, .streamError, .lineTooShort, .unknownSectionCode, .unknownRecordType,
        .missingRequiredField, .unknownSubsectionCode, .aggregationError:
        nil
    }
  }
}
