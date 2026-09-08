# Change Log

## [Unreleased]

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
