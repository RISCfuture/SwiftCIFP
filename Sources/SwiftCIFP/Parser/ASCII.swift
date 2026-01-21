import Foundation

/// ASCII byte constants for efficient byte-level parsing.
@usableFromInline
enum ASCII {
  @usableFromInline static let LF: UInt8 = 0x0A  // '\n'
  @usableFromInline static let CR: UInt8 = 0x0D  // '\r'
  @usableFromInline static let space: UInt8 = 0x20  // ' '
  @usableFromInline static let plus: UInt8 = 0x2B  // '+'
  @usableFromInline static let minus: UInt8 = 0x2D  // '-'
  @usableFromInline static let dot: UInt8 = 0x2E  // '.'
  @usableFromInline static let slash: UInt8 = 0x2F  // '/'
  @usableFromInline static let zero: UInt8 = 0x30  // '0'
  @usableFromInline static let one: UInt8 = 0x31  // '1'
  @usableFromInline static let two: UInt8 = 0x32  // '2'
  @usableFromInline static let three: UInt8 = 0x33  // '3'
  @usableFromInline static let four: UInt8 = 0x34  // '4'
  @usableFromInline static let five: UInt8 = 0x35  // '5'
  @usableFromInline static let six: UInt8 = 0x36  // '6'
  @usableFromInline static let seven: UInt8 = 0x37  // '7'
  @usableFromInline static let eight: UInt8 = 0x38  // '8'
  @usableFromInline static let nine: UInt8 = 0x39  // '9'
  @usableFromInline static let at: UInt8 = 0x40  // '@'
  @usableFromInline static let A: UInt8 = 0x41
  @usableFromInline static let B: UInt8 = 0x42
  @usableFromInline static let C: UInt8 = 0x43
  @usableFromInline static let D: UInt8 = 0x44
  @usableFromInline static let E: UInt8 = 0x45
  @usableFromInline static let F: UInt8 = 0x46
  @usableFromInline static let G: UInt8 = 0x47
  @usableFromInline static let H: UInt8 = 0x48
  @usableFromInline static let I: UInt8 = 0x49
  @usableFromInline static let J: UInt8 = 0x4A
  @usableFromInline static let K: UInt8 = 0x4B
  @usableFromInline static let L: UInt8 = 0x4C
  @usableFromInline static let M: UInt8 = 0x4D
  @usableFromInline static let N: UInt8 = 0x4E
  @usableFromInline static let O: UInt8 = 0x4F
  @usableFromInline static let P: UInt8 = 0x50
  @usableFromInline static let Q: UInt8 = 0x51
  @usableFromInline static let R: UInt8 = 0x52
  @usableFromInline static let S: UInt8 = 0x53
  @usableFromInline static let T: UInt8 = 0x54
  @usableFromInline static let U: UInt8 = 0x55
  @usableFromInline static let V: UInt8 = 0x56
  @usableFromInline static let W: UInt8 = 0x57
  @usableFromInline static let X: UInt8 = 0x58
  @usableFromInline static let Y: UInt8 = 0x59
  @usableFromInline static let Z: UInt8 = 0x5A

  @inlinable
  static func isDigit(_ byte: UInt8) -> Bool {
    byte >= zero && byte <= nine
  }

  @inlinable
  static func digitValue(_ byte: UInt8) -> Int {
    Int(byte - zero)
  }

  @inlinable
  static func isUpperAlpha(_ byte: UInt8) -> Bool {
    byte >= A && byte <= Z
  }

  @inlinable
  static func isAlphanumeric(_ byte: UInt8) -> Bool {
    isDigit(byte) || isUpperAlpha(byte)
  }
}
