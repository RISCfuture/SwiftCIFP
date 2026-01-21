import Foundation

/// Altitude description code.
///
/// Specifies how altitude values should be interpreted for a procedure leg.
enum AltitudeDescription: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// At or above altitude 1.
  case atOrAbove = "+"

  /// At or below altitude 1.
  case atOrBelow = "-"

  /// At altitude 1.
  case at = "@"

  /// Between altitude 1 and altitude 2.
  case between = "B"

  /// Glide slope altitude at fix (ILS).
  case glideSlopeIntercept = "G"

  /// Glide path altitude at fix (RNAV).
  case glidePathIntercept = "H"

  /// At or above altitude 1 to at or below altitude 2.
  case atOrAboveToAtOrBelow = "I"

  /// At or above altitude 1 to at altitude 2.
  case atOrAboveToAt = "J"

  /// At altitude 1 to at or below altitude 2.
  case atToAtOrBelow = "V"

  /// At altitude 1 to at or above altitude 2.
  case atToAtOrAbove = "X"

  /// At or below altitude 1 to at or above altitude 2.
  case atOrBelowToAtOrAbove = "Y"
}
