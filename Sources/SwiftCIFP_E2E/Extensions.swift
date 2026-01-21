import Foundation

extension URL {
  /// Returns true if this URL uses the HTTP or HTTPS scheme.
  var isHTTP: Bool {
    guard let scheme = scheme?.lowercased() else { return false }
    return scheme == "http" || scheme == "https"
  }
}

extension FileHandle {
  /// Writes a message to this file handle followed by a newline.
  func printError(_ message: String) {
    write(Data("\(message)\n".utf8))
  }
}
