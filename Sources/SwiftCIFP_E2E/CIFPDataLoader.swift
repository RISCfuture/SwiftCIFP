import Foundation
import SwiftCIFP

/// Protocol for loading CIFP data from various sources.
protocol CIFPDataLoader {
  /// Load CIFP data from the source.
  /// - Parameters:
  ///   - progressHandler: Optional callback for progress tracking.
  ///   - errorCallback: Called for each parse error with (error, lineNumber).
  /// - Returns: The parsed CIFP data.
  func load(
    progressHandler: @Sendable (Progress) -> Void,
    errorCallback: @escaping (Error, Int?) -> Void
  ) async throws -> CIFP
}

/// Loads CIFP from a local file (supports both raw and ZIP).
struct FileDataLoader: CIFPDataLoader {
  let url: URL

  func load(
    progressHandler: @Sendable (Progress) -> Void,
    errorCallback: @escaping (Error, Int?) -> Void
  ) throws -> CIFP {
    let data: Data
    if url.pathExtension.lowercased() == "zip" {
      data = try ZipExtractor.extractCIFP(from: url)
    } else {
      data = try Data(contentsOf: url)
    }
    return try CIFP(data: data, progressHandler: progressHandler, errorCallback: errorCallback)
  }
}

/// Loads CIFP from a remote URL by downloading first.
struct URLDataLoader: CIFPDataLoader {
  let url: URL

  func load(
    progressHandler: @Sendable (Progress) -> Void,
    errorCallback: @escaping (Error, Int?) -> Void
  ) async throws -> CIFP {
    let (data, response) = try await URLSession.shared.data(from: url)

    if let httpResponse = response as? HTTPURLResponse,
      !(200..<300).contains(httpResponse.statusCode)
    {
      throw URLError(.badServerResponse)
    }

    let cifpData: Data
    if url.pathExtension.lowercased() == "zip" {
      cifpData = try ZipExtractor.extractCIFP(from: data)
    } else {
      cifpData = data
    }

    return try CIFP(data: cifpData, progressHandler: progressHandler, errorCallback: errorCallback)
  }
}

/// Creates the appropriate loader for the given URL.
func createLoader(for url: URL) -> CIFPDataLoader {
  if url.isFileURL {
    return FileDataLoader(url: url)
  }
  return URLDataLoader(url: url)
}
