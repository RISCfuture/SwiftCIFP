# ``ProcedureLeg``

@Metadata {
  @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Identification

- ``sequenceNumber``
- ``pathTerminator``
- ``waypointDescription``

### Fix Information

- ``fixId``
- ``fixICAO``
- ``fixSectionCode``

### Turn & Course

- ``turnDirection``
- ``isTurnDirectionValid``
- ``magneticCourseDeg``
- ``arcRadiusNM``

### Navaid Reference

- ``recommendedNavaid``
- ``recommendedNavaidICAO``
- ``thetaDeg``
- ``rhoNM``

### Distance & Route

- ``routeDistanceNMOrMinutes``
- ``rnpNM``

### Constraints

- ``altitudeConstraint``
- ``speedConstraint``
- ``transitionAltitudeFt``
- ``verticalAngleDeg``

### RF Leg Center Fix

- ``centerFix``
- ``centerFixICAO``

### Computed Properties

- ``isInitialFix``
- ``isHoldPattern``

### Linked Properties

- ``fix``
- ``navaid``
- ``centerFixObject``

### Measurement Extensions

- ``rnp``
- ``arcRadius``
- ``theta``
- ``rho``
- ``magneticCourse``
- ``transitionAltitude``
- ``speedLimit``
- ``verticalAngle``
