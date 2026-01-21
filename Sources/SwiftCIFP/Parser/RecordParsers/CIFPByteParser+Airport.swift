import Foundation

// MARK: - Airport Parsing

extension CIFPByteParser {
  static func parseGridMORA(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    // Parse grid identifier to get starting coordinates
    let gridIdent = bytes.slice(13..<20).toString()

    // Parse grid coordinates from identifier
    var startLat: Int?
    var startLon: Int?
    if gridIdent.count >= 7 {
      let latStr = gridIdent.dropFirst().prefix(2)
      let lonStr = gridIdent.dropFirst(4).prefix(3)
      if let lat = Int(latStr), let lon = Int(lonStr) {
        startLat = gridIdent.first == "S" ? -lat : lat
        startLon = gridIdent.dropFirst(3).first == "W" ? -lon : lon
      }
    }

    guard let latitude = startLat,
      let startingLongitude = startLon
    else {
      throw CIFPError.missingRequiredField(
        field: "coordinates",
        recordType: "GridMORA",
        line: lineNumber
      )
    }

    // Parse 30 MORA values, creating individual GridMORA for each valid value
    var gridMORAs: [GridMORA] = []
    for i in 0..<30 {
      let start = 30 + i * 3
      let moraSlice = bytes.slice(start..<(start + 3))
      let str = moraSlice.toString()

      // Skip unknown or empty values
      if str == "UNK" || str.isEmpty {
        continue
      }

      // Only create a record if we have a valid MORA value
      guard let mora = Int(str) else { continue }
      let longitudeDeg = startingLongitude + i
      gridMORAs.append(
        GridMORA(
          latitudeDeg: latitude,
          longitudeDeg: longitudeDeg,
          moraFt: mora * 100
        )
      )
    }

    return .gridMORAs(gridMORAs)
  }

  static func parseAirport(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let icaoIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let faaIdent = bytes.slice(13..<17).toString()

    // IATA designator (position 13-16, 3 chars) - same position as FAA ID in some cases
    let iataSlice = bytes.slice(13..<16)
    let iataDesignator = iataSlice.isBlank() ? nil : iataSlice.toString()

    // Longest runway length (position 27-30, hundreds of feet)
    let rwyLenSlice = bytes.slice(27..<30)
    let longestRunwayLengthFt: Int? =
      rwyLenSlice.isBlank() ? nil : rwyLenSlice.parseUInt().map { Int($0) * 100 }

    // Longest runway surface (position 30)
    let surfByte = bytes.count > 30 ? bytes[bytes.startIndex + 30] : ASCII.space
    let longestRunwaySurface = RunwaySurface(byte: surfByte)

    // IFR capability (position 31) - H=High, L=Low, Y=Yes, N=No
    let ifrByte = bytes.count > 31 ? bytes[bytes.startIndex + 31] : ASCII.space
    let isIFRCapable = ifrByte == ASCII.H || ifrByte == ASCII.Y

    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let magVar = CoordinateParser.parseMagneticVariation(bytes.slice(51..<56))
    let elevation = bytes.slice(56..<61).parseInt()
    let speedLimit = bytes.slice(61..<64).parseInt()

    // Transition altitude (position 69-74)
    let transAltSlice = bytes.slice(69..<74)
    let transitionAltitudeFt = transAltSlice.isBlank() ? nil : transAltSlice.parseInt()

    // Transition level (position 74-79) - stored as flight level × 100
    let transLvlSlice = bytes.slice(74..<79)
    let transitionLevel = transLvlSlice.isBlank() ? nil : transLvlSlice.parseInt()

    // Public/Military status (position 80)
    let pubMilByte = bytes.count > 80 ? bytes[bytes.startIndex + 80] : ASCII.space
    let publicMilitary = PublicMilitary(byte: pubMilByte)

    // Magnetic/True indicator (position 85)
    let magTrueByte = bytes.count > 85 ? bytes[bytes.startIndex + 85] : ASCII.M
    let bearingReference: BearingReference = magTrueByte == ASCII.T ? .trueNorth : .magnetic

    // Datum code (position 86-89, 3 chars)
    let datumSlice = bytes.slice(86..<89)
    let datumCode = datumSlice.isBlank() ? nil : DatumCode(rawValue: datumSlice.toString())

    let name = bytes.slice(93..<123).toString()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "Airport",
        line: lineNumber
      )
    }
    guard let magVar else {
      throw CIFPError.missingRequiredField(
        field: "magneticVariation",
        recordType: "Airport",
        line: lineNumber
      )
    }
    guard let elevation else {
      throw CIFPError.missingRequiredField(
        field: "elevation",
        recordType: "Airport",
        line: lineNumber
      )
    }

    return .airport(
      Airport(
        id: icaoIdent,
        icaoRegion: icaoRegion,
        faaId: faaIdent.isEmpty ? nil : faaIdent,
        iataDesignator: iataDesignator,
        coordinate: coord,
        magneticVariation: magVar,
        elevationFt: elevation,
        longestRunwayLengthFt: longestRunwayLengthFt,
        longestRunwaySurface: longestRunwaySurface,
        isIFRCapable: isIFRCapable,
        speedLimitKts: speedLimit,
        transitionAltitudeFt: transitionAltitudeFt,
        transitionLevel: transitionLevel,
        publicMilitary: publicMilitary,
        bearingReference: bearingReference,
        datumCode: datumCode,
        name: name
      )
    )
  }

  static func parseRunway(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let runwayIdent = bytes.slice(13..<18).toString()
    let length = bytes.slice(22..<27).parseInt()
    let bearing = CoordinateParser.parseCourse(bytes.slice(27..<31))
    let coord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let gradient = CoordinateParser.parseGradient(bytes.slice(51..<56))

    // Ellipsoid height (position 60-66, 6 chars, in tenths of feet, can be negative)
    let ellipsoidSlice = bytes.slice(60..<66)
    var ellipsoidHeightFt: Int?
    if !ellipsoidSlice.isBlank() {
      if let heightValue = ellipsoidSlice.parseInt() {
        // Convert from tenths to whole feet (rounded)
        ellipsoidHeightFt = (heightValue + 5) / 10
      }
    }

    let threshElev = bytes.slice(66..<71).parseInt()
    let displacedThresh = bytes.slice(71..<75).parseInt()
    let tch = bytes.slice(75..<77).parseInt()
    let width = bytes.slice(77..<80).parseInt()

    // Localizer identifier (position 80-84, 4 chars)
    let locIdSlice = bytes.slice(80..<84)
    let localizerId = locIdSlice.isBlank() ? nil : locIdSlice.toString()

    // ILS category (position 84, single character)
    let ilsCatByte = bytes.count > 84 ? bytes[bytes.startIndex + 84] : ASCII.space
    let ilsCategory = ILSCategory(byte: ilsCatByte)

    // Stopway length (position 85-88, 4 chars in feet)
    let stopwaySlice = bytes.slice(85..<89)
    let stopwayFt: Int? = stopwaySlice.isBlank() ? nil : stopwaySlice.parseInt()

    guard let coord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "Runway",
        line: lineNumber
      )
    }
    guard let length else {
      throw CIFPError.missingRequiredField(
        field: "length",
        recordType: "Runway",
        line: lineNumber
      )
    }
    guard let threshElev else {
      throw CIFPError.missingRequiredField(
        field: "thresholdElevation",
        recordType: "Runway",
        line: lineNumber
      )
    }
    guard let displacedThresh else {
      throw CIFPError.missingRequiredField(
        field: "displacedThreshold",
        recordType: "Runway",
        line: lineNumber
      )
    }
    guard let tch else {
      throw CIFPError.missingRequiredField(
        field: "thresholdCrossingHeight",
        recordType: "Runway",
        line: lineNumber
      )
    }
    guard let width else {
      throw CIFPError.missingRequiredField(
        field: "width",
        recordType: "Runway",
        line: lineNumber
      )
    }

    return .runway(
      Runway(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        runwayId: runwayIdent,
        lengthFt: length,
        magneticBearingDeg: bearing,
        thresholdCoordinate: coord,
        gradientPct: gradient,
        ellipsoidHeightFt: ellipsoidHeightFt,
        thresholdElevationFt: threshElev,
        displacedThresholdFt: displacedThresh,
        thresholdCrossingHeightFt: tch,
        widthFt: width,
        localizerId: localizerId,
        ilsCategory: ilsCategory,
        stopwayFt: stopwayFt
      )
    )
  }

  static func parseLocalizer(
    _ bytes: ArraySlice<UInt8>,
    lineNumber: Int
  ) throws -> ParsedRecord {
    let airportIdent = bytes.slice(6..<10).toString()
    let icaoRegion = bytes.slice(10..<12).toString()
    let locIdent = bytes.slice(13..<17).toString()
    let catByte = bytes.count > 17 ? bytes[bytes.startIndex + 17] : ASCII.space
    let frequency = CoordinateParser.parseVHFFrequency(bytes.slice(22..<27))
    let runwayIdent = bytes.slice(27..<32).toString()
    let locCoord = CoordinateParser.parseCoordinate(bytes.slice(32..<51))
    let locBearing = CoordinateParser.parseCourse(bytes.slice(51..<55))
    let gsCoord = CoordinateParser.parseCoordinate(bytes.slice(55..<74))

    // Glide slope angle (position 83-87, in hundredths of degrees)
    let gsAngleSlice = bytes.slice(83..<87)
    let slopeAngleDeg: Double? =
      gsAngleSlice.isBlank() ? nil : gsAngleSlice.parseUInt().map { Double($0) / 100.0 }

    // Localizer width (position 87-90, in hundredths of degrees)
    let widthSlice = bytes.slice(87..<90)
    let widthDeg: Double? =
      widthSlice.isBlank() ? nil : widthSlice.parseUInt().map { Double($0) / 100.0 }

    // Station declination (position 90-95, direction + degrees in tenths)
    let stationDeclination = CoordinateParser.parseMagneticVariation(bytes.slice(90..<95))

    // Threshold crossing height (position 95-99, in hundredths of feet)
    let tchSlice = bytes.slice(95..<99)
    let thresholdCrossingHeightFt: Int? =
      tchSlice.isBlank() ? nil : tchSlice.parseUInt().map { Int($0) / 100 }

    guard let locCoord else {
      throw CIFPError.missingRequiredField(
        field: "coordinate",
        recordType: "Localizer",
        line: lineNumber
      )
    }
    guard let frequency else {
      throw CIFPError.missingRequiredField(
        field: "frequency",
        recordType: "Localizer",
        line: lineNumber
      )
    }
    guard let locBearing else {
      throw CIFPError.missingRequiredField(
        field: "bearing",
        recordType: "Localizer",
        line: lineNumber
      )
    }

    return .localizer(
      LocalizerGlideSlope(
        airportId: airportIdent,
        icaoRegion: icaoRegion,
        localizerId: locIdent,
        ilsCategory: ILSCategory(byte: catByte),
        frequencyMHz: frequency,
        runwayId: runwayIdent,
        coordinate: locCoord,
        bearingDeg: locBearing,
        slopeCoordinate: gsCoord,
        slopeAngleDeg: slopeAngleDeg,
        widthDeg: widthDeg,
        stationDeclinationDeg: stationDeclination?.signedValue,
        thresholdCrossingHeightFt: thresholdCrossingHeightFt
      )
    )
  }
}
