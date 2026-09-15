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

  /// Whether to animate a progress bar.
  ///
  /// Redirected output is a report for something else to read, not a screen to animate, so the
  /// bar appears only when standard error is a terminal.
  private static var showsProgress: Bool {
    isatty(STDERR_FILENO) != 0
  }

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
      let filename = unsafe String(format: Self.cifpFilenameFormat, year % 100, month, day)
      guard let url = URL(string: unsafe String(format: Self.cifpURLFormat, filename)) else {
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

    // The bar draws on standard error, so it no longer has to be withheld from a format
    // that writes to standard output.
    let progressTracker = Self.showsProgress ? ProgressTracker() : nil

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
        if let reason = (error as? (any LocalizedError))?.failureReason {
          message += "\n - \(reason)"
        }
        FileHandle.standardError.printError(message)
      }
    )

    // Clean up observation
    if let progressTracker {
      await progressTracker.stop()
      FileHandle.standardError.write("\r\u{1B}[K")  // Clear progress line
    }

    let elapsed = Date().timeIntervalSince(startTime)

    let formatter: any OutputFormatter =
      switch format {
        case .summary: SummaryOutputFormatter()
        case .json: JSONOutputFormatter()
      }
    let report = try await formatter.report(cifp: cifp, errorCount: errorCount, elapsed: elapsed)
    try FileHandle.standardOutput.write(contentsOf: report)
  }

  enum OutputFormat: String, ExpressibleByArgument {
    case summary
    case json
  }
}

// MARK: - ProgressTracker

/// Actor to safely track progress using Progress.swift library.
///
/// Polls `fractionCompleted` on a timer rather than observing it via KVO, since
/// `NSKeyValueObservation` requires the Objective-C runtime and isn't available on Linux.
private actor ProgressTracker {
  private var bar: ProgressBar
  private var lastPercent = 0
  private var pollTask: Task<Void, Never>?

  init() {
    bar = ProgressBar(
      count: 100,
      configuration: [
        ProgressString(string: "Parsing:"),
        ProgressPercent(),
        ProgressBarLine(barLength: 40)
      ],
      printer: StandardErrorProgressPrinter()
    )
  }

  func track(_ progress: Foundation.Progress) {
    pollTask = Task {
      while !Task.isCancelled, !progress.isFinished {
        update(to: Int(progress.fractionCompleted * 100))
        try? await Task.sleep(for: .milliseconds(50))
      }
      update(to: Int(progress.fractionCompleted * 100))
    }
  }

  private func update(to percent: Int) {
    while lastPercent < percent {
      bar.next()
      lastPercent += 1
    }
  }

  func stop() {
    pollTask?.cancel()
    pollTask = nil
  }
}

// MARK: - StandardErrorProgressPrinter

/// Draws the progress bar on standard error, leaving standard output to the report alone.
private struct StandardErrorProgressPrinter: ProgressBarPrinter {
  private var lastPrintedTime = 0.0

  init() {
    // Each redraw moves the cursor up a line first, so it needs one to move up into.
    FileHandle.standardError.write("\n")
  }

  mutating func display(_ progressBar: ProgressBar) {
    let now = Date().timeIntervalSince1970
    guard now - lastPrintedTime > 0.1 || progressBar.index == progressBar.count else { return }
    FileHandle.standardError.write("\u{1B}[1A\u{1B}[K\(progressBar.value)\n")
    lastPrintedTime = now
  }
}
