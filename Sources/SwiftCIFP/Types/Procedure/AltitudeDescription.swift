import Foundation

/// Altitude description code (ARINC 424 field 5.29).
///
/// Specifies how altitude values should be interpreted for a procedure leg. A blank
/// description means ``at``.
enum AltitudeDescription: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// At or above altitude 1.
  case atOrAbove = "+"

  /// At or below altitude 1.
  case atOrBelow = "-"

  /// At altitude 1.
  case at = "@"

  /// At or above altitude 2 to at or below altitude 1, which is always the higher.
  case between = "B"

  /// At or above altitude 2, as a conditional altitude termination on a SID leg.
  case conditionalAtOrAbove = "C"

  /// At altitude 1, with the glide slope altitude in altitude 2 (FAF, precision approach).
  case atWithGlideSlope = "G"

  /// At or above altitude 1, with the glide slope altitude in altitude 2 (FAF, precision
  /// approach).
  case atOrAboveWithGlideSlope = "H"

  /// At altitude 1, with the glide slope intercept altitude in altitude 2 (FACF, precision
  /// approach).
  case atWithGlideSlopeIntercept = "I"

  /// At or above altitude 1, with the glide slope intercept altitude in altitude 2 (FACF,
  /// precision approach).
  case atOrAboveWithGlideSlopeIntercept = "J"

  /// At or above altitude 1, with the vertical path altitude in altitude 2 (step-down fix).
  case atOrAboveWithVerticalPath = "V"

  /// At altitude 1, with the vertical path altitude in altitude 2 (step-down fix).
  case atWithVerticalPath = "X"

  /// At or below altitude 1, with the vertical path altitude in altitude 2 (step-down fix).
  case atOrBelowWithVerticalPath = "Y"
}
