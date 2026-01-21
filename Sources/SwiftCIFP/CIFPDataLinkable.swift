import Foundation

/// Protocol for CIFP models that can link back to CIFPData for relationship resolution.
///
/// Models conforming to this protocol can access related models through
/// the `data` property, enabling async computed properties that resolve
/// string identifiers to actual model objects.
///
/// - Note: Conforming types should declare the `data` property as `weak`
///   to avoid retain cycles with the parent `CIFPData` actor.
protocol CIFPDataLinkable {
  /// Reference to the parent CIFPData container.
  ///
  /// This property is set by `CIFPData` when establishing model links.
  /// Use it in async computed properties to look up related models.
  var data: CIFPData? { get set }
}

/// Closure type for resolving a fix identifier to a Fix object.
///
/// - Parameters:
///   - identifier: The fix identifier string.
///   - sectionCode: Optional section code indicating fix type.
///   - airportId: Optional airport identifier for terminal waypoint resolution.
/// - Returns: The resolved Fix, or nil if not found.
typealias FixResolver =
  @Sendable (
    _ identifier: String,
    _ sectionCode: SectionCode?,
    _ airportId: String?
  ) async -> Fix?

/// Closure type for resolving a navaid identifier to a Navaid object.
///
/// - Parameters:
///   - identifier: The navaid identifier string.
///   - sectionCode: Optional section code indicating navaid type.
/// - Returns: The resolved Navaid, or nil if not found.
typealias NavaidResolver =
  @Sendable (
    _ identifier: String,
    _ sectionCode: String?
  ) async -> Navaid?

/// Protocol for procedure models that contain legs requiring closure injection.
///
/// Procedures (SID, STAR, Approach) contain nested `ProcedureLeg` structures
/// that need to resolve fix and navaid references. Since nested structs cannot
/// hold weak references, they use closure injection instead.
protocol ProcedureLinkable: CIFPDataLinkable {
  /// Injects fix and navaid resolver closures into the procedure's legs.
  ///
  /// This method is called by `CIFPData` after setting the `data` property
  /// to enable fix resolution in procedure legs.
  ///
  /// - Parameters:
  ///   - findFix: Closure to resolve fix identifiers to Fix objects.
  ///   - findNavaid: Closure to resolve navaid identifiers to Navaid objects.
  mutating func injectLegResolvers(
    findFix: @escaping FixResolver,
    findNavaid: @escaping NavaidResolver
  )
}

/// Protocol for airway models that contain fixes requiring closure injection.
///
/// Airways contain nested `AirwayFix` structures that need to resolve
/// fix references. Since nested structs cannot hold weak references,
/// they use closure injection instead.
protocol AirwayLinkable: CIFPDataLinkable {
  /// Injects fix resolver closures into the airway's fixes.
  ///
  /// - Parameter findFix: Closure to resolve fix identifiers to Fix objects.
  mutating func injectFixResolvers(findFix: @escaping FixResolver)
}
