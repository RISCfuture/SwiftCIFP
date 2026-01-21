import CoreLocation
import Foundation

/// Airport reference record.
///
/// Contains basic airport information including location, elevation,
/// and operational characteristics.
///
/// ## Airport Identifiers
///
/// Airports use several identification systems:
///
/// - **ICAO code**: A 4-letter code assigned by the International Civil Aviation
///   Organization (e.g., "KLAX" for Los Angeles International). In the US, ICAO codes
///   begin with "K" for continental airports and "P" for airports in Alaska and Hawaii.
///   Smaller airports often lack ICAO codes.
///
/// - **IATA designator**: A 3-letter code used by the airline industry for ticketing
///   and baggage handling (e.g., "LAX"). Available via ``iataDesignator``. Only airports
///   with scheduled airline service are assigned IATA designators.
///
/// - **FAA LID**: The FAA Location Identifier, a 3–4 character alphanumeric code
///   assigned to US airports (e.g., "LAX", "L88"). Available via ``faaLID``. Every
///   public airport in the US has an FAA LID; it may or may not be the same as its
///   ICAO code without the leading "K".
///
/// The ``id`` property contains the identifier used in CIFP/ARINC 424 data, which is
/// the ICAO code when one exists, or the FAA LID otherwise. This means `id` may be
/// "KLAX" for Los Angeles International but "L88" for New Cuyama (which has no ICAO
/// code). Airport lookups in ``CIFP`` and ``CIFPData`` use this identifier as the
/// dictionary key.
public struct Airport: Sendable, Codable, CIFPDataLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// Airport identifier (ICAO code or FAA-assigned identifier).
  public let id: String

  /// ICAO region code.
  public let icaoRegion: String

  /// FAA identifier (may differ from ICAO).
  public let faaLID: String?

  /// IATA designator (3 characters).
  public let iataDesignator: String?

  /// Airport reference point coordinate.
  public let location: Coordinate

  /// Magnetic variation at airport.
  public let magneticVariation: MagneticVariation

  /// Airport elevation in feet MSL.
  public let elevationFt: Int

  /// Longest runway length in feet.
  public let longestRunwayLengthFt: Int?

  /// Longest runway surface type.
  public let longestRunwaySurface: RunwaySurface?

  /// Whether the airport supports IFR operations.
  public let isIFRCapable: Bool

  /// Speed limit in knots (typically at or below an altitude).
  public let speedLimitKts: Int?

  /// Transition altitude in feet.
  public let transitionAltitudeFt: Int?

  /// Transition level (flight level).
  public let transitionLevel: Int?

  /// Public/military status.
  public let publicMilitary: PublicMilitary?

  /// Reference system for bearings (magnetic or true north).
  public let bearingReference: BearingReference

  /// Geodetic datum for coordinate reference.
  public let datumCode: DatumCode?

  /// Airport name.
  public let name: String

  // MARK: - Child Collections (populated during linking)

  /// Runways at this airport.
  public internal(set) var runways: [Runway] = []

  /// Terminal waypoints at this airport.
  public internal(set) var terminalWaypoints: [TerminalWaypoint] = []

  /// Terminal navaids at this airport.
  public internal(set) var terminalNavaids: [TerminalNavaid] = []

  /// Localizer/glide slope records at this airport.
  public internal(set) var localizers: [LocalizerGlideSlope] = []

  /// Path point records at this airport.
  public internal(set) var pathPoints: [PathPoint] = []

  /// MSA records at this airport.
  public internal(set) var msaRecords: [MSA] = []

  /// SID procedures at this airport.
  public internal(set) var sids: [SID] = []

  /// STAR procedures at this airport.
  public internal(set) var stars: [STAR] = []

  /// Approach procedures at this airport.
  public internal(set) var approaches: [Approach] = []

  /// Creates an Airport record.
  init(
    id: String,
    icaoRegion: String,
    faaId: String?,
    iataDesignator: String?,
    coordinate: Coordinate,
    magneticVariation: MagneticVariation,
    elevationFt: Int,
    longestRunwayLengthFt: Int?,
    longestRunwaySurface: RunwaySurface?,
    isIFRCapable: Bool,
    speedLimitKts: Int?,
    transitionAltitudeFt: Int?,
    transitionLevel: Int?,
    publicMilitary: PublicMilitary?,
    bearingReference: BearingReference,
    datumCode: DatumCode?,
    name: String
  ) {
    self.id = id
    self.icaoRegion = icaoRegion
    self.faaLID = faaId
    self.iataDesignator = iataDesignator
    self.location = coordinate
    self.magneticVariation = magneticVariation
    self.elevationFt = elevationFt
    self.longestRunwayLengthFt = longestRunwayLengthFt
    self.longestRunwaySurface = longestRunwaySurface
    self.isIFRCapable = isIFRCapable
    self.speedLimitKts = speedLimitKts
    self.transitionAltitudeFt = transitionAltitudeFt
    self.transitionLevel = transitionLevel
    self.publicMilitary = publicMilitary
    self.bearingReference = bearingReference
    self.datumCode = datumCode
    self.name = name
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case id, icaoRegion, faaLID, iataDesignator, location
    case magneticVariation, elevationFt, longestRunwayLengthFt
    case longestRunwaySurface, isIFRCapable, speedLimitKts
    case transitionAltitudeFt, transitionLevel
    case publicMilitary, bearingReference, datumCode, name
    case runways, terminalWaypoints, terminalNavaids, localizers
    case pathPoints, msaRecords, sids, stars, approaches
    // Note: 'data' is excluded to avoid encoding the weak reference
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension Airport: Identifiable, Equatable, Hashable {
  public static func == (lhs: Airport, rhs: Airport) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension Airport: CustomStringConvertible {
  public var description: String {
    "\(id) - \(name)"
  }
}

// MARK: - Measurement Extensions

extension Airport {
  /// Airport elevation as a Measurement.
  public var elevation: Measurement<UnitLength> {
    .init(value: Double(elevationFt), unit: .feet)
  }

  /// Longest runway length as a Measurement.
  public var longestRunwayLength: Measurement<UnitLength>? {
    longestRunwayLengthFt.map { .init(value: Double($0), unit: .feet) }
  }

  /// Speed limit as a Measurement.
  public var speedLimit: Measurement<UnitSpeed>? {
    speedLimitKts.map { .init(value: Double($0), unit: .knots) }
  }

  /// Transition altitude as a Measurement.
  public var transitionAltitude: Measurement<UnitLength>? {
    transitionAltitudeFt.map { .init(value: Double($0), unit: .feet) }
  }
}
