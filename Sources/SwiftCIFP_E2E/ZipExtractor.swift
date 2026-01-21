import Foundation
import ZIPFoundation

/// Errors that can occur during ZIP extraction.
public enum ZipExtractorError: Error, LocalizedError {
  /// The ZIP archive is invalid or corrupted.
  case invalidZipFormat

  /// The CIFP data file was not found in the archive.
  case cifpNotFound

  public var errorDescription: String? {
    switch self {
      case .invalidZipFormat:
        "The ZIP archive could not be read."
      case .cifpNotFound:
        "The CIFP data file was not found in the ZIP archive."
    }
  }

  public var failureReason: String? {
    switch self {
      case .invalidZipFormat:
        "The file may be corrupted or not a valid ZIP archive."
      case .cifpNotFound:
        "Expected to find FAACIFP18 or a .dat file in the archive."
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidZipFormat:
        "Re-download the file and try again."
      case .cifpNotFound:
        "Verify the archive contains the CIFP data file."
    }
  }
}

/// Extracts CIFP data from ZIP archives.
public enum ZipExtractor {
  /// Extract CIFP data from a ZIP file URL.
  ///
  /// - Parameter url: The URL of the ZIP file.
  /// - Returns: The extracted CIFP data.
  /// - Throws: ZipExtractorError if extraction fails.
  public static func extractCIFP(from url: URL) throws -> Data {
    let data = try Data(contentsOf: url)
    return try extractCIFP(from: data)
  }

  /// Extract CIFP data from raw ZIP bytes.
  ///
  /// - Parameter zipData: The ZIP file data.
  /// - Returns: The extracted CIFP data.
  /// - Throws: ZipExtractorError if extraction fails.
  public static func extractCIFP(from zipData: Data) throws -> Data {
    let archive: Archive
    do {
      archive = try Archive(data: zipData, accessMode: .read)
    } catch {
      throw ZipExtractorError.invalidZipFormat
    }

    // Look for FAACIFP18 first (exact match, case-insensitive)
    if let entry = archive.first(where: {
      $0.path.uppercased().hasSuffix("FAACIFP18")
    }) {
      return try extractEntry(entry, from: archive)
    }

    // Fall back to any file without an extension (CIFP files have no extension)
    if let entry = archive.first(where: {
      let filename = URL(fileURLWithPath: $0.path).lastPathComponent
      return !filename.contains(".") && !filename.isEmpty && $0.type == .file
    }) {
      return try extractEntry(entry, from: archive)
    }

    throw ZipExtractorError.cifpNotFound
  }

  private static func extractEntry(_ entry: Entry, from archive: Archive) throws -> Data {
    var extractedData = Data()
    _ = try archive.extract(entry) { data in
      extractedData.append(data)
    }
    return extractedData
  }
}
