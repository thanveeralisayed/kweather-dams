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

### Phase 1: Core Networking & Weather Engine (Week 1)
- [ ] Initialize Flutter project in `c:\Users\thanv\kweather`.
- [ ] Set up `Dio` service with required IMD headers (`Referer: https://city.imd.gov.in/citywx/responsive/`).
- [ ] Implement `WeatherRepository` to fetch station directory, auto-search, and 7-day forecast JSON.
- [ ] Build Weather Home Dashboard with current weather cards, astronomical info, and 7-day forecast horizontal slider.

### Phase 2: Dam Water Level Scraping Engine (Week 2)
- [ ] Implement parser for KSDMA portal to extract daily PDF URLs (`kseb-site.pdf`, `IRR-site.pdf`).
- [ ] Build table extractor to parse the 37 dams into structured `DamModel` instances.
- [ ] Create Dam Water Level screen featuring liquid circular progress gauges (`% capacity`), alert badges (Red/Orange/Blue), and shutter opening status.
- [ ] Add sorting by storage percentage and district filtering.

### Phase 3: Nowcast, Warnings & Interactive Map (Week 3)
- [ ] Parse station-wise 3-hour nowcast HTML and district-wise 5-day warning levels.
- [ ] Integrate interactive Kerala map view displaying live station alerts and dam locations.
- [ ] Build Doppler Radar viewer with animated GIF playback and zoom controls.

### Phase 4: Marine Port Alerts, Localization & Polish (Week 4)
- [ ] Add Port Cautionary signals and Sabarimala pilgrimage forecast tabs.
- [ ] Implement complete Malayalam (മലയാളം) localization with language toggle in app bar.
- [ ] Add Hive offline caching and pull-to-refresh on all screens.
- [ ] Conduct end-to-end testing, error boundary validation, and release APK build.

---

## 8. Non-Functional & Reliability Requirements

1. **Graceful Fallbacks:** If an IMD or SDMA endpoint is temporarily unreachable, the app must display cached data with a clear "Updated X hours ago" banner.
2. **Data Usage:** All standard API queries must consume under 100 KB per refresh.
3. **App Size:** Target APK release bundle under 25 MB.
4. **Battery Efficiency:** Background sync should only trigger periodically (every 2-3 hours) during active alert periods.
