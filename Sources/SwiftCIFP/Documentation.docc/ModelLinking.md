# Linking Related Models

Learn how to resolve relationships between CIFP models.

## Overview

By default, CIFP models reference related models through string identifiers. For example, a
`Runway` has a `localizerId` property that contains a string, not the actual
`LocalizerGlideSlope` object. This keeps the basic `CIFP` struct simple and efficient.

When you need to navigate relationships between models, use ``CIFPData`` instead. This actor
establishes links between models, enabling async computed properties that resolve string
identifiers to actual model objects.

## Creating Linked Data

Use the ``CIFP/linked()`` method to create a `CIFPData` instance:

```swift
let cifp = try await CIFP(url: fileURL)
let data = await cifp.linked()

// Now you can resolve relationships
for runway in data.runways {
    if let localizer = await runway.localizer {
        print("Runway \(runway.name) has localizer \(localizer.localizerId)")
    }
}
```

## Resolving Procedure Fixes

Procedure legs reference fixes (navaids and waypoints) by identifier. With linked data, you can
resolve these to actual fix objects:

```swift
for approach in data.approaches {
    for leg in approach.legs {
        if let fix = await leg.fix {
            switch fix {
            case .vhfNavaid(let nav):
                print("VOR: \(nav.name ?? nav.identifier)")
            case .ndbNavaid(let ndb):
                print("NDB: \(ndb.name ?? ndb.identifier)")
            case .enrouteWaypoint(let wp):
                print("Waypoint: \(wp.identifier)")
            case .terminalWaypoint(let wp):
                print("Terminal Waypoint: \(wp.identifier)")
            }
        }
    }
}
```

## Available Linked Properties

### Runway

- ``Runway/airport``: The parent airport
- ``Runway/localizer``: The associated localizer/glide slope

### Approach

- ``Approach/airport``: The parent airport
- ``Approach/runway``: The associated runway

### SID / STAR

- ``SID/airport``: The parent airport
- ``SID/runways``: The associated runways
- ``STAR/airport``: The parent airport
- ``STAR/runways``: The associated runways

### ProcedureLeg

- ``ProcedureLeg/fix``: The resolved fix (VHF navaid, NDB, or waypoint)
- ``ProcedureLeg/navaid``: The resolved recommended navaid
- ``ProcedureLeg/centerFixObject``: The resolved center fix (for RF legs)

### AirwayFix

- ``AirwayFix/fix``: The resolved fix for this airway point

### Airspace

- ``ControlledAirspace/centerFix``: The resolved center fix
- ``ControlledAirspace/centerAirport``: The resolved center airport (if center is an airport)
- ``SpecialUseAirspace/centerFix``: The resolved center fix

### MSA

- ``MSA/airport``: The parent airport
- ``MSA/centerFix``: The resolved center fix

## When to Use Linked Data

Use `CIFPData` when you need to:
- Navigate between related models (e.g., runway to localizer)
- Resolve fix identifiers in procedures to actual fix objects
- Access the coordinate or other properties of procedure fix references

Use the basic `CIFP` struct when you:
- Only need simple lookups by identifier
- Want minimal memory overhead
- Don't need to traverse relationships

## Topics

### Creating Linked Data

- ``CIFP/linked()``
- ``CIFPData``

### Fix Resolution

- ``Fix``
- ``Navaid``
