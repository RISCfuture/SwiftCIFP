# Getting Started with SwiftCIFP

Learn how to load and query FAA CIFP data.

## Overview

SwiftCIFP parses CIFP data from the FAA into type-safe Swift structures. CIFP data
can be downloaded from <https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/>.

### Loading CIFP Data

Load CIFP data from a file or URL:

```swift
import SwiftCIFP

// From in-memory data
let cifp = try CIFP(data: fileData)

// From a file URL (async)
let cifp = try await CIFP(url: fileURL)

// Stream from network
let (bytes, _) = try await URLSession.shared.bytes(from: remoteURL)
let cifp = try await CIFP(bytes: bytes)
```

### Handling Parse Errors

All parsing methods accept an optional `errorCallback` to receive detailed error
information for records that couldn't be parsed:

```swift
let cifp = try CIFP(data: fileData) { error, lineNumber in
    if let lineNumber {
        print("Parse error at line \(lineNumber): \(error.localizedDescription)")
    } else {
        // Aggregation errors (e.g., building procedures from records)
        print("Aggregation error: \(error.localizedDescription)")
    }
    if let reason = (error as? LocalizedError)?.failureReason {
        print("  Reason: \(reason)")
    }
}
```

Errors are reported via ``CIFPError`` with specific cases for different error types.
The `lineNumber` is `nil` for aggregation errors that occur when building models
from parsed records.

### Querying Airports

Access airports by identifier. The key is the ICAO code for airports that have one
(e.g., "KLAX"), or the FAA LID for US airports without an ICAO code (e.g., "L88").
See ``Airport`` for more details on identifier types.

```swift
// Look up by identifier
if let klax = cifp.airports["KLAX"] {
    print("\(klax.name) at elevation \(klax.elevation.description)")
}

// Get all airports
for (id, airport) in cifp.airports {
    print("\(id): \(airport.name)")
}
```

### Querying Procedures

Access SIDs, STARs, and approaches:

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

### Querying Navaids

Access VHF navaids (VOR, VORTAC, DME) and NDBs:

```swift
// VHF Navaids
if let lax = cifp.vhfNavaids["LAX"] {
    print("\(lax.name) - \(lax.navaidClass)")
    print("Frequency: \(lax.frequency)")
}

// NDB Navaids
for (id, ndb) in cifp.ndbNavaids {
    print("\(id): \(ndb.frequency)")
}
```

### Working with Measurements

CIFP properties integrate with Foundation's `Measurement` types:

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

// CoreLocation integration
let clCoordinate = coordinate.coreLocation  // CLLocationCoordinate2D
```

### AIRAC Cycles

CIFP data is published on 28-day AIRAC cycles:

```swift
// Access cycle from parsed data
print("Data cycle: \(cifp.cycle)")
print("Effective: \(cifp.cycle.effectiveDate)")
print("Expires: \(cifp.cycle.expirationDate)")

// Get effective AIRAC cycle
let effective = Cycle.effective
print("Effective cycle: \(effective)")

// Navigate between cycles
let next = effective.next
let previous = effective.previous
```
