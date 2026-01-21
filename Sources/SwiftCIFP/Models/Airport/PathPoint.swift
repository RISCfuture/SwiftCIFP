import CoreLocation
import Foundation

/// Path point type.
public enum PathPointType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Landing threshold point (LTP).
  case landingThreshold = "A"

  /// Flight path alignment point (FPAP).
  case flightPathAlignment = "G"

  /// Glide path intercept point (GPIP).
  case glidePathIntercept = "P"
}

/// Path Point record.
///
/// Defines precision path points for RNAV approaches (GLS, SBAS, etc.).
public struct PathPoint: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Parent airport ICAO identifier.
  let airportId: String

  /// ICAO region code.
  public let icaoRegion: String

  /// Approach procedure identifier.
  let approachId: String

  /// Associated runway identifier.
  let runwayId: String

  /// Path point type.
  public let pathPointType: PathPointType?

  /// Point coordinate (LTP/FTP coordinate from primary record).
  public let coordinate: Coordinate?

  /// Ellipsoid height in feet.
  public let ellipsoidHeightFt: Double?

  /// Glide path angle in degrees.
  public let glidepathAngleDeg: Double?

  /// Flight path alignment point coordinate.
  public let flightPathAlignmentPoint: Coordinate?

  /// Course width in meters.
  public let courseWidthM: Double?

  /// Length offset in meters.
  public let lengthOffsetM: Double?

  /// Reference path identifier.
  public let referencePathId: String?

  // MARK: - Continuation Record Fields (ARINC 424-17 section 4.1.28.2)

  /// FPAP ellipsoid height in feet.
  public let fpapEllipsoidHeightFt: Double?

  /// FPAP orthometric height in feet.
  public let fpapOrthometricHeightFt: Double?

  /// LTP orthometric height in feet.
  public let ltpOrthometricHeightFt: Double?

  /// Approach type identifier.
  public let approachTypeIdentifier: String?

  /// GNSS channel number.
  public let gnssChannelNumber: Int?

  /// Helicopter procedure course in degrees.
  public let helicopterProcedureCourse: Double?

  /// Creates a Path Point record.
  init(
    airportId: String,
    icaoRegion: String,
    approachId: String,
    runwayId: String,
    pathPointType: PathPointType?,
    coordinate: Coordinate?,
    ellipsoidHeightFt: Double?,
    glidepathAngleDeg: Double?,
    flightPathAlignmentPoint: Coordinate?,
    courseWidthM: Double?,
    lengthOffsetM: Double?,
    referencePathId: String?,
    fpapEllipsoidHeightFt: Double?,
    fpapOrthometricHeightFt: Double?,
    ltpOrthometricHeightFt: Double?,
    approachTypeIdentifier: String?,
    gnssChannelNumber: Int?,
    helicopterProcedureCourse: Double?
  ) {
    self.airportId = airportId
    self.icaoRegion = icaoRegion
    self.approachId = approachId
    self.runwayId = runwayId
    self.pathPointType = pathPointType
    self.coordinate = coordinate
    self.ellipsoidHeightFt = ellipsoidHeightFt
    self.glidepathAngleDeg = glidepathAngleDeg
    self.flightPathAlignmentPoint = flightPathAlignmentPoint
    self.courseWidthM = courseWidthM
    self.lengthOffsetM = lengthOffsetM
    self.referencePathId = referencePathId
    self.fpapEllipsoidHeightFt = fpapEllipsoidHeightFt
    self.fpapOrthometricHeightFt = fpapOrthometricHeightFt
    self.ltpOrthometricHeightFt = ltpOrthometricHeightFt
    self.approachTypeIdentifier = approachTypeIdentifier
    self.gnssChannelNumber = gnssChannelNumber
    self.helicopterProcedureCourse = helicopterProcedureCourse
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case airportId, icaoRegion, approachId, runwayId
    case pathPointType, coordinate, ellipsoidHeightFt
    case glidepathAngleDeg, flightPathAlignmentPoint
    case courseWidthM, lengthOffsetM, referencePathId
    case fpapEllipsoidHeightFt, fpapOrthometricHeightFt
    case ltpOrthometricHeightFt, approachTypeIdentifier
    case gnssChannelNumber, helicopterProcedureCourse
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Measurement Extensions

extension PathPoint {
  /// Ellipsoid height as a Measurement.
  public var ellipsoidHeight: Measurement<UnitLength>? {
    ellipsoidHeightFt.map { .init(value: $0, unit: .feet) }
  }

  /// Glide path angle as a Measurement.
  public var glidepathAngle: Measurement<UnitSlope>? {
    glidepathAngleDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Course width as a Measurement.
  public var courseWidth: Measurement<UnitLength>? {
    courseWidthM.map { .init(value: $0, unit: .meters) }
  }

  /// Length offset as a Measurement.
  public var lengthOffset: Measurement<UnitLength>? {
    lengthOffsetM.map { .init(value: $0, unit: .meters) }
  }

  // MARK: - Continuation Field Measurements

  /// FPAP ellipsoid height as a Measurement.
  public var fpapEllipsoidHeight: Measurement<UnitLength>? {
    fpapEllipsoidHeightFt.map { .init(value: $0, unit: .feet) }
  }

  /// FPAP orthometric height as a Measurement.
  public var fpapOrthometricHeight: Measurement<UnitLength>? {
    fpapOrthometricHeightFt.map { .init(value: $0, unit: .feet) }
  }

  /// LTP orthometric height as a Measurement.
  public var ltpOrthometricHeight: Measurement<UnitLength>? {
    ltpOrthometricHeightFt.map { .init(value: $0, unit: .feet) }
  }

  /// Helicopter procedure course as a Measurement.
  public var helicopterProcedureCourseAngle: Measurement<UnitAngle>? {
    helicopterProcedureCourse.map { .init(value: $0, unit: .degrees) }
  }
}

// MARK: - Linked Properties

extension PathPoint {
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

  /// The associated runway.
  ///
  /// This property resolves the `runwayId` to the actual `Runway` object
  /// when linked via `CIFPData`.
  public var runway: Runway? {
    get async {
      guard let data else { return nil }
      return await data.runway(runwayId, airportId: airportId)
    }
  }

  /// The associated approach procedure.
  ///
  /// This property resolves the `approachId` to the actual `Approach` object
  /// when linked via `CIFPData`.
  public var approach: Approach? {
    get async {
      guard let data else { return nil }
      return await data.approach(approachId, airportId: airportId)
    }
  }
}
