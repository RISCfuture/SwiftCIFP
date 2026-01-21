import Foundation
import SwiftCIFP

/// Protocol for formatting CIFP output.
protocol OutputFormatter {
  /// Format and output the CIFP data.
  /// - Parameters:
  ///   - cifp: The parsed CIFP data.
  ///   - errorCount: Number of parse errors encountered.
  ///   - elapsed: Time taken to load and parse.
  ///   - stream: The output stream to write to.
  func format(cifp: CIFP, errorCount: Int, elapsed: TimeInterval, to stream: OutputStream)
    async throws
}

// MARK: - OutputStream Extension

extension OutputStream {
  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    data.withUnsafeBytes { buffer in
      guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
      write(pointer, maxLength: buffer.count)
    }
  }

  func writeLine(_ string: String = "") {
    write("\(string)\n")
  }
}

// MARK: - SummaryOutputFormatter

/// Formats CIFP data as a human-readable summary.
struct SummaryOutputFormatter: OutputFormatter {
  func format(cifp: CIFP, errorCount: Int, elapsed: TimeInterval, to stream: OutputStream)
    throws
  {
    stream.writeLine()
    stream.writeLine("=== CIFP Summary ===")
    stream.writeLine("Cycle: \(cifp.cycle)")
    stream.writeLine("Parse time: \(String(format: "%.2f", elapsed)) seconds")
    stream.writeLine("Errors: \(errorCount)")
    stream.writeLine()

    var runwayCount = 0,
      terminalWaypointCount = 0,
      sidCount = 0,
      starCount = 0,
      approachCount = 0,
      localizerCount = 0,
      msaCount = 0,
      pathPointCount = 0
    for airport in cifp.airports.values {
      runwayCount += airport.runways.count
      terminalWaypointCount += airport.terminalWaypoints.count
      sidCount += airport.sids.count
      starCount += airport.stars.count
      approachCount += airport.approaches.count
      localizerCount += airport.localizers.count
      msaCount += airport.msaRecords.count
      pathPointCount += airport.pathPoints.count
    }

    stream.writeLine("Record counts:")
    stream.writeLine("  Airports:           \(cifp.airports.count)")
    stream.writeLine("  Runways:            \(runwayCount)")
    stream.writeLine("  VHF Navaids:        \(cifp.vhfNavaids.count)")
    stream.writeLine("  NDB Navaids:        \(cifp.ndbNavaids.count)")
    stream.writeLine("  Enroute Waypoints:  \(cifp.enrouteWaypoints.count)")
    stream.writeLine("  Terminal Waypoints: \(terminalWaypointCount)")
    stream.writeLine("  Airways:            \(cifp.airways.count)")
    stream.writeLine("  SIDs:               \(sidCount)")
    stream.writeLine("  STARs:              \(starCount)")
    stream.writeLine("  Approaches:         \(approachCount)")
    stream.writeLine("  Localizers:         \(localizerCount)")
    stream.writeLine("  Grid MORAs:         \(cifp.gridMORAs.count)")
    stream.writeLine("  MSA Records:        \(msaCount)")
    stream.writeLine("  Path Points:        \(pathPointCount)")
    stream.writeLine("  Ctrl. Airspace:     \(cifp.controlledAirspaces.count)")
    stream.writeLine("  SUA:                \(cifp.specialUseAirspaces.count)")
    stream.writeLine("  Heliports:          \(cifp.heliports.count)")
    stream.writeLine()
    stream.writeLine("Total records:        \(cifp.totalRecordCount)")
  }
}

// MARK: - JSONOutputFormatter

/// Formats CIFP data as JSON.
struct JSONOutputFormatter: OutputFormatter {
  func format(cifp: CIFP, errorCount _: Int, elapsed _: TimeInterval, to stream: OutputStream)
    async throws
  {
    // Use linked data for hierarchical JSON output
    let linkedData = await cifp.linked()
    let snapshot = await linkedData.snapshot()

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(snapshot)
    jsonData.withUnsafeBytes { buffer in
      guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
      stream.write(pointer, maxLength: buffer.count)
    }
  }
}
