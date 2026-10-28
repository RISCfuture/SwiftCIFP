public import Foundation

/// A fix/waypoint along an airway.
public struct AirwayFix: Sendable, Codable, Equatable, Hashable {

  // MARK: - Linking Properties

  /// Closure for resolving fix identifiers (injected by parent airway).
  var findFix: FixResolver?

  /// Sequence number of this fix in the airway.
  public let sequenceNumber: Int

  /// Fix/waypoint identifier.
  public let fixId: String

  /// ICAO region code of the fix.
  public let fixICAO: String

  /// Section code indicating the fix type.
  public let fixSectionCode: SectionCode?

  /// Boundary code (for FIR/UIR boundaries).
  public let boundaryCode: String?

  /// The direction this segment may be flown in, or nil if either.
  public let directionRestriction: DirectionRestriction?

  /// Outbound magnetic course from this fix in degrees.
  public let outboundCourseDeg: Double?

  /// Distance to next fix in nautical miles.
  public let distanceNM: Double?

  /// Inbound magnetic course to this fix in degrees.
  public let inboundCourseDeg: Double?

  /// Minimum altitude for this segment.
  public let minimumAltitude: Altitude?

  /// Alternate minimum altitude (for directional variation or MEA gap).
  public let alternateMinimumAltitude: Altitude?

  /// Maximum altitude for this segment.
  public let maximumAltitude: Altitude?

  /// Creates an AirwayFix.
  init(
    sequenceNumber: Int,
    fixId: String,
    fixICAO: String,
    fixSectionCode: SectionCode?,
    boundaryCode: String?,
    directionRestriction: DirectionRestriction?,
    outboundCourseDeg: Double?,
    distanceNM: Double?,
    inboundCourseDeg: Double?,
    minimumAltitude: Altitude?,
    alternateMinimumAltitude: Altitude?,
    maximumAltitude: Altitude?
  ) {
    self.sequenceNumber = sequenceNumber
    self.fixId = fixId
    self.fixICAO = fixICAO
    self.fixSectionCode = fixSectionCode
    self.boundaryCode = boundaryCode
    self.directionRestriction = directionRestriction
    self.outboundCourseDeg = outboundCourseDeg
    self.distanceNM = distanceNM
    self.inboundCourseDeg = inboundCourseDeg
    self.minimumAltitude = minimumAltitude
    self.alternateMinimumAltitude = alternateMinimumAltitude
    self.maximumAltitude = maximumAltitude
  }

  // MARK: - Equatable & Hashable

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.sequenceNumber == rhs.sequenceNumber && lhs.fixId == rhs.fixId && lhs.fixICAO == rhs.fixICAO
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(sequenceNumber)
    hasher.combine(fixId)
    hasher.combine(fixICAO)
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case sequenceNumber, fixId, fixICAO, fixSectionCode
    case boundaryCode, directionRestriction, outboundCourseDeg
    case distanceNM, inboundCourseDeg, minimumAltitude
    case alternateMinimumAltitude, maximumAltitude
    // Note: 'findFix' is excluded
  }
}

// MARK: - Direction Restriction

extension AirwayFix {
  /// A one-way restriction on an airway segment (ARINC 424 field 5.115).
  public enum DirectionRestriction: Character, Sendable, Codable, CaseIterable,
    ByteInitializable
  {
    /// One way, in the direction the airway is coded.
    case forward = "F"

    /// One way, opposite the direction the airway is coded.
    case backward = "B"
  }
}

// MARK: - AirwayFix Measurement Extensions

extension AirwayFix {
  /// Outbound magnetic course as a Measurement.
  public var outboundCourse: Measurement<UnitAngle>? {
    outboundCourseDeg.map { .init(value: $0, unit: .degrees) }
  }

  /// Distance to next fix as a Measurement.
  public var distance: Measurement<UnitLength>? {
    distanceNM.map { .init(value: $0, unit: .nauticalMiles) }
  }

  /// Inbound magnetic course as a Measurement.
  public var inboundCourse: Measurement<UnitAngle>? {
    inboundCourseDeg.map { .init(value: $0, unit: .degrees) }
  }
}

// MARK: - Comparable

extension AirwayFix: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.sequenceNumber < rhs.sequenceNumber
  }
}

// MARK: - AirwayFix Linked Properties

extension AirwayFix {
  /// The resolved fix for this airway point.
  ///
  /// This property uses the injected resolver to find the actual fix object
  /// based on the `fixId` and `fixSectionCode`.
  public var fix: Fix? {
    get async {
      guard let findFix else { return nil }
      // Airway fixes are enroute, not terminal, so no airportId needed
      return await findFix(fixId, fixICAO, fixSectionCode, nil)
    }
  }
}

/// Airway record.
///
/// Airways are named routes between navigation fixes used for
/// instrument flight navigation.
public struct Airway: Sendable, Codable, AirwayLinkable {

  // MARK: - CIFPDataLinkable

  /// Reference to the parent CIFPData container for model linking.
  public weak var data: CIFPData?

  /// The airway identifier (e.g., "V1", "J60", "Q105").
  public let identifier: String

  /// Route type (conventional, RNAV, etc.).
  public let routeType: RouteType

  /// Altitude structure (high, low, or both), if published.
  public let level: Level?

  /// Sequence of fixes along the airway.
  public internal(set) var fixes: [AirwayFix]

  /// Total length of the airway in nautical miles.
  public var totalDistanceNM: Double {
    fixes.compactMap(\.distanceNM).reduce(0, +)
  }

  /// Total length of the airway as a Measurement.
  public var totalDistance: Measurement<UnitLength> {
    .init(value: totalDistanceNM, unit: .nauticalMiles)
  }

  /// Creates an Airway record.
  init(
    identifier: String,
    routeType: RouteType,
    level: Level?,
    fixes: [AirwayFix]
  ) {
    self.identifier = identifier
    self.routeType = routeType
    self.level = level
    self.fixes = fixes
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case identifier, routeType, level, fixes
    // Note: 'data' is excluded
  }
}

// MARK: - Route Type and Level

extension Airway {
  /// The kind of airway (ARINC 424 field 5.7).
  public enum RouteType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// Airline airway (tailored data).
    case airline = "A"

    /// Control airway.
    case control = "C"

    /// Direct route.
    case direct = "D"

    /// Helicopter airway.
    case helicopter = "H"

    /// Officially designated airway, other than an RNAV or helicopter airway.
    case officiallyDesignated = "O"

    /// RNAV airway.
    case rnav = "R"

    /// Undesignated ATS route.
    case undesignatedATSRoute = "S"
  }

  /// The altitude structure an airway belongs to (ARINC 424 field 5.19).
  public enum Level: Character, Sendable, Codable, CaseIterable, ByteInitializable {
    /// All altitudes.
    case all = "B"

    /// High-level airway.
    case high = "H"

    /// Low-level airway.
    case low = "L"
  }
}

// MARK: - AirwayLinkable

extension Airway {
  /// Injects fix resolver closures into the airway's fixes.
  mutating func injectFixResolvers(findFix: @escaping FixResolver) {
    // Inject into all fixes
    for i in fixes.indices {
      fixes[i].findFix = findFix
    }
  }
}

// MARK: - Identifiable, Equatable, Hashable

extension Airway: Identifiable, Equatable, Hashable {
  public var id: String { identifier }

  public static func == (lhs: Airway, rhs: Airway) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
