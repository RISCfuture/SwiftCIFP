# ``CIFPData``

@Metadata {
  @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Creating CIFPData

- ``init(from:)``

### Metadata

- ``header``
- ``cycle``
- ``totalRecordCount``

### Navigation Data

- ``vhfNavaids``
- ``ndbNavaids``
- ``enrouteWaypoints``
- ``airways``
- ``gridMORAs``

### Airport Data

- ``airports``

### Airspace

- ``controlledAirspaces``
- ``specialUseAirspaces``

### Heliports

- ``heliports``

### Single-Record Lookup

- ``airport(_:)``
- ``vhfNavaid(_:)``
- ``ndbNavaid(_:)``
- ``enrouteWaypoint(_:)``
- ``terminalWaypoint(_:airportId:)``
- ``airway(_:)``
- ``runway(_:airportId:)``
- ``localizer(_:airportId:)``
- ``approach(_:airportId:)``
- ``heliport(_:)``

### Fix Resolution

- ``resolveFix(_:sectionCode:airportId:)``
- ``resolveNavaid(_:sectionCode:)``
