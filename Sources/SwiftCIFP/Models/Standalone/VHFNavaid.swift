import CoreLocation
import Foundation

/// VHF Navaid (VOR, VORTAC, DME) record.
///
/// VHF navigation aids are ground-based radio stations used for aircraft navigation.
public struct VHFNavaid: Sendable, Codable {
  /// The navaid identifier (typically 3-4 characters).
  public let identifier: String

  /// ICAO region code.
  public let icaoRegion: String

  /// VOR frequency in MHz (e.g., 115.90).
  public let frequencyMHz: Double

  /// Navaid class/type.
  public let navaidClass: NavaidClass

  /// Usage/altitude class.
  public let usageClass: NavaidUsageClass?

  /// VOR transmitter coordinate.
  public let vorCoordinate: Coordinate?

  /// DME transponder coordinate (may differ from VOR).
  public let dmeCoordinate: Coordinate?

  /// Station magnetic declination/variation in degrees.
  public let stationDeclinationDeg: Double

  /// DME elevation in feet MSL.
  public let dmeElevationFt: Int?

  /// Figure of merit (accuracy indicator).
  public let figureOfMerit: Int?

  /// ILS/DME bias in nautical miles.
  public let ilsDMEBiasNM: Double?

  /// Facility name.
  public let name: String

  /// The primary coordinate (VOR if available, otherwise DME).
  public var coordinate: Coordinate? {
    vorCoordinate ?? dmeCoordinate
  }

  /// Whether this navaid has DME capability.
  public var hasDME: Bool {
    dmeCoordinate != nil || navaidClass.hasDME
  }

  /// Whether this navaid has VOR capability.
  public var hasVOR: Bool {
    vorCoordinate != nil || navaidClass.hasVOR
  }

  /// Creates a VHF Navaid record.
  init(
    identifier: String,
    icaoRegion: String,
    frequencyMHz: Double,
    navaidClass: NavaidClass,
    usageClass: NavaidUsageClass?,
    vorCoordinate: Coordinate?,
    dmeCoordinate: Coordinate?,
    stationDeclinationDeg: Double,
    dmeElevationFt: Int?,
    figureOfMerit: Int?,
    ilsDMEBiasNM: Double?,
    name: String
  ) {
    self.identifier = identifier
    self.icaoRegion = icaoRegion
    self.frequencyMHz = frequencyMHz
    self.navaidClass = navaidClass
    self.usageClass = usageClass
    self.vorCoordinate = vorCoordinate
    self.dmeCoordinate = dmeCoordinate
    self.stationDeclinationDeg = stationDeclinationDeg
    self.dmeElevationFt = dmeElevationFt
    self.figureOfMerit = figureOfMerit
    self.ilsDMEBiasNM = ilsDMEBiasNM
    self.name = name
  }
}

// MARK: - CustomStringConvertible

extension VHFNavaid: CustomStringConvertible {
  public var description: String {
    "\(identifier) (VOR)"
  }
}

// MARK: - Measurement Extensions

extension VHFNavaid {
  /// VOR frequency as a Measurement.
  public var frequency: Measurement<UnitFrequency> {
    .init(value: frequencyMHz, unit: .megahertz)
  }

  /// Station magnetic declination as a Measurement.
  public var stationDeclination: Measurement<UnitAngle> {
    .init(value: stationDeclinationDeg, unit: .degrees)
  }

  /// DME elevation as a Measurement.
  public var dmeElevation: Measurement<UnitLength>? {
    dmeElevationFt.map { .init(value: Double($0), unit: .feet) }
  }

  /// ILS/DME bias as a Measurement.
  public var ilsDMEBias: Measurement<UnitLength>? {
    ilsDMEBiasNM.map { .init(value: $0, unit: .nauticalMiles) }
  }
}
