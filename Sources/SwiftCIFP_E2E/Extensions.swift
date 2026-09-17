import Foundation

extension URL {
  /// Returns true if this URL uses the HTTP or HTTPS scheme.
  var isHTTP: Bool {
    guard let scheme = scheme?.lowercased() else { return false }
    return scheme == "http" || scheme == "https"
  }
}

extension FileHandle {
  /// Writes a string to this file handle.
  func write(_ string: String) {
    write(Data(string.utf8))
  }

  /// Writes a message to this file handle followed by a newline.
  func printError(_ message: String) {
    write("\(message)\n")
  }
}
