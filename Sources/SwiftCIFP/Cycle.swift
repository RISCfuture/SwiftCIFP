import Foundation

/// AIRAC (Aeronautical Information Regulation and Control) cycle.
///
/// AIRAC cycles are 28 days in length and start on predetermined dates.
/// There are 13 cycles per year.
public struct Cycle: Sendable, Codable, Equatable, Hashable {
  /// Two-digit year (e.g., 26 for 2026).
  public let year: UInt

  /// Cycle number within the year (01-13).
  public let cycleNumber: UInt8

  /// Creates an AIRAC cycle.
  ///
  /// - Parameters:
  ///   - year: Two-digit year (will be converted to 4-digit).
  ///   - cycleNumber: Cycle number (1-13).
  init(year: UInt, cycleNumber: UInt8) {
    self.year = year < 100 ? 2000 + year : year
    self.cycleNumber = cycleNumber
  }

  /// Creates a cycle from the YYMM format used in CIFP.
  ///
  /// - Parameter yymm: Four-character string in YYMM format.
  init?(yymm: String) {
    guard yymm.count == 4 else { return nil }
    let yearStr = yymm.prefix(2)
    let cycleStr = yymm.suffix(2)
    guard let y = UInt(yearStr), let c = UInt8(cycleStr) else { return nil }
    self.year = 2000 + y
    self.cycleNumber = c
  }
}

// MARK: - AIRAC Date Calculation

extension Cycle {
  /// AIRAC reference date (January 25, 2024 is cycle 2401).
  private static let referenceDate: Date = {
    var components = DateComponents()
    components.year = 2024
    components.month = 1
    components.day = 25
    components.timeZone = .gmt
    return Calendar(identifier: .gregorian).date(from: components)!
  }()

  /// AIRAC cycle length in days.
  private static let cycleLengthDays = 28

  /// The current AIRAC cycle.
  public static var current: Self {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date()

    let daysSinceRef = calendar.dateComponents([.day], from: referenceDate, to: now).day ?? 0
    let totalCycles = daysSinceRef / cycleLengthDays

    // Calculate year and cycle within year
    let year = 2024 + (totalCycles / 13)
    let cycleInYear = (totalCycles % 13) + 1

    return Self(year: UInt(year), cycleNumber: UInt8(cycleInYear))
  }

  /// The effective date of this cycle.
  public var effectiveDate: Date? {
    let calendar = Calendar(identifier: .gregorian)

    // Calculate days from reference
    let yearsFromRef = Int(year) - 2024
    let cyclesInPrevYears = yearsFromRef * 13
    let totalCycles = cyclesInPrevYears + Int(cycleNumber) - 1

    return calendar.date(
      byAdding: .day,
      value: totalCycles * Self.cycleLengthDays,
      to: Self.referenceDate
    )
  }

  /// The expiration date of this cycle (day before next cycle).
  public var expirationDate: Date? {
    guard let effectiveDate else { return nil }
    let calendar = Calendar(identifier: .gregorian)
    return calendar.date(byAdding: .day, value: Self.cycleLengthDays - 1, to: effectiveDate)
  }
}

// MARK: - Cycle Navigation

extension Cycle {
  /// The previous cycle.
  public var previous: Self {
    if cycleNumber > 1 {
      return Self(year: year, cycleNumber: cycleNumber - 1)
    }
    return Self(year: year - 1, cycleNumber: 13)
  }

  /// The next cycle.
  public var next: Self {
    if cycleNumber < 13 {
      return Self(year: year, cycleNumber: cycleNumber + 1)
    }
    return Self(year: year + 1, cycleNumber: 1)
  }

  /// Whether this cycle is currently effective.
  public var isCurrent: Bool {
    self == Self.current
  }
}

// MARK: - String Representation

extension Cycle {
  /// The YYMM string representation.
  public var yymm: String {
    String(format: "%02d%02d", year % 100, cycleNumber)
  }

  /// The full 4-digit year.
  public var fullYear: Int {
    Int(year)
  }
}

// MARK: - Comparable

extension Cycle: Comparable {
  public static func < (lhs: Cycle, rhs: Cycle) -> Bool {
    if lhs.year != rhs.year {
      return lhs.year < rhs.year
    }
    return lhs.cycleNumber < rhs.cycleNumber
  }
}

// MARK: - Identifiable

extension Cycle: Identifiable {
  public var id: String { yymm }
}

// MARK: - CustomStringConvertible

extension Cycle: CustomStringConvertible {
  public var description: String {
    "AIRAC \(yymm)"
  }
}
