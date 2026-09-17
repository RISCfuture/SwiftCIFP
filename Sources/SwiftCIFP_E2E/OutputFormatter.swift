import Foundation
import SwiftCIFP

/// Protocol for formatting CIFP output.
protocol OutputFormatter {
  /// Renders the parsed data as the bytes of a report.
  ///
  /// Formatters return their report rather than writing it, so the caller owns the single
  /// write to standard output.
  ///
  /// - Parameters:
  ///   - cifp: The parsed CIFP data.
  ///   - errorCount: Number of parse errors encountered.
  ///   - elapsed: Time taken to load and parse.
  /// - Returns: The encoded report.
  func report(cifp: CIFP, errorCount: Int, elapsed: TimeInterval) async throws -> Data
}

// MARK: - SummaryOutputFormatter

/// Formats CIFP data as a human-readable summary.
struct SummaryOutputFormatter: OutputFormatter {
  func report(cifp: CIFP, errorCount: Int, elapsed: TimeInterval) -> Data {
    .init(lines(for: cifp, errorCount: errorCount, elapsed: elapsed).joined(separator: "\n").utf8)
  }

  private func lines(for cifp: CIFP, errorCount: Int, elapsed: TimeInterval) -> [String] {
    let children = ChildRecordCounts(of: cifp)
    return [
      "",
      "=== CIFP Summary ===",
      "Cycle: \(cifp.cycle)",
      "Parse time: \(String(format: "%.2f", elapsed)) seconds",
      "Errors: \(errorCount)",
      "",
      "Record counts:",
      "  Airports:           \(cifp.airports.count)",
      "  Runways:            \(children.runways)",
      "  VHF Navaids:        \(cifp.vhfNavaids.count)",
      "  NDB Navaids:        \(cifp.ndbNavaidCount)",
      "  Enroute Waypoints:  \(cifp.enrouteWaypoints.count)",
      "  Terminal Waypoints: \(children.terminalWaypoints)",
      "  Airways:            \(cifp.airways.count)",
      "  SIDs:               \(children.sids)",
      "  STARs:              \(children.stars)",
      "  Approaches:         \(children.approaches)",
      "  Localizers:         \(children.localizers)",
      "  Grid MORAs:         \(cifp.gridMORAs.count)",
      "  MSA Records:        \(children.msaRecords)",
      "  Path Points:        \(children.pathPoints)",
      "  Ctrl. Airspace:     \(cifp.controlledAirspaces.count)",
      "  SUA:                \(cifp.specialUseAirspaces.count)",
      "  Heliports:          \(cifp.heliports.count)",
      "",
      "Total records:        \(cifp.totalRecordCount)",
      ""
    ]
  }

  /// Tallies of the child records folded into each airport.
  private struct ChildRecordCounts {
    var runways = 0,
      terminalWaypoints = 0,
      sids = 0,
      stars = 0,
      approaches = 0,
      localizers = 0,
      msaRecords = 0,
      pathPoints = 0

    init(of cifp: CIFP) {
      for airport in cifp.airports.values {
        runways += airport.runways.count
        terminalWaypoints += airport.terminalWaypoints.count
        sids += airport.sids.count
        stars += airport.stars.count
        approaches += airport.approaches.count
        localizers += airport.localizers.count
        msaRecords += airport.msaRecords.count
        pathPoints += airport.pathPoints.count
      }
    }
  }
}

// MARK: - JSONOutputFormatter

/// Formats CIFP data as JSON.
struct JSONOutputFormatter: OutputFormatter {
  func report(cifp: CIFP, errorCount _: Int, elapsed _: TimeInterval) async throws -> Data {
    // Use linked data for hierarchical JSON output
    let linkedData = await cifp.linked()
    let snapshot = await linkedData.snapshot()

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(snapshot)
  }
}
