# SwiftCIFP

[![Build and Test](https://github.com/RISCfuture/SwiftCIFP/actions/workflows/ci.yml/badge.svg)](https://github.com/RISCfuture/SwiftCIFP/actions/workflows/ci.yml)
[![Documentation](https://github.com/RISCfuture/SwiftCIFP/actions/workflows/doc.yml/badge.svg)](https://riscfuture.github.io/SwiftCIFP/)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg)](https://swift.org)

A parser for FAA CIFP (Coded Instrument Flight Procedures) data in ARINC 424 format.

## Overview

SwiftCIFP parses FAA CIFP data, which can be downloaded from
<https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/>.

The data is parsed into Codable structs that can be used in your Swift project.

The design philosophy of SwiftCIFP is _domain restricted data_ wherever
possible. This means favoring restrictive enums over open types like Strings.
It also takes advantage of `Foundation` types wherever possible, such as
`Measurement`s instead of raw numeric types for physical values.

CIFP uses the ARINC 424 format with fixed-width 132-character records. The format
includes approximately 20 record types covering navaids, waypoints, airways,
airports, procedures (SID/STAR/approach), and airspace.

## Requirements

- Swift 6.2+
- macOS 26+, iOS 26+, watchOS 26+, tvOS 26+, or visionOS 26+

## Installation

Add SwiftCIFP to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RISCfuture/SwiftCIFP", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftCIFP"]
)
```

## Usage

### Loading CIFP Data

```swift
import SwiftCIFP

// Load from in-memory data
let cifp = try CIFP(data: fileData)

// Stream from a local file URL (async)
let cifp = try await CIFP(url: fileURL)

// Stream from any async byte sequence (e.g., URLSession)
let (bytes, _) = try await URLSession.shared.bytes(from: remoteURL)
let cifp = try await CIFP(bytes: bytes)
```

### Error Handling

All parsing methods accept an optional `errorCallback` to receive detailed error
information for records that couldn't be parsed:

```swift
let cifp = try CIFP(data: fileData) { error, lineNumber in
    if let line = lineNumber {
        print("Parse error at line \(line): \(error.localizedDescription)")
    } else {
        // Aggregation errors (e.g., building procedures from records)
        print("Aggregation error: \(error.localizedDescription)")
    }
    if let reason = (error as? LocalizedError)?.failureReason {
        print("  Reason: \(reason)")
    }
}
```

Errors are reported via `CIFPError` with specific cases for:
- `lineTooShort` - Record doesn't have enough characters
- `unknownSectionCode` - Unrecognized section in the file
- `unknownSubsectionCode` - Unrecognized subsection within a section
- `missingRequiredField` - A required field couldn't be parsed
- `aggregationError` - Error building a model from parsed records

### Querying Airports

```swift
// Get airport by identifier (ICAO code or FAA LID)
if let klax = cifp.airports["KLAX"] {
    print("\(klax.name) at elevation \(klax.elevation)")
}

// Get runways for an airport
let runways = cifp.runways.filter { $0.airportId == "KLAX" }
for runway in runways {
    print("Runway \(runway.name): \(runway.length)")
}
```

### Querying Procedures

```swift
// Get SIDs for an airport
let sids = cifp.sids.filter { $0.airportId == "KLAX" }
for sid in sids {
    print("SID: \(sid.identifier)")
    for leg in sid.legs {
        print("  - \(leg.fixId ?? "?") (\(leg.pathTerminator))")
    }
}

// Get approaches
let approaches = cifp.approaches.filter { $0.airportId == "KLAX" }
for approach in approaches {
    print("\(approach.approachType) \(approach.identifier)")
}
```

### Querying Navaids and Waypoints

```swift
// VHF Navaids (VOR, VORTAC, DME)
if let lax = cifp.vhfNavaids["LAX"] {
    print("\(lax.name) - \(lax.navaidClass)")
    print("Frequency: \(lax.frequency)")
}

// NDB Navaids
for (id, ndb) in cifp.ndbNavaids {
    print("\(id): \(ndb.frequency)")
}

// Enroute waypoints
if let waypoint = cifp.enrouteWaypoints["SADDE"] {
    print("Waypoint at \(waypoint.coordinate)")
}

// Airways
if let v25 = cifp.airways["V25"] {
    print("Airway \(v25.identifier) with \(v25.fixes.count) fixes")
}
```

### Using Measurement Types

```swift
// Altitude as Measurement<UnitLength>
if let elevation = airport.elevation,
   let measurement = elevation.measurement {
    let meters = measurement.converted(to: .meters)
    print("Elevation: \(meters)")
}

// Coordinates as Measurement<UnitAngle>
let lat = coordinate.latitude  // Measurement<UnitAngle>
let degrees = lat.converted(to: .degrees)

// Or as CoreLocation coordinate
let clCoordinate = coordinate.coreLocation
```

### AIRAC Cycle Information

```swift
// Access cycle information from parsed data
print("Data cycle: \(cifp.cycle)")
print("Effective: \(cifp.cycle.effectiveDate)")

// Get current AIRAC cycle
let current = Cycle.current
print("Current cycle: \(current.yymm)")
```

## Data Model

### Record Types

| Section | Type | Description |
|---------|------|-------------|
| AS | GridMORA | Minimum obstruction altitude grid |
| D | VHFNavaid | VOR/VORTAC/DME stations |
| DB | NDBNavaid | Non-directional beacons |
| EA | EnrouteWaypoint | Named waypoints for enroute |
| ER | Airway | Airways with fix sequences |
| PA | Airport | Airport reference data |
| PG | Runway | Runway information |
| PC | TerminalWaypoint | Terminal area waypoints |
| PD | SID | Standard Instrument Departures |
| PE | STAR | Standard Terminal Arrivals |
| PF | Approach | Approach procedures |
| PI | LocalizerGlideSlope | ILS components |
| UC | ControlledAirspace | Class B/C/D airspace |
| UR | SpecialUseAirspace | Restricted/MOA/Warning areas |
| HA | Heliport | Heliport reference data |

### Path Terminators

Procedure legs use path terminators to define how to fly to each fix:

- **IF** - Initial Fix
- **TF** - Track to Fix
- **CF** - Course to Fix
- **DF** - Direct to Fix
- **AF** - Arc to Fix (DME arc)
- **RF** - Radius to Fix (constant radius arc)
- **CA** - Course to Altitude
- **VA** - Heading to Altitude
- **FA** - Fix to Altitude
- **FC** - Track from Fix for Distance
- **FD** - Track from Fix to DME Distance
- **FM** - From Fix to Manual termination
- **HA** - Holding pattern with altitude termination
- **HF** - Holding pattern with single circuit
- **HM** - Holding pattern with manual termination
- **PI** - Procedure turn
- **VM** - Heading to manual termination
- **VI** - Heading to intercept
- **VD** - Heading to DME
- **VR** - Heading to radial
- **CR** - Course to radial
- **CD** - Course to DME

## ARINC 424 Compatibility

SwiftCIFP is designed specifically for FAA CIFP data, which uses a subset
of the ARINC 424 format. The parser supports approximately 23 record types
covering navigation aids, airports, procedures, and airspace.

For details on supported vs. unsupported record types and other differences
from the full ARINC specification, see the
[ARINC 424 Compatibility](https://riscfuture.github.io/SwiftCIFP/documentation/swiftcifp/arinc424compatibility)
documentation.

## Documentation

Online API documentation and tutorials are available at
<https://riscfuture.github.io/SwiftCIFP/documentation/swiftcifp/>.

DocC documentation is available. For Xcode documentation, you can run

```sh
swift package generate-documentation --target SwiftCIFP
```

to generate a docarchive at
`.build/plugins/Swift-DocC/outputs/SwiftCIFP.doccarchive`. You can open this
docarchive file in Xcode for browseable API documentation. Or, within Xcode,
open the SwiftCIFP package in Xcode and choose **Build Documentation** from the
**Product** menu.

## Testing

SwiftCIFP has comprehensive unit tests, which can be run with `swift test`.

### E2E Testing Tool

The `SwiftCIFP_E2E` target is a command-line tool for testing CIFP parsing:

```sh
# Parse a local file
swift run SwiftCIFP_E2E -i ~/Downloads/CIFP_260122/FAACIFP18

# Parse a ZIP archive (automatically extracts FAACIFP18)
swift run SwiftCIFP_E2E -i ~/Downloads/CIFP_260122.zip

# Parse from a remote URL (supports both raw and ZIP)
swift run SwiftCIFP_E2E -i https://aeronav.faa.gov/Upload_313-d/cifp/CIFP_260122.zip

# Output as JSON
swift run SwiftCIFP_E2E -i /path/to/FAACIFP18 -f json > cifp.json

# Verbose output
swift run SwiftCIFP_E2E -i /path/to/FAACIFP18 -v
```

Options:
- `-i, --input <path|url>`: Path or URL to CIFP file (FAACIFP18 or .zip).
- `-f, --format <summary|json>`: Output format. Defaults to summary.
- `-v, --verbose`: Show verbose output during parsing.

## CIFP Data

CIFP data is published by the FAA on a 28-day AIRAC cycle. Data can be downloaded from:
<https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/>

The data file is named `FAACIFP18` and typically comes in a zip archive with the cycle date (e.g., `CIFP_260122.zip`).
