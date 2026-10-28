# Change Log

## [Unreleased]

### Added

- `Approach` and `HeliportApproach` report each route's qualifiers (ARINC 424
  field 5.7, columns 119 and 120) as `navigationRequirement` and `landing`.
  They are read per route because the FAA codes them that way: KOAK ILS RWY
  12's RAIDR transition requires GPS while its final route requires DME. An
  unrecognized qualifier fails its record. Cycle 2610 has one, the `A` on KUIN
  RNAV (GPS) RWY 31's UYAPI transition.

### Fixed

- Waypoint description codes now decode each column under FAA Order 8260.19G,
  Appendix N. Column 43 carries the approach role, so `isFAF` and `isMAP` read
  `F` and `M` there instead of column 42. Column 41 carries fly-over status, so
  `isFlyover` reads `Y` or `B` there instead of treating every essential
  waypoint as fly-over. On KOAK ILS RWY 12, PLAZA is now the final approach fix
  and RW12 the missed approach point, and `Approach.finalApproachFix` and
  `missedApproachPoint` find both. Codes the old enums lacked (`B`, `D`, `F`,
  `H`, `I`, and `M` in column 43; `B` and `Y` in column 41) used to come back
  as `nil` with no diagnostic. An unrecognized character now fails the record
  through the error callback.
- A blank altitude description is the "at" restriction (ARINC 424 field 5.29),
  so altitudes published with one are no longer dropped. Cycle 2610 has 16,461
  such legs, including RAIDR's 5,000-foot crossing on KOAK ILS RWY 12.
- `between` constraints had their altitudes swapped. ARINC puts the higher
  altitude in the first field.
- Speed limits are no longer dropped. The description was read from column 103,
  the first character of the vertical angle, rather than column 118, and a
  blank description, which ARINC 424 field 5.261 defines as the mandatory "at"
  speed, produced no constraint. Cycle 2610 publishes 9,560 speed limits, and
  all but one were lost, including 4,104 "at or below" maximums.
- Holding pattern leg times are no longer dropped. A time such as `T010` (1.0
  minute) didn't parse as a distance, so cycle 2610's 4,303 timed holds had no
  leg length.
- Airway records are read from their published columns (ARINC 424 section
  4.1.6.1). Every airway reported an `undesignated` route type and an
  `unspecified` level, read from blank columns. Each segment's distance and
  inbound course were swapped, so `totalDistanceNM` summed courses. The
  direction restriction was read from the boundary code column, and the
  boundary code from the waypoint description.
- Waypoint types decode all three columns of ARINC 424 field 5.42. Only the
  first column was read, with several codes misnamed (`R` is a named
  intersection, not an RNAV waypoint, and `V` a VFR waypoint, not a VHF
  navaid). The 991 enroute waypoints whose type sits in the second column, such
  as latitude/longitude intersections, were reported as `other`.
- VHF navaid usage classes are read from column 30. Column 29, the DME type,
  was being read instead, so TACANs reported `terminal` and other navaids
  reported nothing.
- Approach level of service records (ARINC 424-19 field 5.297) are decoded:
  each line of minimums (LPV/LP, LNAV/VNAV, LNAV) as authorized or not, and the
  RNP values an RNP AR approach is authorized to. The old decoding read fields a
  column off and folded the authorization flag into the name, so
  `requiredNavPerformance` never decoded and an unauthorized line looked the
  same as a missing record. Every route of a procedure, transitions included,
  now carries its levels of service, and heliport approaches have them too.
- RNP decodes as a two-digit mantissa and a negative exponent (ARINC 424 field
  5.211), so `031` is 0.3 NM rather than 3.1 NM. A malformed value now fails the
  record.
- Airspace boundary sequence numbers and multiple codes are read from their
  published columns. Every boundary used to get sequence number zero, and
  controlled airspace never had a multiple code or class.
- Each airspace volume is its own `ControlledAirspace` or `SpecialUseAirspace`.
  Volumes that share a center or designation used to merge into one, taking the
  first volume's limits. Cycle 2610 now yields 1,281 controlled airspace volumes
  rather than 696.
- Boundary-via codes follow ARINC 424 field 5.118: `H` is a rhumb line, `R` a
  clockwise arc, and `L` a counter-clockwise arc. The end-of-description marker
  in the second column is now `AirspaceBoundary.isEndOfDescription`. Arc
  origin, distance, and bearing are read for clockwise arcs, which `R` used to
  hide.
- Airspace and heliport approach continuation records are no longer decoded as
  extra boundaries or legs.
- An approach transition reports the approach type of the procedure it serves.
  The type was taken from each route's own route type, so every transition
  reported `transition` rather than, say, `ils`. `Approach.routeType`,
  `runwayId`, and `multipleIndicator`, which were always `nil`, now say whether
  the route is a transition or the final approach and name the runway and
  multiple indicator from the approach identifier.
- Heliport approaches are built per transition, like airport approaches, with
  their approach type, transition, and missed approach legs. Every route of a
  procedure used to be merged into one leg list ordered by sequence number.

### Changed

- **BREAKING:** `WaypointDescriptionCode` names its columns for what they
  hold. `position1` through `position4` are now `fixType`, `fixStatus`,
  `fixFunction`, and `approachRole`, typed by the nested `FixType`,
  `FixStatus`, `FixFunction`, and `ApproachRole` enums, which replace
  `WaypointDescPosition1` through `WaypointDescPosition4`. Their cases match
  each column's published codes, and `FixType.transition` is now
  `transitionEssential`. The type adds `code`, `isIAF`, `isIntermediateFix`,
  `isFACF`, and `isFirstMissedApproachLeg`.
- **BREAKING:** `Approach.routeType` is a non-optional `Approach.RouteType`
  (`transition`, `finalApproach`, or `missedApproach`), replacing the
  `ApproachRouteType` enum, whose cases had no counterpart in the data.
  `ApproachType` loses `transition` and `missedApproach`, which are route types
  rather than approach types, and `AggregationErrorReason.invalidApproachType`
  is gone. `HeliportApproach` gains `routeType`, and its `approachType` is no
  longer optional.
- **BREAKING:** `ProcedureLeg.routeDistanceNMOrMinutes` is now `length`, a
  `ProcedureLeg.Length` that is either a `distance` or a holding `time`.
- **BREAKING:** `AirwayRouteType`, `AirwayLevel`, and `DirectionRestriction`
  are now `Airway.RouteType`, `Airway.Level`, and
  `AirwayFix.DirectionRestriction`, with the codes ARINC 424 defines. Blank
  fields are `nil` rather than `undesignated`, `unspecified`, or `none`, so
  `Airway.level` is optional. `AggregationErrorReason.missingAirwayMetadata`
  is replaced by `missingRouteType`.
- **BREAKING:** `WaypointType` is a struct with `kind`, `function`, and
  `procedureUse` for its three columns. `EnrouteWaypoint.usageClass` is now
  `usage`, an `EnrouteWaypoint.Usage` whose blank column is `terminalOnly`
  per ARINC 424 field 5.82, plus `isRNAV`. `WaypointUsage` and
  `TerminalWaypoint.waypointUsage`, a field terminal waypoints don't carry,
  are gone.
- **BREAKING:** Types that belong to one model are nested in it:

  | 2.0.0 | Now |
  | --- | --- |
  | `MagVarDirection` | `MagneticVariation.Direction` |
  | `SIDRouteType`, `STARRouteType` | `SID.RouteType`, `STAR.RouteType` |
  | `PathPointType` | `PathPoint.Kind` |
  | `MSASector` | `MSA.Sector` |
  | `AirspaceClass` | `ControlledAirspace.Class` |
  | `RestrictiveAirspaceType` | `SpecialUseAirspace.Kind` |
  | `PublicMilitary` | `Airport.Use` |
  | `FileType` | `Header.FileType` |
  | `CIFPFormatError` | `CIFPError.FormatReason` |
  | `AggregationErrorReason` | `CIFPError.AggregationReason` |

- **BREAKING:** Properties are named for what they hold:

  | 2.0.0 | Now |
  | --- | --- |
  | `Airport.publicMilitary` | `Airport.use` |
  | `Airport.datumCode` (`DatumCode`) | `Airport.datum` (`GeodeticDatum`) |
  | `Airport.msaRecords`, `Heliport.msaRecords` | `minimumSafeAltitudes` |
  | `PathPoint.pathPointType` | `PathPoint.kind` |
  | `SpecialUseAirspace.restrictiveType` | `SpecialUseAirspace.kind` |
  | `ProcedureLeg.centerFix`, `centerFixObject` | `centerFixId`, `centerFix` |
  | `ProcedureLeg.recommendedNavaid`, `navaid` | `recommendedNavaidId`, `recommendedNavaid` |

  `MagneticVariation.Direction.true` is now `trueNorth`.
- **BREAKING:** The unused `NDBInfo`, `IFRCapability`, `WaypointNameFormat`,
  and `DMEType` enums are gone.
- **BREAKING:** `Approach.sbasServiceLevel`, `requiredNavPerformance`, and
  `lateralNavCapability` are replaced by `levelsOfService`, an
  `Approach.LevelsOfService`. `SBASServiceLevel` is now
  `Approach.SBASServiceLevel`, and `RequiredNavPerformance` and
  `LateralNavCapability` are gone.
- **BREAKING:** `AltitudeConstraint` follows ARINC 424 field 5.29. The `G`,
  `H`, `I`, `J`, `V`, `X`, and `Y` cases each pair the procedure altitude with
  a glide slope, glide slope intercept, or vertical path altitude.
  `conditionalAtOrAbove` covers `C`.
- **BREAKING:** `BoundaryVia` drops `end` and `returnToOrigin` and adds
  `arcByEdge`. The letters for `rhumbLine`, `arcClockwise`, and
  `arcCounterClockwise` change to `H`, `R`, and `L`.

- **BREAKING:** The platform floor rises to macOS 26, iOS 26, tvOS 26, watchOS
  26, and visionOS 26. CIFP fields are now decoded through `UTF8Span` over the
  record slice's own storage, and `UTF8Span` exists nowhere below that floor.
- **BREAKING:** Both async line reader iterators declare their error type. The
  file-backed reader throws `CIFPError.streamError`, wrapping the underlying
  `FileHandle` failure, which makes `CIFP(url:)` match its documented contract
  of throwing `CIFPError`. The generic byte-sequence reader propagates its
  source's own `Failure`, so a non-throwing source now yields a non-throwing
  sequence.
- Field decoding no longer copies each field into an `Array` before reading it.
  `toString()` and `toRawString()` run on roughly 101 call sites per record
  across hundreds of thousands of records, so that per-field allocation
  dominated the string side of parsing. Decoding over the slice's own storage is
  about 2.3x faster on a field-decode microbenchmark and produces byte-identical
  output, verified exhaustively over all one- and two-byte sequences, over 400k
  random and ASCII-biased fields, and end-to-end against a 60k-record synthetic
  corpus.
- Strict memory safety (SE-0458) is enabled, and every unsafe construct it
  surfaces is audited and marked.

## [2.0.0] - 2026-09-16

### Fixed

- Every NDB navaid in the distribution now survives parsing. `ndbNavaids` was
  keyed by identifier alone, but an NDB identifier is only unique within an
  ICAO region, so beacons sharing one overwrote each other as records were
  read. Cycle 2610 lost 32 of its 382 beacons that way, including three of the
  four distinct navaids named `IL`. Each entry now holds every beacon carrying
  that identifier, in the order the records appear in the file.
- A procedure leg naming a terminal navaid (section `PN`) resolves to nothing rather
  than to an enroute NDB that happens to share the identifier.
  `resolveFix(_:icaoRegion:sectionCode:airportId:)` had no case for `.terminalNavaid`, so
  the reference fell through to the catch-all that tries every table in turn and answered
  from the enroute NDB list. `Fix` carries no case for a `TerminalNavaid` and the FAA's
  CIFP publishes no `PN` records for one to name, so there is nothing correct to return:
  Brainerd's ILS and LOC RWY 34 missed-approach hold resolved to a beacon 1,237 NM away
  in Brownsville, Texas. Legs whose fix does not resolve already carry no coordinate,
  which is what such a leg now does.
- `SwiftCIFP_E2E` no longer loses its report when standard output is a file.
  It reopened `/dev/stdout` by path, with truncation, while the progress bar
  wrote to the standard output it already had. On Linux that path resolves
  through `/proc/self/fd`, so reopening a redirected file yields a second file
  description with its own offset and the two writers overwrite each other --
  `SwiftCIFP_E2E > report.txt` came back empty or mangled. The report is now
  written once to the standard output the process was given, and the progress
  bar draws on standard error, only when that is a terminal.

### Changed

- `ndbNavaids` on `CIFP`, `CIFPData`, and `CIFPDataSnapshot` is now
  `[String: [NDBNavaid]]` rather than `[String: NDBNavaid]`, so a lookup
  returns every beacon sharing the identifier. The new `ndbNavaidCount`
  totals every beacon rather than every identifier.
- `ndbNavaid(_:)` is gone, replaced by `ndbNavaid(_:icaoRegion:)`. An NDB
  identifier does not name a beacon on its own, so the bare lookup could only
  guess among the candidates.
- `resolveFix(_:sectionCode:airportId:)` and `resolveNavaid(_:sectionCode:)`
  take an `icaoRegion` argument, as do the `FixResolver` and `NavaidResolver`
  closures behind them. Procedure legs, airway fixes, MSA records, and the
  airspace types all carried the region already and now pass it, so a leg
  referencing one of the beacons that share an identifier resolves to the right
  one. A record naming no region resolves an NDB only where the identifier is
  unambiguous.

## [1.3.0] - 2026-09-14

### Changed

- Lowered the platform floor to macOS 13, iOS 16, watchOS 9, tvOS 16, and
  visionOS 1, down from 26 on every platform. The manifest had required
  releases far newer than anything the package uses — `TimeZone.gmt` is the
  newest API it touches — so apps that have not moved to the 26 releases can
  now adopt the library unchanged.
- Raised the minimum version of two package dependencies: swift-argument-parser
  1.8.2 and swift-docc-plugin 1.5.0.

### Fixed

- Parsing a truncated record no longer traps. `slice(_:)` clamped only its upper
  bound, so a field whose range began past the end of a short line produced an
  inverted range and an uncatchable runtime failure that took down the host app.
  Both bounds are now clamped, and an out-of-range field reads as empty — which
  routes the record to `errorCallback` as a missing required field, matching the
  short-line tolerance the single-byte field reads already had.

## [1.2.0] - 2026-07-06

### Added

- Linux support. `URLSession` is guarded behind `FoundationNetworking`, a
  `String(localized:)` shim covers error strings, and numeric interpolation in
  error messages uses `.formatted(.number)` in place of the Linux-unavailable
  `\(value, format:)` sugar. The end-to-end tool's progress display now polls
  `Progress.fractionCompleted` instead of using KVO (unavailable on Linux).

## [1.1.0] - 2026-06-26

### Changed

- Adopted Swift's Approachable Concurrency upcoming features
  (`NonisolatedNonsendingByDefault` and `InferIsolatedConformances`). The public
  `async` entry points (`CIFP(url:)`, `CIFP(bytes:)`, and `linked()`) now run on
  the caller's executor by default, and the streaming line readers are annotated
  `@concurrent` so file and byte iteration keep running off the caller's
  executor. No public signatures changed.

### Internal

- Removed the remaining `nonisolated(unsafe)` escape hatches: the two
  header-parsing regexes are now compiled once per parse on the builder instead
  of stored as shared unsafe statics.
- Dropped a vestigial `@preconcurrency` from `import RegexBuilder`; the module is
  fully `Sendable`-audited under Swift 6.

## [1.0.0] - 2026-01-17

Initial release.
