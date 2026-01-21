import Foundation

/// ILS (Instrument Landing System)/MLS (Microwave Landing System) approach category.
public enum ILSCategory: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// ILS Category I.
  case catI = "1"

  /// ILS Category II.
  case catII = "2"

  /// ILS Category IIIa.
  case catIIIA = "3"

  /// ILS Category IIIb.
  case catIIIB = "A"

  /// ILS Category IIIc.
  case catIIIC = "B"

  /// Localizer only (no glide slope).
  case localizerOnly = "L"

  /// LDA (Localizer-type Directional Aid).
  case lda = "D"

  /// SDF (Simplified Directional Facility).
  case sdf = "S"

  /// IGS (Interim Standard Microwave Landing System Glide Slope).
  case igs = "G"

  /// ILS/DME.
  case ilsDME = "E"

  /// MLS.
  case mls = "M"

  public var description: String {
    switch self {
      case .catI: "CAT I"
      case .catII: "CAT II"
      case .catIIIA: "CAT IIIA"
      case .catIIIB: "CAT IIIB"
      case .catIIIC: "CAT IIIC"
      case .localizerOnly: "LOC"
      case .lda: "LDA"
      case .sdf: "SDF"
      case .igs: "IGS"
      case .ilsDME: "ILS/DME"
      case .mls: "MLS"
    }
  }
}
