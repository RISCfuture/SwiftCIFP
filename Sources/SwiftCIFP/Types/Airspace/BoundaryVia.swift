import Foundation

/// Path from a boundary point to the next one (ARINC 424 field 5.118, first column).
///
/// The second column marks the end of a description; see
/// ``AirspaceBoundary/isEndOfDescription``.
public enum BoundaryVia: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Arc by edge.
  case arcByEdge = "A"

  /// Circle.
  case circle = "C"

  /// Great circle route.
  case greatCircle = "G"

  /// Rhumb line.
  case rhumbLine = "H"

  /// Arc, counter-clockwise.
  case arcCounterClockwise = "L"

  /// Arc, clockwise.
  case arcClockwise = "R"

  /// Whether this path is defined by an arc origin, distance, and bearing.
  var hasArcDefinition: Bool {
    switch self {
      case .arcByEdge, .circle, .arcCounterClockwise, .arcClockwise: true
      case .greatCircle, .rhumbLine: false
    }
  }
}
