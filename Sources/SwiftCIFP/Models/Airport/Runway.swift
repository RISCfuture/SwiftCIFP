import CoreLocation
import Foundation

/// Runway record.
///
/// Contains runway physical characteristics and approach information.
public struct Runway: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Runway identifier (e.g., "09L", "27R", "18").
  public let name: String

  /// Runway length in feet.
  public let lengthFt: Int

  /// Runway magnetic bearing in degrees.
  public let magneticBearingDeg: Double?

  /// Runway threshold coordinate.
  public let thresholdCoordinate: Coordinate

  /// Runway gradient in percent (positive = uphill).
  public let gradientPct: Double?

  /// Threshold ellipsoid height in feet.
  public let ellipsoidHeightFt: Int?

  /// Landing threshold elevation in feet MSL.
  public let thresholdElevationFt: Int

  /// Displaced threshold distance in feet.
  public let displacedThresholdFt: Int

  /// Threshold crossing height in feet.
  public let thresholdCrossingHeightFt: Int

  /// Runway width in feet.
  public let widthFt: Int

  /// Associated localizer identifier.
  public let localizerId: String?

  /// ILS/MLS category.
  public let ilsCategory: ILSCategory?

  /// Stopway distance in feet.
  public let stopwayFt: Int?

  /// Creates a Runway record.
  init(
    airportId: String,
    icaoRegion: String,
    runwayId: String,
    lengthFt: Int,
    magneticBearingDeg: Double?,
    thresholdCoordinate: Coordinate,
    gradientPct: Double?,
    ellipsoidHeightFt: Int?,
    thresholdElevationFt: Int,
    displacedThresholdFt: Int,
    thresholdCrossingHeightFt: Int,
    widthFt: Int,
    localizerId: String?,
    ilsCategory: ILSCategory?,
    stopwayFt: Int?
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.name = runwayId
    self.lengthFt = lengthFt
    self.magneticBearingDeg = magneticBearingDeg
    self.thresholdCoordinate = thresholdCoordinate
    self.gradientPct = gradientPct
    self.ellipsoidHeightFt = ellipsoidHeightFt
    self.thresholdElevationFt = thresholdElevationFt
    self.displacedThresholdFt = displacedThresholdFt
    self.thresholdCrossingHeightFt = thresholdCrossingHeightFt
    self.widthFt = widthFt
    self.localizerId = localizerId
    self.ilsCategory = ilsCategory
    self.stopwayFt = stopwayFt
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, name, lengthFt
    case magneticBearingDeg, thresholdCoordinate, gradientPct
    case ellipsoidHeightFt, thresholdElevationFt, displacedThresholdFt
    case thresholdCrossingHeightFt, widthFt, localizerId
    case ilsCategory, stopwayFt
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension Runway: Identifiable, Equatable, Hashable {
  public var id: String { "\(airportId)-\(name)" }

  public static func == (lhs: Runway, rhs: Runway) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension Runway: CustomStringConvertible {
  public var description: String {
    "RW\(name)"
  }
}

// MARK: - Measurement Extensions

extension Runway {
  /// Runway length as a Measurement.
  public var length: Measurement<UnitLength> {
    .init(value: Double(lengthFt), unit: .feet)
  }

  /// Runway magnetic bearing as a Measurement.
  public var magneticBearing: Measurement<UnitAngle>? {
    magneticBearingDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Runway gradient as a Measurement.
  public var gradient: Measurement<UnitSlope>? {
    gradientPct.map { .init(value: $0, unit: .percentGrade) }
  }

  /// Threshold ellipsoid height as a Measurement.
  public var ellipsoidHeight: Measurement<UnitLength>? {
    ellipsoidHeightFt.map { .init(value: Double($0), unit: .feet) }
  }

  /// Landing threshold elevation as a Measurement.
  public var thresholdElevation: Measurement<UnitLength> {
    .init(value: Double(thresholdElevationFt), unit: .feet)
  }

  /// Displaced threshold distance as a Measurement.
  public var displacedThreshold: Measurement<UnitLength> {
    .init(value: Double(displacedThresholdFt), unit: .feet)
  }

  /// Threshold crossing height as a Measurement.
  public var thresholdCrossingHeight: Measurement<UnitLength> {
    .init(value: Double(thresholdCrossingHeightFt), unit: .feet)
  }

  /// Runway width as a Measurement.
  public var width: Measurement<UnitLength> {
    .init(value: Double(widthFt), unit: .feet)
  }

  /// Stopway distance as a Measurement.
  public var stopway: Measurement<UnitLength>? {
    stopwayFt.map { .init(value: Double($0), unit: .feet) }
  }
}

// MARK: - Linked Properties

extension Runway {
  /// The associated localizer/glide slope, if any.
  ///
  /// This property resolves the `localizerId` to the actual
  /// `LocalizerGlideSlope` object when linked via `CIFPData`.
  public var localizer: LocalizerGlideSlope? {
    get async {
      guard let localizerId,
        let data
      else { return nil }
      return await data.localizer(localizerId, airportId: airportId)
    }
  }

  /// The parent airport.
  ///
  /// This property resolves the `airportId` to the actual `Airport` object
  /// when linked via `CIFPData`.
  public var airport: Airport? {
    get async {
      guard let data else { return nil }
      return await data.airport(airportId)
    }
  }
}
