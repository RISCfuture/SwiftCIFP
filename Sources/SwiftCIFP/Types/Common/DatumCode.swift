import Foundation

/// Geodetic datum code indicating the coordinate reference system.
///
/// ARINC 424 defines these codes to specify which geodetic datum
/// coordinates are referenced to. Modern data typically uses WGS-84.
public enum DatumCode: String, Sendable, Codable, Equatable, Hashable, CaseIterable {
  // MARK: - World Geodetic Systems

  /// World Geodetic System 1984 (WGS-84) - current standard
  case wgs84 = "WGE"

  /// World Geodetic System 1972
  case wgs72 = "WGC"

  /// World Geodetic System 1966
  case wgs66 = "WGB"

  /// World Geodetic System 1960
  case wgs60 = "WGA"

  // MARK: - North American Datums

  /// North American Datum 1927
  case nad27 = "NAS"

  /// North American Datum 1927 Caribbean
  case nad27Caribbean = "NAT"

  /// North American Datum 1927 Mexico and Central America
  case nad27Mexico = "NAU"

  /// North American Datum 1983
  case nad83 = "NAR"

  // MARK: - European Datums

  /// European Datum 1950
  case european1950 = "EUR"

  /// European Datum 1979
  case european1979 = "EUS"

  /// Ordnance Survey of Great Britain 1936
  case osgb36 = "OGB"

  /// Potsdam (Germany)
  case potsdam = "PDM"

  /// Berne 1873 (Switzerland)
  case berne1873 = "BRN"

  /// CH-1903 (Switzerland)
  case ch1903 = "CHI"

  /// Danish GI 1934
  case danish1934 = "DAN"

  /// Reykjavik (Iceland)
  case reykjavik = "REY"

  /// Hjorsey 1955 (Iceland)
  case hjorsey1955 = "HJO"

  /// Ireland 1965
  case ireland1965 = "IRL"

  /// Belgium 1950
  case belgium1950 = "BEL"

  /// RNB 72 (Belgium)
  case rnb72 = "RNB"

  /// Netherlands Triangulation 1921
  case netherlands1921 = "NTH"

  /// Nouvelle Triangulation de France
  case ntfFrance = "IGF"

  /// Nouvelle Triangulation de France (Luxembourg)
  case ntfLuxembourg = "IGL"

  /// Rome 1940
  case rome1940 = "MOD"

  /// Portuguese Datum DLX
  case portugueseDLX = "DLX"

  /// Portuguese Datum 1973
  case portuguese1973 = "PRD"

  /// RT90 (Sweden)
  case rt90 = "STO"

  /// Austria NS
  case austriaNS = "ANS"

  /// GGRS 87 (Greece)
  case ggrs87 = "GRX"

  /// Spitzbergen (Norway)
  case spitzbergen = "SPZ"

  // MARK: - African Datums

  /// Adindan
  case adindan = "ADI"

  /// Afgooye (Somalia)
  case afgooye = "AFG"

  /// Arc 1950 (Africa)
  case arc1950 = "ARF"

  /// Arc 1960
  case arc1960 = "ARS"

  /// Cape (South Africa)
  case cape = "CAP"

  /// Carthage
  case carthage = "CGE"

  /// Liberia 1964 (Roberts Field Astro)
  case liberia1964 = "LIB"

  /// Mahe 1971 (Mahe Island)
  case mahe1971 = "MIK"

  /// Merchich (Morocco)
  case merchich = "MER"

  /// Minna (Nigeria)
  case minna = "MIN"

  /// Nigeria
  case nigeria = "NIG"

  /// Massawa (Eritrea, Ethiopia)
  case massawa = "MAS"

  /// Old Egyptian 1930
  case oldEgyptian1930 = "OEG"

  /// Sierra Leone 1960
  case sierraLeone1960 = "SRL"

  /// Schwarzeck (Southwest Africa)
  case schwarzeck = "SCK"

  /// Tananarive Observatory 1925 (Madagascar)
  case tananarive1925 = "TAN"

  /// Voirol (Algeria)
  case voirol = "VOI"

  /// Mozambique
  case mozambique = "MOZ"

  // MARK: - Asian Datums

  /// Tokyo
  case tokyo = "TOY"

  /// Indian
  case indian = "IND"

  /// Kandawala (Sri Lanka)
  case kandawala = "KAN"

  /// Pidurutal Agala (Sri Lanka)
  case pidurutalAgala = "PID"

  /// Kertau 1948
  case kertau1948 = "KEA"

  /// Timbalai 1948 (Borneo)
  case timbalai1948 = "TIL"

  /// Hong Kong 1963
  case hongKong1963 = "HKD"

  /// Hu-Tzu-Shan (Taiwan)
  case huTzuShan = "HTN"

  /// Luzon (Philippines)
  case luzon = "LUZ"

  /// South Asia Datum
  case southAsia = "SOA"

  /// Herat North (Afghanistan)
  case heratNorth = "HEN"

  /// Nahrwan
  case nahrwan = "NAH"

  /// Oman (Fahud)
  case oman = "FAH"

  /// Qatar National Datum
  case qatarNational = "QAT"

  /// Ain El Abd 1970 (Bahrain)
  case ainElAbd1970 = "AIN"

  /// Pulkovo 1942 (USSR)
  case pulkovo1942 = "PUK"

  /// Pulkovo 1932 (USSR)
  case pulkovo1932 = "PKO"

  /// Tsingtao Observatory (China)
  case tsingtao = "TSO"

  /// Nanking 1960
  case nanking1960 = "NAN"

  /// Manchurian Principal System
  case manchurian = "MCN"

  // MARK: - Australian/Pacific Datums

  /// Australian Geodetic
  case australianGeodetic = "AUA"

  /// AGD 1966
  case agd1966 = "AGE"

  /// AGD 1984
  case agd1984 = "AGD"

  /// Sydney Observatory (New South Wales)
  case sydneyObservatory = "SYO"

  /// Geodetic Datum 1949 (New Zealand)
  case newZealand1949 = "GEO"

  /// Monavatu (Viti Levu, Fiji)
  case monavatu = "MVS"

  /// Guam 1963
  case guam1963 = "GUA"

  /// Anna 1 Astro 1965 (Cocos Islands)
  case anna1Astro1965 = "ANO"

  /// Johnston Island 1961
  case johnstonIsland1961 = "JOH"

  /// Midway Astro 1961
  case midwayAstro1961 = "MID"

  /// Wake Island Astro 1952
  case wakeIsland1952 = "WAK"

  /// Wake-Eniwetok 1960
  case wakeEniwetok1960 = "ENW"

  /// Canton Island Astro 1966
  case cantonIsland1966 = "CAO"

  /// Ponape Astro 1962
  case ponapeAstro1962 = "PON"

  /// Taongi Astro 1952
  case taongiAstro1952 = "TAO"

  /// Marcus Astro 1961
  case marcusAstro1961 = "MCS"

  /// Marcus Astro 1965
  case marcusAstro1965 = "MAX"

  /// Astronomic Station 1952 (Marcus Island)
  case astronomicStation1952 = "ASI"

  /// Lemuta (Samoa Islands)
  case lemutaSamoa = "LEM"

  /// Vaitape Flagstaff (Borabora, Society Islands)
  case vaitapeFlagstaff = "VBS"

  /// Bellevue IGN (New Hebrides)
  case bellevueIGN = "IBE"

  /// Santo DOS (Espirito Santo Island)
  case santoDOS = "SAE"

  // MARK: - South American Datums

  /// South American 1969
  case southAmerican1969 = "SAN"

  /// Provisional South American 1956
  case provisionalSouthAmerican1956 = "PRP"

  /// La Canoa (Venezuela)
  case laCanoa = "LAC"

  /// Bogota Observatorio (Colombia)
  case bogotaObservatorio = "BOO"

  /// Campo Inchauspe (Argentina)
  case campoInchauspe = "CAI"

  /// Chua Astro
  case chuaAstro = "CHU"

  /// Corrego Alegre (Brazil)
  case corregoAlegre = "COA"

  /// Pronto Socorro (Brazil)
  case prontoSocorro = "PRS"

  /// Provisional Chilean 1963
  case provisionalChilean1963 = "PRC"

  /// Hito XVIII Astro (Chile)
  case hitoXVIIIAstro = "HIT"

  /// Yacare (Uruguay)
  case yacare = "YAC"

  // MARK: - Caribbean/Central American Datums

  /// Puerto Rico
  case puertoRico = "PUR"

  /// Old Hawaiian
  case oldHawaiian = "OHA"

  /// Bermuda 1957
  case bermuda1957 = "BER"

  /// Cape Canaveral
  case capeCanaveral = "CAC"

  /// Naparima (BWI)
  case naparima = "NAP"

  /// L.C. 5 Astro (Cayman Brac Island)
  case lc5Astro = "LCF"

  /// Trinidad Trigonometrical Survey (Lesser Antilles)
  case trinidadSurvey = "TRI"

  /// Zanderij (Suriname)
  case zanderij = "ZAN"

  // MARK: - Atlantic Island Datums

  /// Ascension Island 1958
  case ascensionIsland1958 = "ASC"

  /// Astro DOS 71/4 (St. Helena Island)
  case astroDOS714 = "ASQ"

  /// Tristan Astro 1968 (Tristan da Cunha)
  case tristanAstro1968 = "TDC"

  /// Observatorio 1966 (Corvo and Flores, Azores)
  case observatorio1966 = "OCF"

  /// Sao Braz (Sao Miguel and Santa Maria, Azores)
  case saoBraz = "SAO"

  /// SW Base (Azores)
  case swBase = "SWB"

  /// Pico de las Nieves (Gran Canaria)
  case picoDeLasNieves = "PLN"

  /// SE Base (Madeira and Porto Santo)
  case seBase = "SEB"

  /// Qornoq (Greenland)
  case qornoq = "QUO"

  // MARK: - Indonesian Datums

  /// Djakarta/Batavia (Indonesia)
  case djakarta = "BAT"

  /// Bukit Rimpah (Indonesia)
  case bukitRimpah = "BUR"

  /// G. Segara (Indonesia)
  case gSegara = "GSE"

  /// Montjong Lowe (Indonesia)
  case montjongLowe = "MOL"

  // MARK: - Indian Ocean Datums

  /// Reunion (Mascarene Islands)
  case reunion = "REU"

  /// Kerguelen Island
  case kerguelenIsland = "KEG"

  /// Gandajika Base (Maldives)
  case gandajikaBase = "GAN"

  /// SE Island (Seychelles)
  case seIslandSeychelles = "SEI"

  /// Chatham Island Observatory (Port Blair, Andaman Islands)
  case chathamIsland = "CHO"

  // MARK: - Other Pacific Datums

  /// Easter Island 1967
  case easterIsland1967 = "EAS"

  /// Pitcairn Astro 1967
  case pitcairnAstro1967 = "PIT"

  /// ISTS 073 Astro 1969
  case ists073Astro1969 = "IST"

  /// Astro B4 Sorol Atoll (Tern Island)
  case astroB4SorolAtoll = "ASG"

  /// Astro Beacon E (Iwo Jima)
  case astroBeaconE = "ASF"

  /// DOS 1968 (Gizo Island)
  case dos1968 = "GIZ"

  /// DOS Astro GUX 1 (Guadalcanal)
  case dosAstroGUX1 = "DOB"

  /// Paga Hill 1939 (New Guinea)
  case pagaHill1939 = "PAH"

  // MARK: - Antarctic Datums

  /// Camp Area Astro
  case campAreaAstro = "CAZ"

  /// McMurdo Camp Area (Antarctica)
  case mcmurdoCampArea = "MCM"

  /// NMA/539 Wilkes Station (Antarctica)
  case wilkesStation = "NMW"

  /// Palmer Astro
  case palmerAstro = "PAM"

  /// Port Lockroy
  case portLockroy = "POR"

  // MARK: - Miscellaneous Datums

  /// Sapper Hill 1943
  case sapperHill1943 = "SAP"

  /// Mercury (Fischer 1960)
  case mercury1960 = "MET"

  /// Modified Mercury (Fischer 1968)
  case modifiedMercury1968 = "MOT"

  /// North Astro 1947
  case northAstro1947 = "NOT"

  /// Lee No. 7
  case leeNo7 = "LEE"

  /// Local Astro
  case localAstro = "LOC"

  /// Manira
  case manira = "MAQ"

  /// Marco Astro (Salvage Island)
  case marcoAstro = "MAT"

  /// Masira Island Astro 1958
  case masiraIsland1958 = "MAZ"

  /// Nikolskoe Astro 1929
  case nikolskoe1929 = "NIL"

  /// Pete Astro 1969
  case peteAstro1969 = "PET"

  /// Pico Norte
  case picoNorte = "PIC"

  /// Pico de Sao Tome (Sao Tome Island)
  case picoSaoTome = "PST"

  /// Table Hill
  case tableHill = "TAH"

  /// Yof Astro 1967
  case yofAstro1967 = "YOF"

  /// Over Water Areas
  case overWater = "N"
}
