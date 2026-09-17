import Foundation
import Testing

#if canImport(CoreLocation)
  import CoreLocation
#endif

@testable import SwiftCIFP

// MARK: - Coordinate Tests

@Suite
struct `Coordinate tests` {
  @Test
  func `stores latitude and longitude in degrees`() {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    #expect(coord.latitudeDeg == 33.9425)
    #expect(coord.longitudeDeg == -118.4081)
  }

  #if canImport(CoreLocation)
    @Test
    func `converts from a CoreLocation coordinate`() {
      let clCoord = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)
      let coord = Coordinate(clCoord)
      #expect(coord.latitudeDeg == 40.6413)
      #expect(coord.longitudeDeg == -73.7781)
    }

    @Test
    func `converts to a CoreLocation coordinate`() {
      let coord = Coordinate(latitudeDeg: 51.4700, longitudeDeg: -0.4543)
      let clCoord = coord.coreLocation
      #expect(clCoord.latitude == 51.4700)
      #expect(clCoord.longitude == -0.4543)
    }
  #endif

  @Test
  func `describes itself with hemisphere letters`() {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    #expect(coord.description.contains("N"))
    #expect(coord.description.contains("W"))
  }
}

// MARK: - CoordinateParser Tests

@Suite
struct `CoordinateParser tests` {
  @Test
  func `parses a northern latitude`() {
    // N38421448 = 38° 42' 14.48" N
    let bytes: [UInt8] = Array("N38421448".utf8)
    let lat = CoordinateParser.parseLatitude(bytes[...])
    #expect(lat != nil)
    if let lat {
      #expect(lat > 38.70 && lat < 38.71)
    }
  }

  @Test
  func `parses a southern latitude as negative`() {
    // S33563000 = 33° 56' 30.00" S = -33.9417
    let bytes: [UInt8] = Array("S33563000".utf8)
    let lat = CoordinateParser.parseLatitude(bytes[...])
    #expect(lat != nil)
    if let lat {
      #expect(lat < 0)
      #expect(abs(lat + 33.9417) < 0.001)
    }
  }

  @Test
  func `parses a western longitude as negative`() {
    // W118244500 = 118° 24' 45.00" W = -118.4125
    let bytes: [UInt8] = Array("W118244500".utf8)
    let lon = CoordinateParser.parseLongitude(bytes[...])
    #expect(lon != nil)
    if let lon {
      #expect(lon < 0)
      #expect(abs(lon + 118.4125) < 0.001)
    }
  }

  @Test
  func `parses an eastern longitude as positive`() {
    // E000274500 = 0° 27' 45.00" E = 0.4625
    let bytes: [UInt8] = Array("E000274500".utf8)
    let lon = CoordinateParser.parseLongitude(bytes[...])
    #expect(lon != nil)
    if let lon {
      #expect(lon > 0)
      #expect(abs(lon - 0.4625) < 0.001)
    }
  }

  @Test
  func `parses a combined latitude and longitude field`() {
    // N33564847W118244290 = 33.9467..° N, 118.4119..° W
    let bytes: [UInt8] = Array("N33564847W118244290".utf8)
    let coord = CoordinateParser.parseCoordinate(bytes[...])
    #expect(coord != nil)
    if let coord {
      #expect(coord.latitudeDeg > 33.94 && coord.latitudeDeg < 33.95)
      #expect(coord.longitudeDeg < -118.41 && coord.longitudeDeg > -118.42)
    }
  }

  @Test
  func `parses an east magnetic variation as positive`() {
    let bytes: [UInt8] = Array("E0130".utf8)
    let magVar = CoordinateParser.parseMagneticVariation(bytes[...])
    #expect(magVar != nil)
    if let magVar {
      #expect(magVar.direction == .east)
      #expect(magVar.degrees == 13.0)
      #expect(magVar.signedValue == 13.0)
    }
  }

  @Test
  func `parses a west magnetic variation as negative`() {
    let bytes: [UInt8] = Array("W0145".utf8)
    let magVar = CoordinateParser.parseMagneticVariation(bytes[...])
    #expect(magVar != nil)
    if let magVar {
      #expect(magVar.direction == .west)
      #expect(magVar.degrees == 14.5)
      #expect(magVar.signedValue == -14.5)
    }
  }

  @Test
  func `parses an altitude in feet MSL`() throws {
    let bytes: [UInt8] = Array("05000".utf8)
    let alt = try CoordinateParser.parseAltitude(bytes[...])
    if case let .feet(value, unit) = alt {
      #expect(value == 5000)
      #expect(unit == .msl)
    } else {
      Issue.record("Expected feet altitude")
    }
  }

  @Test
  func `parses a flight level altitude`() throws {
    let bytes: [UInt8] = Array("FL350".utf8)
    let alt = try CoordinateParser.parseAltitude(bytes[...])
    if case .flightLevel(let value) = alt {
      #expect(value == 350)
    } else {
      Issue.record("Expected flight level")
    }
  }

  @Test
  func `parses a course in tenths of a degree`() {
    let bytes: [UInt8] = Array("0900".utf8)
    let course = CoordinateParser.parseCourse(bytes[...])
    #expect(course != nil)
    #expect(course == 90.0)
  }

  @Test
  func `parses a distance in tenths of a nautical mile`() {
    let bytes: [UInt8] = Array("0150".utf8)
    let distance = CoordinateParser.parseDistance(bytes[...])
    #expect(distance != nil)
    #expect(distance == 15.0)
  }
}

// MARK: - ByteParsing Tests

@Suite
struct `ByteParsing tests` {
  @Test
  func `parses an integer with leading whitespace`() {
    let bytes: [UInt8] = Array("  123".utf8)
    let value = bytes[...].parseInt()
    #expect(value == 123)
  }

  @Test
  func `parses a negative integer`() {
    let bytes: [UInt8] = Array("-456".utf8)
    let value = bytes[...].parseInt()
    #expect(value == -456)
  }

  @Test
  func `parses an unsigned integer`() {
    let bytes: [UInt8] = Array("99999".utf8)
    let value = bytes[...].parseUInt()
    #expect(value == 99999)
  }

  @Test
  func `parses a double`() {
    let bytes: [UInt8] = Array("123.45".utf8)
    let value = bytes[...].parseDouble()
    #expect(value != nil)
    if let value {
      #expect(abs(value - 123.45) < 0.001)
    }
  }

  @Test
  func `trims whitespace when converting to a string`() {
    let bytes: [UInt8] = Array("  hello  ".utf8)
    let str = bytes[...].toString()
    #expect(str == "hello")
  }

  @Test
  func `preserves whitespace in a raw string`() {
    let bytes: [UInt8] = Array("P ".utf8)
    let str = bytes[...].toRawString()
    #expect(str == "P ")
  }

  @Test
  func `reports an all-whitespace slice as blank`() {
    let bytes: [UInt8] = Array("     ".utf8)
    #expect(bytes[...].isBlank())
  }

  @Test
  func `reports a slice with content as not blank`() {
    let bytes: [UInt8] = Array("  X  ".utf8)
    #expect(!bytes[...].isBlank())
  }

  @Test
  func `slices a byte range`() {
    let bytes: [UInt8] = Array("HELLO WORLD".utf8)
    let slice = bytes[...].slice(6..<11)
    #expect(slice.toString() == "WORLD")
  }

  @Test
  func `returns an empty slice for a range beginning past the end`() {
    let bytes: [UInt8] = Array("HELLO".utf8)
    #expect(bytes[...].slice(93..<123).isEmpty)
  }
}

// MARK: - Truncated Record Tests

@Suite
struct `truncated record handling` {
  @Test
  func `reports a truncated record through the error callback`() throws {
    // An airport record cut off just past its subsection code.
    let truncatedAirportRecord = "SUSAP KLAXK2A"
    var reportedErrors: [(error: any Error, line: Int?)] = []

    let cifp = try CIFP(
      data: Data(truncatedAirportRecord.utf8),
      errorCallback: { error, line in reportedErrors.append((error, line)) }
    )

    #expect(cifp.airports.isEmpty)
    #expect(reportedErrors.count == 1)
    #expect(reportedErrors.first?.line == 1)

    let error = try #require(reportedErrors.first?.error as? CIFPError)
    guard case let .missingRequiredField(field, recordType, _) = error else {
      Issue.record("Expected a missing required field error")
      return
    }
    #expect(field == "coordinate")
    #expect(recordType == "Airport")
  }
}

// MARK: - NDB Identifier Collision Tests

@Suite
struct `NDB navaids sharing an identifier` {
  /// Two beacons from the FAA distribution that both answer to `IL`, in different ICAO
  /// regions. Joined with CRLF to match the line endings the distribution ships.
  private static let collidingRecords = [
    "SUSADB       IL    K4002780HOLW N31012674W097422925                       E0050           NARIRESH                         270261811",
    "SUSADB       IL    K5004070HOMW N39293492W083441745                       W0070           NARAIRBO                         270272106"
  ].joined(separator: "\r\n")

  private static func parseCollidingRecords() throws -> CIFP {
    try CIFP(data: Data(collidingRecords.utf8))
  }

  @Test
  func `keeps every beacon that shares the identifier`() throws {
    let cifp = try Self.parseCollidingRecords()

    #expect(cifp.ndbNavaids["IL"]?.count == 2)
    #expect(cifp.ndbNavaidCount == 2)
  }

  @Test
  func `selects a beacon by ICAO region`() throws {
    let cifp = try Self.parseCollidingRecords()

    #expect(cifp.ndbNavaid("IL", icaoRegion: "K4")?.icaoRegion == "K4")
    #expect(cifp.ndbNavaid("IL", icaoRegion: "K5")?.icaoRegion == "K5")
    #expect(cifp.ndbNavaid("IL", icaoRegion: "K9") == nil)
  }
}

// MARK: - Altitude Tests

@Suite
struct `Altitude tests` {
  @Test
  func `reports a feet altitude and its datum`() {
    let alt = Altitude.feet(1000, .msl)
    #expect(alt.feetValue == 1000)
    #expect(alt.datum == .msl)
  }

  @Test
  func `converts a feet altitude to meters`() {
    let alt = Altitude.feet(1000, .msl)
    if let measurement = alt.measurement {
      // 1000 feet in meters is approximately 304.8
      let meters = measurement.converted(to: UnitLength.meters).value
      #expect(abs(meters - 304.8) < 1)
    } else {
      Issue.record("Expected measurement")
    }
  }

  @Test
  func `converts a flight level to feet`() {
    let alt = Altitude.flightLevel(350)
    #expect(alt.feetValue == 35000)
  }

  @Test
  func `reports no feet value for a ground altitude`() {
    let alt = Altitude.ground
    #expect(alt.feetValue == nil)
  }
}

// MARK: - Cycle Tests

@Suite
struct `Cycle tests` {
  @Test
  func `parses a YYMM cycle identifier`() {
    let cycle = Cycle(yymm: "2601")
    #expect(cycle != nil)
    if let cycle {
      #expect(cycle.year == 2026)
      #expect(cycle.cycleNumber == 1)
    }
  }

  @Test
  func `resolves the effective date to the correct UTC calendar day`() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt

    // AIRAC cycle boundaries are defined in UTC; the resolved date must land on the exact
    // UTC calendar day regardless of the host's local timezone.
    let referenceCycle = try #require(Cycle(yymm: "2401"))
    let referenceDate = try #require(referenceCycle.effectiveDate)
    #expect(
      calendar.dateComponents([.year, .month, .day], from: referenceDate)
        == DateComponents(year: 2024, month: 1, day: 25)
    )

    let cycle = try #require(Cycle(yymm: "2605"))
    let effectiveDate = try #require(cycle.effectiveDate)
    #expect(
      calendar.dateComponents([.year, .month, .day], from: effectiveDate)
        == DateComponents(year: 2026, month: 5, day: 14)
    )
  }

  @Test
  func `navigates to the next and previous cycles across a year boundary`() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle {
      #expect(cycle.next?.cycleNumber == 2)
      #expect(cycle.next?.year == 2025)
      #expect(cycle.previous?.cycleNumber == 13)
      #expect(cycle.previous?.year == 2024)
    }
  }

  @Test
  func `returns the currently effective cycle`() {
    let effective = Cycle.effective
    #expect(effective.isEffective)
    #expect(effective.cycleNumber >= 1 && effective.cycleNumber <= 13)
  }

  @Test
  func `finds the cycle covering a given date`() {
    // Use the reference date (Jan 25, 2024 is cycle 2401)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let refDate = calendar.date(
      from: DateComponents(timeZone: .gmt, year: 2024, month: 1, day: 25)
    )!

    let cycle = Cycle.cycle(for: refDate)
    #expect(cycle != nil)
    #expect(cycle?.year == 2024)
    #expect(cycle?.cycleNumber == 1)
  }

  @Test
  func `covers a 28-day date range`() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle {
      let dateRange = cycle.dateRange
      #expect(dateRange != nil)

      // Duration should be 28 days
      let expectedDuration: TimeInterval = 28 * 24 * 60 * 60
      #expect(dateRange?.duration == expectedDuration)
    }
  }

  @Test
  func `contains a date inside the cycle`() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle, let effectiveDate = cycle.effectiveDate {
      // A date 14 days into the cycle should be contained
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = .gmt
      let midCycleDate = calendar.date(byAdding: .day, value: 14, to: effectiveDate)!
      #expect(cycle.contains(midCycleDate))
    }
  }

  @Test
  func `does not contain a date past the cycle`() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle, let effectiveDate = cycle.effectiveDate {
      // A date 30 days after the effective date should not be contained
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = .gmt
      let afterDate = calendar.date(byAdding: .day, value: 30, to: effectiveDate)!
      #expect(!cycle.contains(afterDate))
    }
  }

  @Test
  func `expires at the next cycle's effective date`() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle {
      let expirationDate = cycle.expirationDate
      #expect(expirationDate != nil)

      // expirationDate should equal next cycle's effectiveDate
      #expect(expirationDate == cycle.next?.effectiveDate)
    }
  }

  @Test
  func `orders cycles chronologically`() {
    let older = Cycle(yymm: "2501")
    let newer = Cycle(yymm: "2502")
    let same = Cycle(yymm: "2501")
    #expect(older != nil && newer != nil && same != nil)
    if let older, let newer, let same {
      #expect(older < newer)
      #expect(newer > older)
      #expect(older == same)
    }
  }

  @Test
  func `reports the effective cycle as effective`() {
    let effective = Cycle.effective
    #expect(effective.isEffective)

    // A past cycle should not be effective
    let past = Cycle(yymm: "2401")
    #expect(past != nil)
    // Past cycle may or may not be effective depending on when test runs
    _ = past?.isEffective
  }
}

// MARK: - PathTerminator Tests

@Suite
struct `PathTerminator tests` {
  @Test
  func `maps raw values to path terminators`() {
    let tf = PathTerminator(rawValue: "TF")
    #expect(tf == .trackToFix)

    let cf = PathTerminator(rawValue: "CF")
    #expect(cf == .courseToFix)

    let df = PathTerminator(rawValue: "DF")
    #expect(df == .directToFix)
  }

  @Test
  func `returns nil for an unknown raw value`() {
    let unknown = PathTerminator(rawValue: "XX")
    #expect(unknown == nil)
  }
}

// MARK: - Model Codable Tests

@Suite
struct `Codable tests` {
  @Test
  func `round-trips a coordinate`() throws {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    let data = try JSONEncoder().encode(coord)
    let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
    #expect(decoded.latitude == coord.latitude)
    #expect(decoded.longitude == coord.longitude)
  }

  @Test
  func `round-trips every altitude case`() throws {
    let altitudes: [Altitude] = [.feet(5000, .msl), .feet(1000, .agl), .flightLevel(350), .ground]
    for alt in altitudes {
      let data = try JSONEncoder().encode(alt)
      let decoded = try JSONDecoder().decode(Altitude.self, from: data)
      #expect(decoded == alt)
    }
  }

  @Test
  func `round-trips a magnetic variation`() throws {
    let magVar = MagneticVariation(direction: .west, degrees: 14.5)
    let data = try JSONEncoder().encode(magVar)
    let decoded = try JSONDecoder().decode(MagneticVariation.self, from: data)
    #expect(decoded.direction == magVar.direction)
    #expect(decoded.degrees == magVar.degrees)
  }
}

// MARK: - ByteInitializable Tests

@Suite
struct `ByteInitializable tests` {
  @Test
  func `initializes RecordType from a byte`() {
    #expect(RecordType(byte: 0x53) == .standard)
    #expect(RecordType(byte: 0x48) == .header)
    #expect(RecordType(byte: 0x54) == .tailored)
  }

  @Test
  func `initializes TurnDirection from a byte`() {
    #expect(TurnDirection(byte: 0x4C) == .left)
    #expect(TurnDirection(byte: 0x52) == .right)
  }

  @Test
  func `initializes ILSCategory from a byte`() {
    #expect(ILSCategory(byte: 0x31) == .catI)
    #expect(ILSCategory(byte: 0x32) == .catII)
  }
}

// MARK: - Fix Tests

@Suite
struct `Fix tests` {
  @Test
  func `reports the identifier and coordinate of a VHF navaid fix`() {
    let navaid = VHFNavaid(
      identifier: "LAX",
      icaoRegion: "K2",
      frequencyMHz: 113.6,
      navaidClass: .vorDME,
      usageClass: nil,
      vorCoordinate: Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081),
      dmeCoordinate: nil,
      stationDeclinationDeg: 14.0,
      dmeElevationFt: nil,
      figureOfMerit: nil,
      ilsDMEBiasNM: nil,
      name: "Los Angeles"
    )
    let fix = Fix.vhfNavaid(navaid)
    #expect(fix.identifier == "LAX")
    #expect(fix.coordinate?.latitudeDeg == 33.9425)
  }

  @Test
  func `reports the identifier of an NDB navaid fix`() {
    let ndb = NDBNavaid(
      identifier: "SLI",
      icaoRegion: "K2",
      frequencyKHz: 365,
      ndbClass: .mediumHighPower,
      coordinate: Coordinate(latitudeDeg: 33.78, longitudeDeg: -118.05),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "Seal Beach"
    )
    let fix = Fix.ndbNavaid(ndb)
    #expect(fix.identifier == "SLI")
  }

  @Test
  func `reports the identifier of an enroute waypoint fix`() {
    let waypoint = EnrouteWaypoint(
      identifier: "DAGGR",
      icaoRegion: "K2",
      waypointType: .rnav,
      usageClass: nil,
      coordinate: Coordinate(latitudeDeg: 34.0, longitudeDeg: -118.0),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "DAGGR"
    )
    let fix = Fix.enrouteWaypoint(waypoint)
    #expect(fix.identifier == "DAGGR")
  }

  @Test
  func `reports the identifier of a terminal waypoint fix`() {
    let waypoint = TerminalWaypoint(
      airportId: "KLAX",
      icaoRegion: "K2",
      identifier: "LIMMA",
      waypointICAO: "K2",
      waypointType: .rnav,
      waypointUsage: nil,
      coordinate: Coordinate(latitudeDeg: 33.95, longitudeDeg: -118.35),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "LIMMA"
    )
    let fix = Fix.terminalWaypoint(waypoint)
    #expect(fix.identifier == "LIMMA")
  }
}

// MARK: - Navaid Tests

@Suite
struct `Navaid tests` {
  @Test
  func `reports the identifier of a VHF navaid`() {
    let navaid = VHFNavaid(
      identifier: "SLI",
      icaoRegion: "K2",
      frequencyMHz: 115.7,
      navaidClass: .vorDME,
      usageClass: nil,
      vorCoordinate: Coordinate(latitudeDeg: 33.78, longitudeDeg: -118.05),
      dmeCoordinate: nil,
      stationDeclinationDeg: 14.0,
      dmeElevationFt: nil,
      figureOfMerit: nil,
      ilsDMEBiasNM: nil,
      name: "Seal Beach"
    )
    let nav = Navaid.vhf(navaid)
    #expect(nav.identifier == "SLI")
  }

  @Test
  func `reports the identifier of an NDB navaid`() {
    let ndb = NDBNavaid(
      identifier: "ABC",
      icaoRegion: "K2",
      frequencyKHz: 400,
      ndbClass: .mediumHighPower,
      coordinate: Coordinate(latitudeDeg: 34.0, longitudeDeg: -118.0),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "Test NDB"
    )
    let nav = Navaid.ndb(ndb)
    #expect(nav.identifier == "ABC")
  }
}

// MARK: - Runway Transition Tests

@Suite
struct `runway transition expansion` {
  @Test
  func `passes a plain runway transition through unchanged`() {
    let result = expandRunwayTransitionId("RW15")
    #expect(result == ["RW15"])
  }

  @Test
  func `passes an L or R suffix through unchanged`() {
    let resultL = expandRunwayTransitionId("RW24L")
    #expect(resultL == ["RW24L"])
    let resultR = expandRunwayTransitionId("RW24R")
    #expect(resultR == ["RW24R"])
  }

  @Test
  func `expands a B suffix into L and R`() {
    let result = expandRunwayTransitionId("RW24B")
    #expect(Set(result) == ["RW24L", "RW24R"])
  }

  @Test
  func `expands a B suffix on a zero-padded runway number`() {
    let result = expandRunwayTransitionId("RW06B")
    #expect(Set(result) == ["RW06L", "RW06R"])
  }
}

@Suite
struct `SID runway names` {
  @Test
  func `stores runway names in the Runway.name format`() {
    let sid = SID(
      airportId: "KASE",
      icaoRegion: "K2",
      identifier: "PITKN5",
      routeType: .rnavRunwayTransition,
      transitionId: "RW33",
      runwayNames: ["RW33"],
      legs: []
    )
    #expect(sid.runwayNames.contains("RW33"))
    #expect(sid.runwayNames.count == 1)
  }

  @Test
  func `stores every runway name expanded from a B suffix`() {
    let sid = SID(
      airportId: "KLAX",
      icaoRegion: "K2",
      identifier: "VTU8",
      routeType: .rnavCommonRoute,
      transitionId: nil,
      runwayNames: ["RW06L", "RW06R", "RW24L", "RW24R"],
      legs: []
    )
    #expect(sid.runwayNames.count == 4)
    #expect(sid.runwayNames.contains("RW24L"))
    #expect(sid.runwayNames.contains("RW24R"))
  }
}

@Suite
struct `STAR runway names` {
  @Test
  func `stores runway names in the Runway.name format`() {
    let star = STAR(
      airportId: "KLAX",
      icaoRegion: "K2",
      identifier: "SADDE6",
      routeType: .rnavRunwayTransition,
      transitionId: "RW24L",
      runwayNames: ["RW24L", "RW24R"],
      legs: []
    )
    #expect(star.runwayNames.contains("RW24L"))
    #expect(star.runwayNames.contains("RW24R"))
  }
}

// MARK: - CIFPData Tests

@Suite
struct `CIFPData tests` {

  private static func ndbNavaid(region: String) -> NDBNavaid {
    .init(
      identifier: "IL",
      icaoRegion: region,
      frequencyKHz: 278,
      ndbClass: .mediumHighPower,
      coordinate: Coordinate(latitudeDeg: 31.02, longitudeDeg: -97.71),
      magneticVariation: MagneticVariation(direction: .east, degrees: 5.0),
      name: "IRESH"
    )
  }
  @Test
  func `resolves a VHF navaid fix`() async {
    let navaid = VHFNavaid(
      identifier: "LAX",
      icaoRegion: "K2",
      frequencyMHz: 113.6,
      navaidClass: .vorDME,
      usageClass: nil,
      vorCoordinate: Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081),
      dmeCoordinate: nil,
      stationDeclinationDeg: 14.0,
      dmeElevationFt: nil,
      figureOfMerit: nil,
      ilsDMEBiasNM: nil,
      name: "Los Angeles"
    )

    let data = CIFPData(
      vhfNavaids: ["LAX": navaid],
      ndbNavaids: [:],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix("LAX", icaoRegion: nil, sectionCode: .vhfNavaid, airportId: nil)
    #expect(fix != nil)
    if case .vhfNavaid(let resolved) = fix {
      #expect(resolved.identifier == "LAX")
    } else {
      Issue.record("Expected VHF navaid fix")
    }
  }

  @Test
  func `resolves an NDB navaid fix`() async {
    let ndb = NDBNavaid(
      identifier: "SLI",
      icaoRegion: "K2",
      frequencyKHz: 365,
      ndbClass: .mediumHighPower,
      coordinate: Coordinate(latitudeDeg: 33.78, longitudeDeg: -118.05),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "Seal Beach"
    )

    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: ["SLI": [ndb]],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix(
      "SLI",
      icaoRegion: "K2",
      sectionCode: .ndbNavaid,
      airportId: nil
    )
    #expect(fix != nil)
    if case .ndbNavaid(let resolved) = fix {
      #expect(resolved.identifier == "SLI")
    } else {
      Issue.record("Expected NDB navaid fix")
    }
  }

  @Test
  func `resolves a shared NDB identifier by region`() async {
    let data = CIFPData(ndbNavaids: [
      "IL": [Self.ndbNavaid(region: "K4"), Self.ndbNavaid(region: "K5")]
    ])

    let fix = await data.resolveFix("IL", icaoRegion: "K5", sectionCode: .ndbNavaid, airportId: nil)
    if case .ndbNavaid(let resolved) = fix {
      #expect(resolved.icaoRegion == "K5")
    } else {
      Issue.record("Expected NDB navaid fix")
    }
  }

  @Test
  func `refuses to resolve a shared NDB identifier with no region`() async {
    let data = CIFPData(ndbNavaids: [
      "IL": [Self.ndbNavaid(region: "K4"), Self.ndbNavaid(region: "K5")]
    ])

    let fix = await data.resolveFix("IL", icaoRegion: nil, sectionCode: .ndbNavaid, airportId: nil)
    #expect(fix == nil)
  }

  @Test
  func `resolves an unambiguous NDB identifier with no region`() async {
    let data = CIFPData(ndbNavaids: ["IL": [Self.ndbNavaid(region: "K4")]])

    let fix = await data.resolveFix("IL", icaoRegion: nil, sectionCode: .ndbNavaid, airportId: nil)
    if case .ndbNavaid(let resolved) = fix {
      #expect(resolved.icaoRegion == "K4")
    } else {
      Issue.record("Expected NDB navaid fix")
    }
  }

  @Test
  func `resolves an enroute waypoint fix`() async {
    let waypoint = EnrouteWaypoint(
      identifier: "DAGGR",
      icaoRegion: "K2",
      waypointType: .rnav,
      usageClass: nil,
      coordinate: Coordinate(latitudeDeg: 34.0, longitudeDeg: -118.0),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "DAGGR"
    )

    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: [:],
      enrouteWaypoints: ["DAGGR": waypoint],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix(
      "DAGGR",
      icaoRegion: nil,
      sectionCode: .enrouteWaypoint,
      airportId: nil
    )
    #expect(fix != nil)
    if case .enrouteWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "DAGGR")
    } else {
      Issue.record("Expected enroute waypoint fix")
    }
  }

  @Test
  func `resolves a terminal waypoint fix`() async {
    let waypoint = TerminalWaypoint(
      airportId: "KLAX",
      icaoRegion: "K2",
      identifier: "LIMMA",
      waypointICAO: "K2",
      waypointType: .rnav,
      waypointUsage: nil,
      coordinate: Coordinate(latitudeDeg: 33.95, longitudeDeg: -118.35),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "LIMMA"
    )

    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: [:],
      enrouteWaypoints: [:],
      terminalWaypoints: [waypoint]
    )

    let fix = await data.resolveFix(
      "LIMMA",
      icaoRegion: nil,
      sectionCode: .terminalWaypoint,
      airportId: "KLAX"
    )
    #expect(fix != nil)
    if case .terminalWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "LIMMA")
      #expect(resolved.airportId == "KLAX")
    } else {
      Issue.record("Expected terminal waypoint fix")
    }
  }

  @Test
  func `resolves a fix without a section code`() async {
    let waypoint = EnrouteWaypoint(
      identifier: "DAGGR",
      icaoRegion: "K2",
      waypointType: .rnav,
      usageClass: nil,
      coordinate: Coordinate(latitudeDeg: 34.0, longitudeDeg: -118.0),
      magneticVariation: MagneticVariation(direction: .east, degrees: 14.0),
      name: "DAGGR"
    )

    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: [:],
      enrouteWaypoints: ["DAGGR": waypoint],
      terminalWaypoints: []
    )

    // Without section code, should still find the waypoint
    let fix = await data.resolveFix("DAGGR", icaoRegion: nil, sectionCode: nil, airportId: nil)
    #expect(fix != nil)
    if case .enrouteWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "DAGGR")
    } else {
      Issue.record("Expected enroute waypoint fix")
    }
  }

  @Test
  func `resolves a navaid by section code`() async {
    let navaid = VHFNavaid(
      identifier: "LAX",
      icaoRegion: "K2",
      frequencyMHz: 113.6,
      navaidClass: .vorDME,
      usageClass: nil,
      vorCoordinate: Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081),
      dmeCoordinate: nil,
      stationDeclinationDeg: 14.0,
      dmeElevationFt: nil,
      figureOfMerit: nil,
      ilsDMEBiasNM: nil,
      name: "Los Angeles"
    )

    let data = CIFPData(
      vhfNavaids: ["LAX": navaid],
      ndbNavaids: [:],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let resolved = await data.resolveNavaid("LAX", icaoRegion: nil, sectionCode: "D")
    #expect(resolved != nil)
    if case .vhf(let vhf) = resolved {
      #expect(vhf.identifier == "LAX")
    } else {
      Issue.record("Expected VHF navaid")
    }
  }

  @Test
  func `returns nil for an unknown fix`() async {
    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: [:],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix("UNKNOWN", icaoRegion: nil, sectionCode: nil, airportId: nil)
    #expect(fix == nil)
  }
}
