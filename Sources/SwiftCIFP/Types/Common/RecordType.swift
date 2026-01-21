import Foundation

/// CIFP record type indicator (position 1).
enum RecordType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Standard record.
  case standard = "S"

  /// Header record.
  case header = "H"

  /// Tailored record.
  case tailored = "T"
}

/// Customer/area code (positions 2-4).
enum CustomerAreaCode: String, Sendable, Codable, CaseIterable {
  /// United States.
  case usa = "USA"

  /// Canada.
  case canada = "CAN"

  /// Pacific.
  case pacific = "PAC"

  /// Continuation record (blank).
  case continuation = "   "

  /// Initialize from bytes, handling the "S   " pattern for continuation records.
  init?<T: RandomAccessCollection>(bytes: T) where T.Element == UInt8, T.Index == Int {
    let str = bytes.toString()
    if str.isEmpty {
      self = .continuation
    } else {
      guard let code = Self(rawValue: str) else { return nil }
      self = code
    }
  }
}
