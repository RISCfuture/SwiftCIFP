import Foundation

/// Converts between degrees and gradient using tan/atan.
private final class UnitConverterDegrees: UnitConverter, @unchecked Sendable {
  override func baseUnitValue(fromValue value: Double) -> Double {
    tan(value * .pi / 180)
  }

  override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
    atan(baseUnitValue) * 180 / .pi
  }
}

/// A unit of slope or gradient (rise over run).
///
/// ``UnitSlope`` provides units for measuring gradients, which describe the
/// steepness of inclines. In SwiftCIFP, this is used for:
///
/// - Glide slope angles (vertical descent gradient)
/// - Runway gradients (uphill/downhill slope)
/// - Climb gradients (feet per nautical mile)
///
/// ## Units
///
/// - ``degrees``: Slope expressed as an angle (e.g., 3° glide slope)
/// - ``gradient``: Decimal ratio (rise/run), base unit
/// - ``percentGrade``: Gradient x 100 (e.g., 2% grade)
/// - ``feetPerNauticalMile``: Aviation climb gradient standard
///
/// ## Usage
///
/// ```swift
/// // Glide slope of 3 degrees
/// let glideSlope = .init(value: 3, unit: UnitSlope.degrees)
///
/// // Convert to feet per nautical mile
/// let ftPerNM = glideSlope.converted(to: .feetPerNauticalMile)
/// // ftPerNM.value ≈ 318 (standard 3° glide slope)
/// ```
public final class UnitSlope: Dimension, @unchecked Sendable {
  /// Slope expressed as an angle in degrees.
  ///
  /// Converts to/from gradient using tan/atan. A 3° slope equals
  /// approximately 0.0524 gradient or 318 ft/NM.
  public static let degrees = UnitSlope(
    symbol: "°",
    converter: UnitConverterDegrees()
  )

  /// Base unit: gradient = rise/run as decimal
  public static let gradient = UnitSlope(
    symbol: "m",
    converter: UnitConverterLinear(coefficient: 1.0)
  )

  /// Percent grade, or gradient x 100
  public static let percentGrade = UnitSlope(
    symbol: "%",
    converter: UnitConverterLinear(coefficient: 0.01)
  )

  /// Feet per nautical mile (ft/NM)
  public static let feetPerNauticalMile = UnitSlope(
    symbol: "ft/NM",
    converter: UnitConverterLinear(
      coefficient: Measurement(value: 1, unit: UnitLength.feet).converted(to: .nauticalMiles).value
    )
  )

  override public static func baseUnit() -> UnitSlope { .gradient }
}
