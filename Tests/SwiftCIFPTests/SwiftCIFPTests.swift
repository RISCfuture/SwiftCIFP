import CoreLocation
import Foundation
import Testing

@testable import SwiftCIFP

// MARK: - Coordinate Tests

@Suite("Coordinate")
struct CoordinateTests {
  @Test("Coordinate initialization")
  func initialization() {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    #expect(coord.latitudeDeg == 33.9425)
    #expect(coord.longitudeDeg == -118.4081)
  }

  @Test("Coordinate from CoreLocation")
  func fromCoreLocation() {
    let clCoord = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)
    let coord = Coordinate(clCoord)
    #expect(coord.latitudeDeg == 40.6413)
    #expect(coord.longitudeDeg == -73.7781)
  }

  @Test("Coordinate to CoreLocation")
  func toCoreLocation() {
    let coord = Coordinate(latitudeDeg: 51.4700, longitudeDeg: -0.4543)
    let clCoord = coord.coreLocation
    #expect(clCoord.latitude == 51.4700)
    #expect(clCoord.longitude == -0.4543)
  }

  @Test("Coordinate description")
  func description() {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    #expect(coord.description.contains("N"))
    #expect(coord.description.contains("W"))
  }
}

// MARK: - CoordinateParser Tests

@Suite("CoordinateParser")
struct CoordinateParserTests {
  @Test("Parse latitude - north")
  func parseLatitudeNorth() {
    // N38421448 = 38° 42' 14.48" N
    let bytes: [UInt8] = Array("N38421448".utf8)
    let lat = CoordinateParser.parseLatitude(bytes[...])
    #expect(lat != nil)
    if let lat {
      #expect(lat > 38.70 && lat < 38.71)
    }
  }

  @Test("Parse latitude - south")
  func parseLatitudeSouth() {
    // S33563000 = 33° 56' 30.00" S = -33.9417
    let bytes: [UInt8] = Array("S33563000".utf8)
    let lat = CoordinateParser.parseLatitude(bytes[...])
    #expect(lat != nil)
    if let lat {
      #expect(lat < 0)
      #expect(abs(lat + 33.9417) < 0.001)
    }
  }

  @Test("Parse longitude - west")
  func parseLongitudeWest() {
    // W118244500 = 118° 24' 45.00" W = -118.4125
    let bytes: [UInt8] = Array("W118244500".utf8)
    let lon = CoordinateParser.parseLongitude(bytes[...])
    #expect(lon != nil)
    if let lon {
      #expect(lon < 0)
      #expect(abs(lon + 118.4125) < 0.001)
    }
  }

  @Test("Parse longitude - east")
  func parseLongitudeEast() {
    // E000274500 = 0° 27' 45.00" E = 0.4625
    let bytes: [UInt8] = Array("E000274500".utf8)
    let lon = CoordinateParser.parseLongitude(bytes[...])
    #expect(lon != nil)
    if let lon {
      #expect(lon > 0)
      #expect(abs(lon - 0.4625) < 0.001)
    }
  }

  @Test("Parse full coordinate")
  func parseFullCoordinate() {
    // N33564847W118244290 = 33.9467..° N, 118.4119..° W
    let bytes: [UInt8] = Array("N33564847W118244290".utf8)
    let coord = CoordinateParser.parseCoordinate(bytes[...])
    #expect(coord != nil)
    if let coord {
      #expect(coord.latitudeDeg > 33.94 && coord.latitudeDeg < 33.95)
      #expect(coord.longitudeDeg < -118.41 && coord.longitudeDeg > -118.42)
    }
  }

  @Test("Parse magnetic variation - east")
  func parseMagneticVariationEast() {
    let bytes: [UInt8] = Array("E0130".utf8)
    let magVar = CoordinateParser.parseMagneticVariation(bytes[...])
    #expect(magVar != nil)
    if let magVar {
      #expect(magVar.direction == .east)
      #expect(magVar.degrees == 13.0)
      #expect(magVar.signedValue == 13.0)
    }
  }

  @Test("Parse magnetic variation - west")
  func parseMagneticVariationWest() {
    let bytes: [UInt8] = Array("W0145".utf8)
    let magVar = CoordinateParser.parseMagneticVariation(bytes[...])
    #expect(magVar != nil)
    if let magVar {
      #expect(magVar.direction == .west)
      #expect(magVar.degrees == 14.5)
      #expect(magVar.signedValue == -14.5)
    }
  }

  @Test("Parse altitude - feet")
  func parseAltitudeFeet() throws {
    let bytes: [UInt8] = Array("05000".utf8)
    let alt = try CoordinateParser.parseAltitude(bytes[...])
    if case .feet(let value, let unit) = alt {
      #expect(value == 5000)
      #expect(unit == .msl)
    } else {
      Issue.record("Expected feet altitude")
    }
  }

  @Test("Parse altitude - flight level")
  func parseAltitudeFlightLevel() throws {
    let bytes: [UInt8] = Array("FL350".utf8)
    let alt = try CoordinateParser.parseAltitude(bytes[...])
    if case .flightLevel(let value) = alt {
      #expect(value == 350)
    } else {
      Issue.record("Expected flight level")
    }
  }

  @Test("Parse course")
  func parseCourse() {
    let bytes: [UInt8] = Array("0900".utf8)
    let course = CoordinateParser.parseCourse(bytes[...])
    #expect(course != nil)
    #expect(course == 90.0)
  }

  @Test("Parse distance")
  func parseDistance() {
    let bytes: [UInt8] = Array("0150".utf8)
    let distance = CoordinateParser.parseDistance(bytes[...])
    #expect(distance != nil)
    #expect(distance == 15.0)
  }
}

// MARK: - ByteParsing Tests

@Suite("ByteParsing")
struct ByteParsingTests {
  @Test("Parse integer")
  func parseInt() {
    let bytes: [UInt8] = Array("  123".utf8)
    let value = bytes[...].parseInt()
    #expect(value == 123)
  }

  @Test("Parse negative integer")
  func parseNegativeInt() {
    let bytes: [UInt8] = Array("-456".utf8)
    let value = bytes[...].parseInt()
    #expect(value == -456)
  }

  @Test("Parse unsigned integer")
  func parseUInt() {
    let bytes: [UInt8] = Array("99999".utf8)
    let value = bytes[...].parseUInt()
    #expect(value == 99999)
  }

  @Test("Parse double")
  func parseDouble() {
    let bytes: [UInt8] = Array("123.45".utf8)
    let value = bytes[...].parseDouble()
    #expect(value != nil)
    if let value {
      #expect(abs(value - 123.45) < 0.001)
    }
  }

  @Test("toString trims whitespace")
  func toStringTrims() {
    let bytes: [UInt8] = Array("  hello  ".utf8)
    let str = bytes[...].toString()
    #expect(str == "hello")
  }

  @Test("toRawString preserves whitespace")
  func toRawStringPreserves() {
    let bytes: [UInt8] = Array("P ".utf8)
    let str = bytes[...].toRawString()
    #expect(str == "P ")
  }

  @Test("isBlank detects blank")
  func isBlankTrue() {
    let bytes: [UInt8] = Array("     ".utf8)
    #expect(bytes[...].isBlank())
  }

  @Test("isBlank detects non-blank")
  func isBlankFalse() {
    let bytes: [UInt8] = Array("  X  ".utf8)
    #expect(!bytes[...].isBlank())
  }

  @Test("slice extracts correct range")
  func sliceRange() {
    let bytes: [UInt8] = Array("HELLO WORLD".utf8)
    let slice = bytes[...].slice(6..<11)
    #expect(slice.toString() == "WORLD")
  }
}

// MARK: - Altitude Tests

@Suite("Altitude")
struct AltitudeTests {
  @Test("Altitude feet value")
  func feetValue() {
    let alt = Altitude.feet(1000, .msl)
    #expect(alt.feetValue == 1000)
    #expect(alt.datum == .msl)
  }

  @Test("Altitude feet measurement")
  func feetMeasurement() {
    let alt = Altitude.feet(1000, .msl)
    if let measurement = alt.measurement {
      // 1000 feet in meters is approximately 304.8
      let meters = measurement.converted(to: UnitLength.meters).value
      #expect(abs(meters - 304.8) < 1)
    } else {
      Issue.record("Expected measurement")
    }
  }

  @Test("Altitude flight level in feet")
  func flightLevelInFeet() {
    let alt = Altitude.flightLevel(350)
    #expect(alt.feetValue == 35000)
  }

  @Test("Altitude ground")
  func ground() {
    let alt = Altitude.ground
    #expect(alt.feetValue == nil)
  }
}

// MARK: - Cycle Tests

@Suite("Cycle")
struct CycleTests {
  @Test("Cycle from YYMM")
  func fromYYMM() {
    let cycle = Cycle(yymm: "2601")
    #expect(cycle != nil)
    if let cycle {
      #expect(cycle.year == 2026)
      #expect(cycle.cycleNumber == 1)
    }
  }

  @Test("Cycle effectiveDate")
  func effectiveDate() {
    let cycle = Cycle(yymm: "2601")
    #expect(cycle?.effectiveDate != nil)
  }

  @Test("Cycle yymm format")
  func yymmFormat() {
    let cycle = Cycle(yymm: "2506")
    #expect(cycle?.yymm == "2506")
  }

  @Test("Cycle navigation")
  func navigation() {
    let cycle = Cycle(yymm: "2501")
    #expect(cycle != nil)
    if let cycle {
      #expect(cycle.next.cycleNumber == 2)
      #expect(cycle.next.year == 2025)
    }
  }
}

// MARK: - PathTerminator Tests

@Suite("PathTerminator")
struct PathTerminatorTests {
  @Test("PathTerminator from raw value")
  func fromRawValue() {
    let tf = PathTerminator(rawValue: "TF")
    #expect(tf == .trackToFix)

    let cf = PathTerminator(rawValue: "CF")
    #expect(cf == .courseToFix)

    let df = PathTerminator(rawValue: "DF")
    #expect(df == .directToFix)
  }

  @Test("PathTerminator unknown")
  func unknown() {
    let unknown = PathTerminator(rawValue: "XX")
    #expect(unknown == nil)
  }
}

// MARK: - Model Codable Tests

@Suite("Codable")
struct CodableTests {
  @Test("Coordinate round-trip")
  func coordinateRoundTrip() throws {
    let coord = Coordinate(latitudeDeg: 33.9425, longitudeDeg: -118.4081)
    let data = try JSONEncoder().encode(coord)
    let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
    #expect(decoded.latitude == coord.latitude)
    #expect(decoded.longitude == coord.longitude)
  }

  @Test("Altitude round-trip")
  func altitudeRoundTrip() throws {
    let altitudes: [Altitude] = [.feet(5000, .msl), .feet(1000, .agl), .flightLevel(350), .ground]
    for alt in altitudes {
      let data = try JSONEncoder().encode(alt)
      let decoded = try JSONDecoder().decode(Altitude.self, from: data)
      #expect(decoded == alt)
    }
  }

  @Test("MagneticVariation round-trip")
  func magVarRoundTrip() throws {
    let magVar = MagneticVariation(direction: .west, degrees: 14.5)
    let data = try JSONEncoder().encode(magVar)
    let decoded = try JSONDecoder().decode(MagneticVariation.self, from: data)
    #expect(decoded.direction == magVar.direction)
    #expect(decoded.degrees == magVar.degrees)
  }
}

// MARK: - ByteInitializable Tests

@Suite("ByteInitializable")
struct ByteInitializableTests {
  @Test("RecordType from byte")
  func recordTypeFromByte() {
    #expect(RecordType(byte: 0x53) == .standard)
    #expect(RecordType(byte: 0x48) == .header)
    #expect(RecordType(byte: 0x54) == .tailored)
  }

  @Test("TurnDirection from byte")
  func turnDirectionFromByte() {
    #expect(TurnDirection(byte: 0x4C) == .left)
    #expect(TurnDirection(byte: 0x52) == .right)
  }

  @Test("ILSCategory from byte")
  func ilsCategoryFromByte() {
    #expect(ILSCategory(byte: 0x31) == .catI)
    #expect(ILSCategory(byte: 0x32) == .catII)
  }
}

// MARK: - Fix Tests

@Suite("Fix")
struct FixTests {
  @Test("Fix identifier from VHF navaid")
  func vhfNavaidIdentifier() {
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

  @Test("Fix identifier from NDB navaid")
  func ndbNavaidIdentifier() {
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

  @Test("Fix identifier from enroute waypoint")
  func enrouteWaypointIdentifier() {
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

  @Test("Fix identifier from terminal waypoint")
  func terminalWaypointIdentifier() {
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

@Suite("Navaid")
struct NavaidTests {
  @Test("Navaid identifier from VHF")
  func vhfIdentifier() {
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

  @Test("Navaid identifier from NDB")
  func ndbIdentifier() {
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

// MARK: - CIFPData Tests

@Suite("CIFPData")
struct CIFPDataTests {
  @Test("CIFPData resolves VHF navaid fix")
  func resolveVHFNavaidFix() async {
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

    let fix = await data.resolveFix("LAX", sectionCode: .vhfNavaid, airportId: nil)
    #expect(fix != nil)
    if case .vhfNavaid(let resolved) = fix {
      #expect(resolved.identifier == "LAX")
    } else {
      Issue.record("Expected VHF navaid fix")
    }
  }

  @Test("CIFPData resolves NDB navaid fix")
  func resolveNDBNavaidFix() async {
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
      ndbNavaids: ["SLI": ndb],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix("SLI", sectionCode: .ndbNavaid, airportId: nil)
    #expect(fix != nil)
    if case .ndbNavaid(let resolved) = fix {
      #expect(resolved.identifier == "SLI")
    } else {
      Issue.record("Expected NDB navaid fix")
    }
  }

  @Test("CIFPData resolves enroute waypoint fix")
  func resolveEnrouteWaypointFix() async {
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

    let fix = await data.resolveFix("DAGGR", sectionCode: .enrouteWaypoint, airportId: nil)
    #expect(fix != nil)
    if case .enrouteWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "DAGGR")
    } else {
      Issue.record("Expected enroute waypoint fix")
    }
  }

  @Test("CIFPData resolves terminal waypoint fix")
  func resolveTerminalWaypointFix() async {
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

    let fix = await data.resolveFix("LIMMA", sectionCode: .terminalWaypoint, airportId: "KLAX")
    #expect(fix != nil)
    if case .terminalWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "LIMMA")
      #expect(resolved.airportId == "KLAX")
    } else {
      Issue.record("Expected terminal waypoint fix")
    }
  }

  @Test("CIFPData resolves fix without section code")
  func resolveFixWithoutSectionCode() async {
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
    let fix = await data.resolveFix("DAGGR", sectionCode: nil, airportId: nil)
    #expect(fix != nil)
    if case .enrouteWaypoint(let resolved) = fix {
      #expect(resolved.identifier == "DAGGR")
    } else {
      Issue.record("Expected enroute waypoint fix")
    }
  }

  @Test("CIFPData resolves navaid")
  func resolveNavaid() async {
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

    let resolved = await data.resolveNavaid("LAX", sectionCode: "D")
    #expect(resolved != nil)
    if case .vhf(let vhf) = resolved {
      #expect(vhf.identifier == "LAX")
    } else {
      Issue.record("Expected VHF navaid")
    }
  }

  @Test("CIFPData returns nil for unknown fix")
  func unknownFix() async {
    let data = CIFPData(
      vhfNavaids: [:],
      ndbNavaids: [:],
      enrouteWaypoints: [:],
      terminalWaypoints: []
    )

    let fix = await data.resolveFix("UNKNOWN", sectionCode: nil, airportId: nil)
    #expect(fix == nil)
  }
}
