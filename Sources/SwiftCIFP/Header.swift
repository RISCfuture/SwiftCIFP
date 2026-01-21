import Foundation

/// CIFP file data type indicator.
public enum FileType: String, Sendable, Codable, Equatable, Hashable {
  /// Production data.
  case production = "P"
  /// Test data.
  case test = "T"
}

/// CIFP file header information.
///
/// Contains metadata from the HDR01-HDR05 records at the start of the file.
public struct Header: Sendable, Codable, Equatable, Hashable {
  /// File name (e.g., "FAACIFP18").
  public let fileName: String

  /// Volume set identifier.
  public let volumeSet: String

  /// Version number.
  public let versionNumber: String

  /// File data type (production or test).
  public let fileType: FileType

  /// Total number of records in the file.
  public let recordCount: Int

  /// Cycle identifier (YYMM format).
  public let cycleId: String

  /// File creation date components (year, month, day).
  public let creationDateComponents: DateComponents?

  /// File creation date.
  public var creationDate: Date? {
    creationDateComponents.flatMap {
      Calendar(identifier: .gregorian).date(from: $0)
    }
  }

  /// Data supplier name.
  public let dataSupplier: String

  /// Descriptive text from HDR02-HDR05.
  public let descriptiveText: [String]

  /// Creates a Header record.
  init(
    fileName: String,
    volumeSet: String,
    versionNumber: String,
    fileType: FileType,
    recordCount: Int,
    cycleId: String,
    creationDateComponents: DateComponents?,
    dataSupplier: String,
    descriptiveText: [String]
  ) {
    self.fileName = fileName
    self.volumeSet = volumeSet
    self.versionNumber = versionNumber
    self.fileType = fileType
    self.recordCount = recordCount
    self.cycleId = cycleId
    self.creationDateComponents = creationDateComponents
    self.dataSupplier = dataSupplier
    self.descriptiveText = descriptiveText
  }
}
