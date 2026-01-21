import CoreLocation
import Foundation

/// Localizer/Glide Slope record.
///
/// Contains ILS component information including localizer and glide slope data.
public struct LocalizerGlideSlope: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Localizer identifier (e.g., "I-LAX").
  public let localizerId: String

  /// ILS/MLS category.
  public let ilsCategory: ILSCategory?

  /// Localizer frequency in MHz.
  public let frequencyMHz: Double

  /// Associated runway identifier.
  let runwayId: String

  /// Localizer antenna coordinate.
  public let coordinate: Coordinate

  /// Localizer bearing in degrees magnetic.
  public let bearingDeg: Double

  /// Glide slope antenna coordinate.
  public let slopeCoordinate: Coordinate?

  /// Glide slope angle in degrees.
  public let slopeAngleDeg: Double?

  /// Localizer beam width in degrees.
  public let widthDeg: Double?

  /// Station magnetic declination in degrees.
  public let stationDeclinationDeg: Double?

  /// Threshold crossing height in feet.
  public let thresholdCrossingHeightFt: Int?

  /// Whether this ILS has a glide slope component.
  public var hasGlideSlope: Bool {
    slopeCoordinate != nil || slopeAngleDeg != nil
  }

  /// Creates a Localizer/Glide Slope record.
  init(
    airportId: String,
    icaoRegion: String,
    localizerId: String,
    ilsCategory: ILSCategory?,
    frequencyMHz: Double,
    runwayId: String,
    coordinate: Coordinate,
    bearingDeg: Double,
    slopeCoordinate: Coordinate?,
    slopeAngleDeg: Double?,
    widthDeg: Double?,
    stationDeclinationDeg: Double?,
    thresholdCrossingHeightFt: Int?
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.localizerId = localizerId
    self.ilsCategory = ilsCategory
    self.frequencyMHz = frequencyMHz
    self.runwayId = runwayId
    self.coordinate = coordinate
    self.bearingDeg = bearingDeg
    self.slopeCoordinate = slopeCoordinate
    self.slopeAngleDeg = slopeAngleDeg
    self.widthDeg = widthDeg
    self.stationDeclinationDeg = stationDeclinationDeg
    self.thresholdCrossingHeightFt = thresholdCrossingHeightFt
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, localizerId, ilsCategory
    case frequencyMHz, runwayId, coordinate, bearingDeg
    case slopeCoordinate, slopeAngleDeg, widthDeg
    case stationDeclinationDeg, thresholdCrossingHeightFt
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension LocalizerGlideSlope: Identifiable, Equatable, Hashable {
  public var id: String { "\(airportId)-\(localizerId)" }

  public static func == (lhs: LocalizerGlideSlope, rhs: LocalizerGlideSlope) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension LocalizerGlideSlope: CustomStringConvertible {
  public var description: String {
    localizerId
  }
}

// MARK: - Measurement Extensions

extension LocalizerGlideSlope {
  /// Localizer frequency as a Measurement.
  public var frequency: Measurement<UnitFrequency> {
    .init(value: frequencyMHz, unit: .megahertz)
  }

  /// Localizer bearing as a Measurement.
  public var bearing: Measurement<UnitAngle> {
    .init(value: bearingDeg, unit: .degrees)
  }

  /// Glide slope as a gradient measurement.
  public var slopeAngle: Measurement<UnitSlope>? {
    slopeAngleDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Localizer beam width as a Measurement.
  public var width: Measurement<UnitAngle>? {
    widthDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Station magnetic declination as a Measurement.
  public var stationDeclination: Measurement<UnitAngle>? {
    stationDeclinationDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Threshold crossing height as a Measurement.
  public var thresholdCrossingHeight: Measurement<UnitLength>? {
    thresholdCrossingHeightFt.map { .init(value: Double($0), unit: .feet) }
  }
}

// MARK: - Linked Properties

extension LocalizerGlideSlope {
  /// The associated runway.
  ///
  /// This property resolves the `runwayId` to the actual
  /// `Runway` object when linked via `CIFPData`.
  public var runway: Runway? {
    get async {
      guard let data else { return nil }
      return await data.runway(runwayId, airportId: airportId)
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
