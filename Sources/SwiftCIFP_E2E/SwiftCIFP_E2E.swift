import ArgumentParser
import Foundation
import Progress
import SwiftCIFP

@main
struct SwiftCIFP_E2E: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "SwiftCIFP_E2E",
    abstract: "Parse and validate FAA CIFP data",
    discussion: """
      Parses CIFP data from a local file, ZIP archive, or remote URL.
      By default, downloads the current AIRAC cycle from the FAA.

      Examples:
        SwiftCIFP_E2E                                  (downloads current cycle)
        SwiftCIFP_E2E -i ~/Downloads/FAACIFP18
        SwiftCIFP_E2E -i ~/Downloads/CIFP_260122.zip
        SwiftCIFP_E2E -i https://aeronav.faa.gov/Upload_313-d/cifp/CIFP_260122.zip

      Errors encountered during parsing are printed to stderr.
      """
  )

  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }()

  private static let cifpFilenameFormat = "CIFP_%02d%02d%02d.zip"
  private static let cifpURLFormat = "https://aeronav.faa.gov/Upload_313-d/cifp/%@"

  @Option(
    name: .shortAndLong,
    help: "Path or URL to CIFP file (FAACIFP18 or .zip). Defaults to current FAA CIFP."
  )
  var input: String?

  /// URL to download the current CIFP cycle from the FAA.
  private var currentCycleURL: URL {
    get throws {
      let cycle = Cycle.effective
      guard let effectiveDate = cycle.effectiveDate else {
        throw ValidationError("Failed to calculate current cycle effective date")
      }
      guard let (year, month, day) = dateComponents(from: effectiveDate) else {
        throw ValidationError("Failed to extract date components from cycle")
      }
      let filename = String(format: Self.cifpFilenameFormat, year % 100, month, day)
      guard let url = URL(string: String(format: Self.cifpURLFormat, filename)) else {
        throw ValidationError("Failed to construct CIFP URL")
      }
      return url
    }
  }

  @Option(name: .shortAndLong, help: "Output format: summary or json")
  var format: OutputFormat = .summary

  @Flag(name: .shortAndLong, help: "Show verbose output")
  var verbose = false

  /// Extracts year, month, and day components from a date.
  private func dateComponents(from date: Date) -> (year: Int, month: Int, day: Int)? {
    let components = Self.calendar.dateComponents([.year, .month, .day], from: date)
    guard let year = components.year, let month = components.month, let day = components.day else {
      return nil
    }
    return (year, month, day)
  }

  mutating func run() async throws {
    let inputURL: URL
    if let input {
      // User provided input - parse as URL or file path
      if let url = URL(string: input), url.isHTTP {
        inputURL = url
      } else {
        inputURL = URL(filePath: input)
      }
    } else {
      // No input - use current FAA CIFP
      inputURL = try currentCycleURL
    }

    let loader = createLoader(for: inputURL)

    var errorCount = 0
    let startTime = Date()

    if verbose { print("Loading CIFP data…") }

    // Set up progress tracking using actor to safely hold observation
    // Only show progress bar for summary format to avoid corrupting JSON output
    let progressTracker = format == .summary ? ProgressTracker() : nil

    let cifp = try await loader.load(
      progressHandler: { progress in
        if let progressTracker {
          Task { await progressTracker.track(progress) }
        }
      },
      errorCallback: { error, line in
        errorCount += 1
        var message = if let line { "Error at line \(line): " } else { "Error: " }
        message += error.localizedDescription
        if let reason = (error as? LocalizedError)?.failureReason {
          message += "\n - \(reason)"
        }
        FileHandle.standardError.printError(message)
      }
    )

    // Clean up observation
    if let progressTracker {
      await progressTracker.stop()
      print("\r\u{1B}[K", terminator: "")  // Clear progress line
    }

    let elapsed = Date().timeIntervalSince(startTime)

    guard let stdout = OutputStream(toFileAtPath: "/dev/stdout", append: false) else {
      fatalError("Failed to open stdout")
    }
    stdout.open()
    defer { stdout.close() }

    let formatter: OutputFormatter =
      switch format {
        case .summary: SummaryOutputFormatter()
        case .json: JSONOutputFormatter()
      }
    try await formatter.format(cifp: cifp, errorCount: errorCount, elapsed: elapsed, to: stdout)
  }

  enum OutputFormat: String, ExpressibleByArgument {
    case summary
    case json
  }
}

// MARK: - ProgressTracker

/// Actor to safely track progress using Progress.swift library.
private actor ProgressTracker {
  private var bar: ProgressBar
  private var lastPercent = 0
  private var observation: NSKeyValueObservation?

  init() {
    bar = ProgressBar(
      count: 100,
      configuration: [
        ProgressString(string: "Parsing:"),
        ProgressPercent(),
        ProgressBarLine(barLength: 40)
      ]
    )
  }

  func track(_ progress: Foundation.Progress) {
    observation = progress.observe(\.fractionCompleted, options: [.new]) { prog, _ in
      let newPercent = Int(prog.fractionCompleted * 100)
      Task { await self.update(to: newPercent) }
    }
  }

  private func update(to percent: Int) {
    while lastPercent < percent {
      bar.next()
      lastPercent += 1
    }
  }

  func stop() {
    observation?.invalidate()
    observation = nil
  }
}
