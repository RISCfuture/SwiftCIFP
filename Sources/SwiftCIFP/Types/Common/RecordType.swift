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
