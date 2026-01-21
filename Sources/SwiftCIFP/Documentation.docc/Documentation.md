# ``SwiftCIFP``

Parse FAA CIFP (Coded Instrument Flight Procedures) data into Swift types.

## Overview

SwiftCIFP provides a high-performance parser for FAA CIFP data in ARINC 424 format.
CIFP contains digital instrument flight procedure data including navaids, waypoints,
airways, airports, and procedures (SID/STAR/approach).

Key features:

- Parse all major CIFP record types (~20 types)
- Type-safe enums for navigation and procedure properties
- Integration with Foundation `Measurement` types
- CoreLocation coordinate support
- Full `Codable` and `Sendable` conformance
- AIRAC cycle tracking
- Comprehensive error reporting via callback

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ModelLinking>

### Core Types

- ``CIFP``
- ``CIFPData``
- ``Cycle``
- ``Header``

### Navigation

- ``VHFNavaid``
- ``NDBNavaid``
- ``EnrouteWaypoint``
- ``Airway``
- ``GridMORA``

### Airports

- ``Airport``
- ``Runway``
- ``TerminalWaypoint``
- ``TerminalNavaid``
- ``LocalizerGlideSlope``
- ``PathPoint``
- ``MSA``

### Procedures

- ``SID``
- ``STAR``
- ``Approach``
- ``ProcedureLeg``

### Airspace

- ``ControlledAirspace``
- ``SpecialUseAirspace``

### Heliports

- ``Heliport``
- ``HeliportWaypoint``
- ``HeliportApproach``
- ``HeliportMSA``

### Supporting Types

- ``Coordinate``
- ``Fix``
- ``Navaid``
- ``Altitude``
- ``MagneticVariation``
- ``PathTerminator``
- ``TurnDirection``
- ``NavaidClass``
- ``ApproachType``

### Errors

- ``CIFPError``
- ``CIFPFormatError``
- ``AggregationErrorReason``

### Reference

- <doc:ARINC424Compatibility>
