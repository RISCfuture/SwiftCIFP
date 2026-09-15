public import Foundation

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

  /// Get a subsequence using a relative range from startIndex, clamped to the end of the
  /// collection. A range that begins past the end yields an empty subsequence.
  @inlinable
  func slice(_ range: Range<Int>) -> SubSequence {
    let lower = Swift.min(startIndex + range.lowerBound, endIndex),
      upper = Swift.min(startIndex + range.upperBound, endIndex)
    return self[lower..<upper]
  }

  /// Convert to trimmed String (only when actually needed).
  @inlinable
  func toString() -> String {
    toRawString().trimmingCharacters(in: .whitespaces)
  }

  /// Convert to raw String without trimming (for exact matching like section codes).
  ///
  /// Decodes in place over the collection's own storage, so no intermediate array is
  /// allocated per field. Bytes that are not valid UTF-8 yield an empty string.
  @inlinable
  func toRawString() -> String {
    unsafe (withContiguousStorageIfAvailable(String.init(validatingUTF8Bytes:))
      ?? ContiguousArray(self).withUnsafeBufferPointer(String.init(validatingUTF8Bytes:)))
  }

  /// Check if all bytes are whitespace.
  @inlinable
  func isBlank() -> Bool {
    allSatisfy { $0 == ASCII.space }
  }
}

extension String {
  /// Create a string from contiguous UTF-8 bytes without copying them into an
  /// intermediate array, yielding an empty string when the bytes are not valid UTF-8.
  @inlinable
  init(validatingUTF8Bytes bytes: UnsafeBufferPointer<UInt8>) {
    guard let utf8 = try? UTF8Span(validating: unsafe bytes.span) else {
      self = ""
      return
    }
    self.init(copying: utf8)
  }
}
