import Foundation

/// Represents an altitude value which can be expressed in different formats.
///
/// CIFP altitude fields can contain:
/// - `NNNNN`: Altitude in feet (e.g., "18000" = 18000 ft)
/// - `FLNNN`: Flight level (e.g., "FL180" = FL180)
/// - `GND  `: Ground level
/// - `UNKNN`: Unknown altitude
/// - `UNLTD`: Unlimited altitude
public enum Altitude: Sendable, Codable, Equatable, Hashable {

  /// Altitude in feet with reference datum (MSL or AGL).
  case feet(Int, Datum)

  /// Flight level (hundreds of feet in standard atmosphere).
  case flightLevel(Int)

  /// Ground level.
  case ground

  /// Unknown altitude (UNKNN in ARINC 424).
  case unknown

  /// Unlimited altitude (UNLTD in ARINC 424).
  case unlimited

  /// The altitude value in feet, if applicable.
  ///
  /// For flight levels, this converts to approximate feet (FL × 100).
  /// Returns `nil` for ground, unknown, or unlimited.
  public var feetValue: Int? {
    switch self {
      case .feet(let ft, _): ft
      case .flightLevel(let fl): fl * 100
      case .ground, .unknown, .unlimited: nil
    }
  }

  /// The altitude reference datum, if applicable.
  ///
  /// Returns the datum for feet-based altitudes, `nil` for other types.
  public var datum: Datum? {
    switch self {
      case .feet(_, let datum): datum
      case .flightLevel, .ground, .unknown, .unlimited: nil
    }
  }

  /// Altitude reference datum for feet-based altitudes.
  public enum Datum: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Mean sea level.
    case msl = "M"

    /// Above ground level.
    case agl = "A"
  }
}

// MARK: - Measurement Extension

extension Altitude {
  /// The altitude as a Measurement of length, if applicable.
  public var measurement: Measurement<UnitLength>? {
    guard let feetValue else { return nil }
    return .init(value: Double(feetValue), unit: .feet)
  }
}

// MARK: - CustomStringConvertible

extension Altitude: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .feet(ft, datum):
        switch datum {
          case .msl: "\(ft) ft MSL"
          case .agl: "\(ft) ft AGL"
        }
      case .flightLevel(let fl): "FL\(fl)"
      case .ground: "GND"
      case .unknown: "UNKN"
      case .unlimited: "UNL"
    }
  }
}
