# Change Log

## [Unreleased]

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
