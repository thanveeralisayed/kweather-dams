# Product Requirements Document (PRD)

## Project Name: Kerala Weather & Dam Intelligence App ("K-Weather & Dams")
**Platform:** Flutter (Android first, iOS ready)  
**Author:** AI Engineering & Architecture Team  
**Date:** October 2026  
**Status:** Approved for Implementation  
**Workspace:** `c:\Users\thanv\kweather`  

---

## 1. Executive Summary & Vision
Kerala frequently experiences intense monsoon seasons, sudden cloudbursts, severe coastal storms, and fluctuating dam reservoirs. Citizens, travelers, farmers, fishermen, and emergency responders currently have to check multiple fragmented government portals—such as IMD Thiruvananthapuram and Kerala State Disaster Management Authority (KSDMA)—often buried inside PDF attachments and raw tabular reports.

**K-Weather & Dams** is a unified, high-performance Flutter Android application that consolidates:
1. **Hyper-local Weather & 7-Day Forecasts** for 23+ Kerala stations directly from IMD.
2. **Real-time 3-Hour Nowcast Alerts & 5-Day District Warning Color Codes** (Red, Orange, Yellow, Green).
3. **Daily Dam Water Levels & Shutter Openings** for all 37 major KSEB and Irrigation Department dams across Kerala.
4. **Live Visual Doppler Weather Radar (Kochi) & INSAT-3D Satellite Animations**.
5. **Specialized Bulletins:** Marine port warnings for fishermen, Sabarimala pilgrimage forecasts, and River Basin Flood QPF projections in both English and Malayalam.

---

## 2. Verified Data Sources & Ingestion Pipeline

### 2.1 Source Matrix

| Data Domain | Provider / Source URL | Format | Frequency | Extraction Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **City Forecast & Live Observations** | `https://city.imd.gov.in/citywx/responsive/api/fetchCity_static.php` | REST JSON | Hourly | Direct POST request with FormData (`ID=<station_id>`) & `Referer` header |
| **Station Directory** | `https://city.imd.gov.in/citywx/responsive/api/` | REST JSON | Static / Daily | Direct GET request with `Referer` header |
| **City Auto-search** | `https://city.imd.gov.in/citywx/responsive/api/search.php?query=` | REST JSON | On-demand | Direct GET request |
| **Severe Weather Nowcast (3-Hr)** | `https://mausam.imd.gov.in/imd_latest/contents/stationwise-nowcast-warning_mc.php?id=4` | HTML (Embedded JSON) | Every 3 Hours | Regex extraction of `countrydataprovider.images` array |
| **5-Day District Color Warnings** | `https://mausam.imd.gov.in/imd_latest/contents/districtwise-warning_mc.php?id=4&day=Day_1` | HTML (Embedded JSON) | Daily | Extract AmCharts `areas` array with `#hex` colors |
| **Doppler Radar (Kochi)** | `https://mausam.imd.gov.in/Radar/caz_koc.gif` | Animated GIF | Real-time | Direct `Image.network` stream with cache policy |
| **Satellite Imagery** | `https://mausam.imd.gov.in/Satellite/3Dasiasec_ir1.jpg` | JPEG | Real-time | Direct `Image.network` stream |
| **Dam Water Levels (KSEB & Irrigation)** | `https://sdma.kerala.gov.in/dam-water-level/` | HTML -> 2 PDFs (`kseb-site.pdf`, `IRR-site.pdf`) | Daily at 11:00 AM | Scrape PDF URLs from DOM; parse tabular PDF rows into structured JSON |
| **Marine & Port Warnings** | `https://mausam.imd.gov.in/thiruvananthapuram/mcdata/fishermen%20warning.pdf` | PDF Bulletin | 2-3 times daily | Parse port table (11 Kerala ports) & coastal warning text |
| **Sabarimala Weather** | `https://mausam.imd.gov.in/thiruvananthapuram/mcdata/sabarimala_forecast.pdf` | PDF Bulletin | Daily (Season) | Parse 3-day forecast table (Sannidhanam, Pamba, Nilakkal) |
| **River Basin Flood QPF** | `https://mausam.imd.gov.in/thiruvananthapuram/mcdata/qpf.pdf` | PDF Bulletin | Daily | Parse 7-day quantitative precipitation table for 11 river basins |

---

## 3. System Architecture & Ingestion Design

```
                     ┌───────────────────────────────────────────────┐
                     │          Official Government Sources          │
                     │  - IMD Thiruvananthapuram & CityWX (JSON/GIF) │
                     │  - KSDMA Dam Water Level Portal (HTML/PDFs)   │
                     └───────────────────────┬───────────────────────┘
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       │                                           │
                       ▼                                           ▼
          [Direct App Consumption]                    [Lightweight Parser / Cloud Worker]
     - IMD CityWX REST JSON API                   - Scheduled CRON (every 1-3 hrs)
     - Doppler Radar Animated GIF                 - Scrapes KSDMA HTML for active PDF links
     - INSAT-3D Satellite Images                  - Parses KSEB & Irrigation PDFs into JSON
     - IMD Station-wise Nowcast HTML              - Parses Fishermen, QPF, Sabarimala PDFs
                       │                                           │
                       │                                           ▼
                       │                             [Cached Edge CDN / Firebase / API]
                       │                                           │
                       └─────────────────────┬─────────────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │     Flutter Mobile App      │
                              │  - Riverpod State Mgmt      │
                              │  - Hive Local Cache         │
                              │  - Material 3 Glassmorphism │
                              │  - Offline Fallback Engine  │
                              └─────────────────────────────┘
```

### 3.1 Recommended Parser Strategy
1. **Direct Mode (Zero-backend required for initial launch):**
   - The Flutter app directly calls IMD JSON APIs and fetches the Nowcast HTML.
   - For PDFs, a lightweight Dart PDF parser package (`syncfusion_flutter_pdf`) or a tiny serverless proxy (Cloudflare Worker / Supabase Edge Function) downloads and extracts the structured tables.
2. **Serverless Proxy Mode (Recommended for production):**
   - A free Cloudflare Worker or Python/Node microservice runs on cron, downloads the daily dam PDFs once at 11:05 AM, parses them into a lightweight 15 KB JSON file, and caches it.
   - Prevents end-user devices from downloading 2 MB to 5 MB of raw PDFs repeatedly, preserving mobile bandwidth and battery life.

---

## 4. Feature Specifications & Requirements

### Module 1: Weather & Forecast
* **F-1.1 Station Weather Dashboard:**
  - Displays current temperature, perceived weather condition, weather icon, 24-hr realized rainfall (mm), humidity (08:30 & 17:30 IST), and sunrise/sunset/moonrise/moonset.
  - Multi-station selector supporting all 23 Kerala stations (Thiruvananthapuram, Kochi, Kozhikode, Kannur, Palakkad, Alappuzha, Kottayam, Kollam, Munnar, Wayanad, Bekal, Varkala, Sabarimala, Guruvayoor, etc.) and Lakshadweep stations.
* **F-1.2 7-Day Day-by-Day Forecast:**
  - 7-day horizontal scroll card displaying day, date, max/min temperature range, rain prediction summary, and warning badges.
* **F-1.3 Station Search & Auto-complete:**
  - Instant live filter matching station names via `api/search.php`.

### Module 2: Nowcast & Severe Alerts
* **F-2.1 Real-Time 3-Hour Severe Nowcast:**
  - Displays location-based real-time warnings for 36+ locations across Kerala.
  - Shows exact rain intensity (`Moderate rain: 5-15 mm/hr`, `Light rain`), surface wind gusts (`< 40 kmph`), thunderstorm and lightning warnings, and validity window.
  - Visual color indicators matching IMD alert levels.
* **F-2.2 5-Day District Warning Map:**
  - District-by-district interactive map or list with Day 1 to Day 5 tabs.
  - Color-coded badges for all 14 districts: Green (No warning), Yellow (Watch), Orange (Alert), Red (Warning).
  - Tapping a district reveals the official meteorological impact advisory.

### Module 3: Kerala Dam Water Levels (KSDMA)
* **F-3.1 KSEB Hydroelectric Dams (17 Dams):**
  - Displays today's water level vs. Full Reservoir Level (FRL) in meters and feet.
  - Live Storage percentage (`% of Capacity`) and Total Storage in Million Cubic Meters (MCM).
  - Current Spillway Release / Outflow in cumecs ($m^3/s$).
  - Official Alert Stage: `Blue Alert` (Stage 1), `Orange Alert` (Stage 2), `Red Alert` (Stage 3), `Yellow Alert` (controlled discharge), `No Alert`.
  - Detailed shutter status & remarks (e.g., *"Shutter 1 opened 10 cm, Outflow for power generation"*).
* **F-3.2 Irrigation Department Dams (20 Dams & Barrages):**
  - Monitors Neyyar, Kallada, Malampuzha, Peechi, Chimoni, Bhoothathankettu, Malankara, Siruvani, Walayar, Kanjirappuzha, Karapuzha, Pazhassi, etc.
  - Live percentage gauge, gross storage, outflow, and alert status.
* **F-3.3 Filter & Sort:**
  - Filter dams by District, Alert Level (Red/Orange/Yellow), or Authority (KSEB vs. Irrigation).
  - Sort by storage percentage (highest to lowest to spot dams nearing capacity).

### Module 4: Live Doppler Radar & Satellite
* **F-4.1 Doppler Weather Radar (Kochi):**
  - Interactive viewer showing the animated Doppler radar reflectivity loop (`caz_koc.gif`).
  - Pinch-to-zoom and pan support to track localized rain cloud clusters over Kerala.
* **F-4.2 Satellite View:**
  - INSAT-3D thermal infrared cloud satellite map updated regularly.
* **F-4.3 Realized 24-Hour Rainfall Map:**
  - Daily statewide realized rainfall heatmap image.

### Module 5: Coastal & Marine Safety (Fishermen & Ports)
* **F-5.1 Port Cautionary Signals:**
  - Displays hoisted signal numbers (e.g. Signal III) for all 11 Kerala ports: Kasaragod, Cannanore, Tellicherry, Kozhikode, Beypore, Ponnani, Azhikkal, Kochi, Alappuzha, Kollam, Thiruvananthapuram.
* **F-5.2 Sea & Squally Wind Warnings:**
  - Advisories on wind speeds (35–55 kmph, gale warnings) and ocean current/swell surge warnings from INCOIS.

### Module 6: Special Bulletins & Pilgrimage
* **F-6.1 Sabarimala Pilgrimage Weather:**
  - Dedicated screen during pilgrimage seasons for Sannidhanam, Pamba Base Camp, and Nilakkal.
* **F-6.2 River Basin Flood Risk (QPF):**
  - 7-day projected precipitation for 11 river basins (Periyar, Bharathapuzha, Pamba, Chalakudy, Achankoil, etc.).

### Module 7: Bilingual Support & Offline Access
* **F-7.1 English & Malayalam Toggle:**
  - Full UI and bulletin support in Malayalam (മലയാളം) and English.
* **F-7.2 Offline Cache First:**
  - Stores the latest successful sync locally using Hive/SharedPreferences so users can view data during network outages.

---

## 5. Data Models & Schemas

### 5.1 Weather Station & Forecast Model
```json
{
  "station_id": "43371",
  "station_name": "Thiruvananthapuram-City",
  "latitude": 8.48,
  "longitude": 76.95,
  "updated_at": "2026-10-26 13:54:31",
  "current_day": {
    "date": "2026-10-26",
    "max_temp": 32.0,
    "max_temp_deviation": 0.8,
    "min_temp": 24.6,
    "min_temp_deviation": 1.0,
    "rainfall_24h_mm": 26.0,
    "humidity_morning_pct": 96,
    "humidity_evening_pct": 75,
    "sunrise": "06:10",
    "sunset": "18:02",
    "moonrise": "18:07",
    "moonset": "06:00"
  },
  "forecast_7_days": [
    {
      "day_index": 0,
      "date": "2026-10-26",
      "forecast_summary": "Generally cloudy sky with a few spells of rain or thundershowers",
      "max_temp": 32.0,
      "min_temp": 23.0,
      "icon_code": "15",
      "warning_color": "yellow",
      "warning_text": "Heavy Rainfall, Thunderstorm accompanied with lightning & gusty winds (30-40kmph)"
    }
  ]
}
```

### 5.2 Dam Water Level Model
```json
{
  "dam_id": "kseb_banasurasagar",
  "dam_name_en": "Banasurasagar",
  "dam_name_ml": "ബാണാസുര സാഗർ",
  "district": "Wayanad",
  "authority": "KSEB",
  "frl_meters": 775.60,
  "current_water_level_meters": 771.90,
  "rule_level_meters": 775.60,
  "alert_levels": {
    "blue_level": 774.10,
    "orange_level": 774.60,
    "red_level": 775.10
  },
  "gross_storage_mcm": 201.00,
  "current_storage_mcm": 156.35,
  "storage_percentage": 77.79,
  "outflow_cumecs": 0.0,
  "alert_status": "No Warning",
  "shutter_remarks": "Control shaft gate opened 50%. Tunnel discharge 0 MCM.",
  "as_of_time": "2026-10-26 11:00 AM"
}
```

### 5.3 Nowcast Alert Model
```json
{
  "station_name": "Kochi",
  "latitude": 9.9312,
  "longitude": 76.2673,
  "alert_level": "Yellow",
  "issue_time": "2026-10-26 22:00 IST",
  "valid_upto": "2026-10-27 01:00 IST",
  "rain_intensity": "Light rain",
  "thunderstorm": false,
  "wind_speed_kmph": "< 40 kmph"
}
```

---

## 6. Technical Stack & Implementation Details

* **Framework:** Flutter 3.47+ (Dart 3.13+)
* **State Management:** Riverpod (`flutter_riverpod`) with code generation
* **HTTP Client:** `dio` (with interceptors for `User-Agent`, `Referer`, and automatic retry)
* **Local Persistence:** `hive_flutter` or `isar` for offline data caching
* **Mapping & Visuals:** `flutter_map` with OpenStreetMap tiles or GeoJSON overlay
* **UI Toolkit:** Material Design 3 with custom color tokens:
  - *Rain & Sky Theme:* Deep indigo (`#0A192F`), cyan accents (`#00F2FE`), gradient card surfaces
  - *Alert Theme:* Standard IMD Green (`#2E7D32`), Yellow (`#FBC02D`), Orange (`#EF6C00`), Red (`#C62828`)
* **Typography:** Google Fonts (`Inter` for numbers/English, `Manjari` / `Noto Sans Malayalam` for Malayalam)
* **Animation:** `flutter_animate` for card entrances and liquid wave level indicators for dams.

---

## 7. Implementation Roadmap & Milestones

### Phase 1: Core Networking & Weather Engine (Completed)
- [x] Initialize Flutter project in `c:\Users\thanv\kweather`.
- [x] Set up HTTP service with required IMD headers (`Referer: https://city.imd.gov.in/citywx/responsive/`).
- [x] Implement `WeatherApiService` to fetch station directory, search, and 7-day forecast JSON.
- [x] Build Weather Home Dashboard with current weather cards, astronomical info, and 7-day forecast horizontal slider.

### Phase 2: Dam Water Level Scraping Engine (Completed)
- [x] Implement parser for KSDMA portal to extract daily dam levels and timestamps.
- [x] Build table/text extractor to parse all 37 dams into structured `DamModel` instances.
- [x] Create Dam Reservoir screen featuring circular storage gauges (`% capacity`), alert badges (Red/Orange/Blue/Yellow), and shutter status.
- [x] Add sorting by storage percentage, authority filtering (All, KSEB, Irrigation), and district filtering.

### Phase 3: Nowcast, Warnings & Vector Radar Map (Completed)
- [x] Parse station-wise 3-hour nowcast HTML and district-wise 5-day warning levels.
- [x] Build 100% vector-based Doppler Radar PPI scope (`_RadarScopePainter`) compliant with Indian Copyright Act (no proprietary raster image scraping).
- [x] Display factual INSAT-3DR atmospheric cloud metrics with official portal attribution links.

### Phase 4: Marine Port Alerts, Localization, Caching & Release APK (Completed)
- [x] Add Port Cautionary signals (11 Kerala ports), Sabarimala pilgrimage micro-weather, and River Basin QPF tabs.
- [x] Implement complete Malayalam (മലയാളം) localization with language toggle in top app bar.
- [x] Add dual-tier cache (`CacheManager`) with 24h dam TTL, 12h forecast TTL, 10-minute cooldown, and automatic 2-hour HTTP 429/403 backoff lockout.
- [x] Integrate Material 3 monochrome adaptive themed icon (`ic_launcher_monochrome.xml` + `KWeatherMonochromeIcon`).
- [x] Build release APK bundle at standard location (`build/app/outputs/flutter-apk/app-release.apk` & `release/kweather-release.apk`).


---

## 8. Non-Functional & Reliability Requirements

1. **Graceful Fallbacks:** If an IMD or SDMA endpoint is temporarily unreachable, the app must display cached data with a clear "Updated X hours ago" banner.
2. **Data Usage:** All standard API queries must consume under 100 KB per refresh.
3. **App Size:** Target APK release bundle under 25 MB.
4. **Battery Efficiency:** Background sync should only trigger periodically (every 2-3 hours) during active alert periods.

---

## 9. Legal, Copyright & Data Rights Compliance (Indian Copyright Act, 1957)

1. **Facts Are Not Copyrightable:**
   - Under the **Idea-Expression Dichotomy** recognized in Indian copyright jurisprudence (*Eastern Book Company v. D.B. Modak, 2008 INSC 1* and Section 13/14 of the Copyright Act, 1957), raw facts, measurements, statistical observations, and natural physical phenomena cannot be copyrighted.
   - All meteorological data points (temperatures in °C, humidity %, atmospheric pressure, rainfall in mm, wind speeds), disaster warning color codes (Red, Orange, Yellow, Green), port signal numbers (Signal III), and reservoir dam levels (meters MSL, feet, storage %, outflow cumecs) are uncopyrightable public facts published for civic safety.

2. **Government Works & Satellite / Radar Imagery (Section 2(k) & Section 17(d)):**
   - Works created or published by the Government of India, the Ministry of Earth Sciences (MoES), IMD, and ISRO constitute **Government Works** under Section 2(k).
   - Under Section 17(d), the Government is the first owner of copyright in processed photographic works, false-color composite satellite raster maps (INSAT-3D, INSAT-3DR), and Doppler Weather Radar (DWR) composite GIF loops.
   - **Compliance Measure:** The application **strictly refrains from hotlinking, scraping, or redistributing proprietary raster images** of satellite or radar feeds. Instead:
     - The radar scope is generated entirely in-app via a native Flutter vector `CustomPainter` rendering factual range rings, azimuth coordinates, and echo clusters.
     - The satellite tab displays factual atmospheric cloud index metrics (cloud base, cloud top temp, precipitable water, SST) and provides direct attribution links to official government portals (`mausam.imd.gov.in`).

3. **Statutory Exceptions & Fair Dealing (Section 52):**
   - Dissemination of weather warnings, disaster alerts, and flood preparedness information conforms to Section 52 of the Copyright Act and the National Disaster Management Act (NDMA), ensuring public safety and accurate source attribution.

---

## 10. Anti-Rate-Limiting Architecture & Maximal App Caching

Government portals (IMD and KSDMA) operate under strict server firewall and rate-limiting policies. To eliminate any possibility of triggering IP bans, HTTP 429 ("Too Many Requests"), or 403 blocks, the app enforces an aggressive **Cache-First / Offline-First** architecture aligned with the actual publication frequencies:

### 10.1 Government Data Publishing Cycles
| Data Stream | Official Publishing Frequency | Publication Time (IST) | App Cache Strategy |
| :--- | :--- | :--- | :--- |
| **Kerala Dam Water Levels (SDMA)** | **Once a day** | ~11:00 AM IST | **24-Hour TTL** with daily 11:00 AM sync window (`isDailyUpdateFresh`). Never re-scrapes if today's 11 AM bulletin is already cached. |
| **Station 7-Day Weather Forecast (IMD)** | **Twice a day** | ~08:30 IST & 17:30 IST | **12-Hour TTL**. Opening the app or switching stations uses persistent disk cache. |
| **Bulletins (Ports, Sabarimala, QPF)** | **Once a day** | ~12:00 PM IST | **24-Hour TTL**. Served directly from local cache. |
| **Nowcast Severe Alerts (IMD)** | As convective cells develop | Valid for 3 hours | **3-Hour TTL**. Only checks once every 3 hours. |

### 10.2 Defense-in-Depth Anti-Rate-Limiting Controls
1. **Persistent Dual-Tier Cache (`CacheManager`):**
   - Fast in-memory cache for instant 0-ms UI lookups during tab switches.
   - Persistent `SharedPreferences` disk storage retaining all telemetry across app restarts.
2. **Strict Anti-Hammering Cooldown (`minRequestCooldown = 10 min`):**
   - Even if a user continuously triggers Pull-to-Refresh or taps refresh, network requests are blocked if the last fetch occurred within the last 10 minutes.
   - Instant cached data is returned with zero network traffic.
3. **Automated 2-Hour Backoff Lockout (HTTP 429 / 403 Protection):**
   - If an endpoint returns HTTP 429 or 403, `CacheManager.recordRateLimitHit()` flags the key for a **2-hour backoff lockout**.
   - During the lockout window, `shouldFetch` strictly returns `false`, preventing any outbound packets to the offending government domain and saving device battery and IP reputation.
4. **Transparent Graceful Fallback (`getFallback`):**
   - If network connectivity is lost, times out, or triggers server error, the app displays the last known good observation with an "Offline Cache" badge, falling back to pre-bundled offline baseline data (`KeralaDamsData.baselineDams` & `KeralaStationsData.defaultStations`).

---

## 11. Material Design Monochrome Icon & Android Themed Icon System

In alignment with Google's Material 3 design language and Android 13+ (API 33+) **Themed App Icons**, the application features a cohesive, custom-crafted vector monochrome emblem:

### 11.1 Icon Emblem Motif
- **Weather Cloud Top:** Smooth Material cloud silhouette representing IMD synoptic weather, rain clouds, and meteorological forecasting.
- **Hydro Dam Water Droplet:** Centered high-contrast teardrop with an inner counter-contour droplet core representing KSDMA dam water storage.
- **Reservoir Surface Waves:** Stylized water level ripple marks flanking the hydro droplet representing dam rule levels and controlled spillway discharge.

### 11.2 Implementation Specifications
1. **Android Adaptive & Themed Icon (`res/mipmap-anydpi-v26/`):**
   - `ic_launcher.xml` & `ic_launcher_round.xml` configure an `<adaptive-icon>` with `<monochrome android:drawable="@drawable/ic_launcher_monochrome" />`.
   - On Android 13+ devices, the system automatically applies the user's dynamic Material You wallpaper-generated color palette to tint the monochrome icon.
2. **Flutter Vector Widget (`KWeatherMonochromeIcon`):**
   - Custom `CustomPainter` vector drawing located in `lib/core/widgets/kweather_monochrome_icon.dart`.
   - Scalable to any dimension, automatically adapting to dark and light Material 3 theme colors.
   - Prominently integrated into the `MainShell` top AppBar for instant brand recognition.



