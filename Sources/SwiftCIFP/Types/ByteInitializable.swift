import Foundation

/// Protocol for Character-based enums that can be initialized from an ASCII byte.
protocol ByteInitializable: RawRepresentable where RawValue == Character {
  init?(byte: UInt8)
}

extension ByteInitializable {
  /// Initialize from an ASCII byte value.
  init?(byte: UInt8) {
    self.init(rawValue: Character(UnicodeScalar(byte)))
  }
}

/// Protocol for String-based enums that can be initialized from ASCII bytes.
protocol StringByteInitializable: RawRepresentable where RawValue == String {
  init?(bytes: some RandomAccessCollection<UInt8>)
}

extension StringByteInitializable {
  /// Initialize from ASCII bytes.
  init?(bytes: some RandomAccessCollection<UInt8>) {
    guard let string = String(bytes: Array(bytes), encoding: .utf8) else { return nil }
    self.init(rawValue: string.trimmingCharacters(in: .whitespaces))
  }
}
