import Foundation

/// Extensions for parsing numeric values directly from ASCII byte sequences.
extension RandomAccessCollection where Element == UInt8, Index == Int {

  /// Parse an integer directly from ASCII bytes, skipping leading whitespace.
  @inlinable
  func parseInt() -> Int? {
    var result = 0
    var started = false
    var negative = false

    for byte in self {
      if byte == ASCII.space {
        if started { break }
        continue
      }
      if byte == ASCII.minus && !started {
        negative = true
        started = true
        continue
      }
      guard ASCII.isDigit(byte) else {
        if started { break }
        return nil
      }
      started = true
      result = result * 10 + ASCII.digitValue(byte)
    }

    guard started else { return nil }
    return negative ? -result : result
  }

  /// Parse an unsigned integer directly from ASCII bytes.
  @inlinable
  func parseUInt() -> UInt? {
    var result: UInt = 0
    var started = false

    for byte in self {
      if byte == ASCII.space {
        if started { break }
        continue
      }
      guard ASCII.isDigit(byte) else {
        if started { break }
        return nil
      }
      started = true
      result = result * 10 + UInt(ASCII.digitValue(byte))
    }

    guard started else { return nil }
    return result
  }

  /// Parse a double directly from ASCII bytes (handles "123.45" format).
  @inlinable
  func parseDouble() -> Double? {
    var result: Double = 0
    var fraction: Double = 0
    var fractionDivisor: Double = 1
    var inFraction = false
    var started = false
    var negative = false

    for byte in self {
      if byte == ASCII.space {
        if started { break }
        continue
      }
      if byte == ASCII.minus && !started {
        negative = true
        started = true
        continue
      }
      if byte == ASCII.dot {
        inFraction = true
        started = true
        continue
      }
      guard ASCII.isDigit(byte) else {
        if started { break }
        return nil
      }
      started = true
      let digit = Double(ASCII.digitValue(byte))
      if inFraction {
        fractionDivisor *= 10
        fraction = fraction * 10 + digit
      } else {
        result = result * 10 + digit
      }
    }

    guard started else { return nil }
    let value = result + fraction / fractionDivisor
    return negative ? -value : value
  }

  /// Get a subsequence using a relative range from startIndex.
  @inlinable
  func slice(_ range: Range<Int>) -> SubSequence {
    let lower = startIndex + range.lowerBound
    let upper = startIndex + range.upperBound
    return self[lower..<Swift.min(upper, endIndex)]
  }

  /// Convert to trimmed String (only when actually needed).
  @inlinable
  func toString() -> String {
    guard let string = String(bytes: Array(self), encoding: .utf8) else { return "" }
    return string.trimmingCharacters(in: .whitespaces)
  }

  /// Convert to raw String without trimming (for exact matching like section codes).
  @inlinable
  func toRawString() -> String {
    String(bytes: Array(self), encoding: .utf8) ?? ""
  }

  /// Check if all bytes are whitespace.
  @inlinable
  func isBlank() -> Bool {
    allSatisfy { $0 == ASCII.space }
  }
}
