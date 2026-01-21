# ARINC 424 Compatibility

Understand how SwiftCIFP relates to the ARINC 424 specification.

## Overview

SwiftCIFP is purpose-built for FAA CIFP data, which uses a subset of
the worldwide ARINC 424 standard. This document describes what's
supported and key differences from the full specification.

## Supported Record Types

SwiftCIFP parses 23 section codes from FAA CIFP data:

| Category | Section Codes | Description |
|----------|---------------|-------------|
| Enroute | AS | GridMORA (Minimum Off-Route Altitude) |
| | D | VHF Navaids (VOR, VORTAC, DME) |
| | DB | NDB Navaids |
| | EA | Enroute Waypoints |
| | ER | Airways |
| Airport | PA | Airport Reference |
| | PC | Terminal Waypoints |
| | PD | SIDs (Standard Instrument Departures) |
| | PE | STARs (Standard Terminal Arrivals) |
| | PF | Approach Procedures |
| | PG | Runways |
| | PI | Localizer/Glide Slope |
| | PN | Terminal NDB |
| | PP | Path Points (SBAS/GBAS) |
| | PS | MSA (Minimum Sector Altitude) |
| Heliport | HA | Heliport Reference |
| | HC | Heliport Waypoints |
| | HD | Heliport SIDs |
| | HE | Heliport STARs |
| | HF | Heliport Approaches |
| | HS | Heliport MSA |
| Airspace | UC | Controlled Airspace |
| | UR | Special Use Airspace |

## Unsupported ARINC 424 Record Types

### Not Present in FAA CIFP

The following ARINC 424 record types are defined in the specification but
are not published in the FAA's CIFP distribution:

- **PB** - Airport Gates
- **PK** - TAA (Terminal Arrival Altitude)
- **PL** - MLS (Microwave Landing System)
- **PM** - Localizer Markers
- **PT** - GLS (GBAS Landing System)
- **PV** - Airport Communications
- **EM** - Airway Markers
- **EP** - Enroute Holding Patterns
- **ET** - Preferred Routes
- **EU** - Airway Restrictions
- **EV** - Enroute Communications
- **HK** - Heliport TAA
- **HV** - Heliport Communications
- **TC** - Cruising Tables
- **TG** - Geographic Reference Tables
- **UF** - FIR/UIR Boundaries

### Tailored Data Records

ARINC 424 distinguishes between Standard (S) and Tailored (T) data.
Tailored records (R, RA) are carrier-specific or FMS-specific customizations
and are not included in the FAA CIFP distribution.

## Other Differences

### Data Scope

- **SwiftCIFP**: US airspace only (FAA CIFP from aeronav.faa.gov)
- **ARINC 424**: Worldwide coverage (multiple data providers like Jeppesen, Lido)

### Header Parsing

SwiftCIFP extracts the AIRAC cycle from the "VOLUME YYMM" text pattern
found in FAA CIFP files. The ARINC 424 specification defines formal
HDR1/HDR2 tape label records, which are historical artifacts from
magnetic tape distribution.

### Continuation Records

SwiftCIFP parses continuation records for multi-record types including
airways, procedures, and path points. However, simulation-specific and
flight planning continuation records defined in ARINC 424 are not
present in FAA CIFP data and therefore not supported.

### Historical Artifacts

ARINC 424 Chapter 6 specifies 9-track magnetic tape encoding details
including bit density, block sizes, and tape labels. These specifications
are historical artifacts and not relevant to modern file-based parsing.
