public import Foundation

extension Approach {
  /// The lines of minimums an approach publishes and whether each is authorized (ARINC 424
  /// fields 5.275 and 5.276, from the approach's level of service continuation record).
  public struct LevelsOfService: Sendable, Codable, Equatable, Hashable {
    /// The authorized SBAS level of service (LPV, LPV200, or LP), or nil if none is.
    public let sbasServiceLevel: SBASServiceLevel?

    /// Whether LNAV/VNAV minimums are authorized, or nil if the record doesn't say.
    public let isLNAVVNAVAuthorized: Bool?

    /// Whether LNAV minimums are authorized, or nil if the record doesn't say.
    public let isLNAVAuthorized: Bool?

    /// The RNP values an RNP AR approach is authorized to, in the order published.
    public let authorizedRNP: [Measurement<UnitLength>]
  }

  /// A level of service flown with an SBAS final approach segment.
  public enum SBASServiceLevel: String, Sendable, Codable, CaseIterable {
    /// Localizer performance with vertical guidance (LPV).
    case lpv = "LPV"

    /// LPV to a 200-foot decision altitude (LPV200).
    case lpv200 = "LPV200"

    /// Localizer performance without vertical guidance (LP).
    case lp = "LP"
  }
}
