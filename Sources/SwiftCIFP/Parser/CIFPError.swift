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
        String(localized: "File encoding was invalid.", bundle: .module)
      case .invalidFormat:
        String(localized: "CIFP data format was invalid.", bundle: .module)
      case .parseError:
        String(localized: "CIFP data could not be parsed.", bundle: .module)
      case .fileNotFound:
        String(localized: "CIFP file was not found.", bundle: .module)
      case .streamError:
        String(localized: "A stream error occurred.", bundle: .module)
      case .lineTooShort:
        String(localized: "Line was too short.", bundle: .module)
      case .unknownSectionCode:
        String(localized: "Unknown section code.", bundle: .module)
      case .unknownRecordType:
        String(localized: "Unknown record type.", bundle: .module)
      case .missingRequiredField:
        String(localized: "Required field was missing.", bundle: .module)
      case .unknownSubsectionCode:
        String(localized: "Unknown subsection code.", bundle: .module)
      case .aggregationError:
        String(localized: "Record aggregation failed.", bundle: .module)
    }
  }

  public var failureReason: String? {
    switch self {
      case .invalidEncoding:
        return String(localized: "The file is not valid ASCII encoding.", bundle: .module)
      case .invalidFormat(let error):
        return switch error {
          case .missingHeader:
            String(
              localized: "The CIFP file does not contain valid header records.",
              bundle: .module
            )
          case .invalidCycleDate:
            String(localized: "The cycle date in the header could not be parsed.", bundle: .module)
          case .invalidCoordinate(let value):
            String(
              localized: "Coordinate value “\(value)” is not in valid HDDDMMSSSS format.",
              bundle: .module
            )
          case .invalidAltitude(let value):
            String(localized: "Altitude value “\(value)” could not be parsed.", bundle: .module)
          case .invalidLatitudeDirection(let char):
            String(
              localized: "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”.",
              bundle: .module
            )
          case .invalidLongitudeDirection(let char):
            String(
              localized: "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”.",
              bundle: .module
            )
        }
      case let .parseError(field, value, line):
        return String(
          localized: "Failed to parse \(field) “\(value)” at line \(line, format: .number).",
          bundle: .module
        )
      case .fileNotFound(let url):
        return String(localized: "The file at “\(url.path)” could not be found.", bundle: .module)
      case .streamError(let error):
        return String(
          localized: "An error occurred while reading: \(error.localizedDescription)",
          bundle: .module
        )
      case let .lineTooShort(expected, actual, line):
        return String(
          localized:
            "Line \(line, format: .number) has \(actual, format: .number) characters but \(expected, format: .number) are required.",
          bundle: .module
        )
      case let .unknownSectionCode(code, line):
        return String(
          localized: "Unknown section code “\(code)” at line \(line, format: .number).",
          bundle: .module
        )
      case let .unknownRecordType(type, line):
        return String(
          localized: "Unknown record type “\(String(type))” at line \(line, format: .number).",
          bundle: .module
        )
      case let .missingRequiredField(field, recordType, line):
        return String(
          localized:
            "Field “\(field)” is required for \(recordType) at line \(line, format: .number).",
          bundle: .module
        )
      case let .unknownSubsectionCode(section, subsection, line):
        return String(
          localized:
            "Unknown subsection “\(String(subsection))” in section “\(section)” at line \(line, format: .number).",
          bundle: .module
        )
      case let .aggregationError(recordType, identifier, reason):
        let reasonString: String =
          switch reason {
            case .missingAirwayMetadata:
              String(localized: "missing route type or level", bundle: .module)
            case .missingMSARadius:
              String(localized: "missing radius", bundle: .module)
            case .invalidRouteType(let char):
              String(localized: "invalid route type “\(String(char))”", bundle: .module)
            case .missingRouteType:
              String(localized: "missing route type", bundle: .module)
            case .invalidApproachType(let char):
              String(localized: "invalid approach type “\(String(char))”", bundle: .module)
            case .missingApproachType:
              String(localized: "missing approach type", bundle: .module)
            case .noBoundaryRecords:
              String(localized: "no boundary records", bundle: .module)
            case .missingRestrictiveType:
              String(localized: "missing restrictive type", bundle: .module)
            case .noLegRecords:
              String(localized: "no leg records", bundle: .module)
          }
        return String(
          localized: "\(recordType) “\(identifier)” could not be built: \(reasonString).",
          bundle: .module
        )
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidEncoding, .invalidFormat:
        String(localized: "Verify the file is a valid FAA CIFP file.", bundle: .module)
      case .fileNotFound:
        String(
          localized: "Verify that the file exists and has not been moved or deleted.",
          bundle: .module
        )
      case .parseError, .streamError, .lineTooShort, .unknownSectionCode, .unknownRecordType,
        .missingRequiredField, .unknownSubsectionCode, .aggregationError:
        nil
    }
  }
}
