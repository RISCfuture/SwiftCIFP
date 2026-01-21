import Foundation

/// NDB (Non-Directional Beacon) power/range classification.
///
/// The NDB class indicates the power output and typical usable range.
public enum NDBClass: String, Sendable, Codable, CaseIterable {
  /// High power, long range (75+ nautical miles).
  case highHighPower = "HH"

  /// High power (50 nautical miles).
  case highPower = "H "

  /// Medium-high power (25 nautical miles).
  case mediumHighPower = "MH"

  /// Medium power (15 nautical miles).
  case mediumPower = "M "

  /// Low power (less than 15 nautical miles).
  case lowPower = "L "

  /// Compass locator (15 nautical miles, typically at outer marker).
  case compassLocator = "LO"

  /// High power compass locator at outer marker.
  case highPowerOuterMarker = "HO"

  /// Compass locator at outer marker.
  case compassOuterMarker = "CO"

  /// Compass locator at middle marker.
  case compassMiddleMarker = "CM"

  /// Typical usable range in nautical miles.
  public var typicalRange: Int {
    switch self {
      case .highHighPower: 75
      case .highPower, .highPowerOuterMarker: 50
      case .mediumHighPower: 25
      case .mediumPower, .compassLocator, .compassOuterMarker, .compassMiddleMarker: 15
      case .lowPower: 10
    }
  }
}

/// NDB additional information codes.
public enum NDBInfo: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Automatic weather broadcast.
  case automaticWeather = "A"

  /// BFO (Beat Frequency Oscillator) required.
  case bfoRequired = "B"

  /// No voice on frequency.
  case noVoice = "W"

  /// Unspecified.
  case none = " "
}
