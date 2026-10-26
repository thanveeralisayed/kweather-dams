/// Official API endpoints and URLs for IMD and Kerala SDMA
class ApiConstants {
  ApiConstants._();

  // IMD City Weather Base URLs
  static const String imdCityBase = 'https://city.imd.gov.in/citywx/responsive';
  static const String imdAllStationsApi = '$imdCityBase/api/';
  static const String imdFetchCityStatic = '$imdCityBase/api/fetchCity_static.php';
  static const String imdSearchApi = '$imdCityBase/api/search.php';

  // IMD Headers required to prevent 403 Forbidden
  static const Map<String, String> imdHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': '$imdCityBase/',
    'Origin': 'https://city.imd.gov.in',
    'Accept': 'application/json, text/plain, */*',
  };

  // IMD Thiruvananthapuram Main Portal & Feeds
  static const String imdTvmBase = 'https://mausam.imd.gov.in/thiruvananthapuram';
  static const String imdNowcastUrl = 'https://mausam.imd.gov.in/imd_latest/contents/stationwise-nowcast-warning_mc.php?id=4';
  static const String imdDistrictWarningUrl = 'https://mausam.imd.gov.in/imd_latest/contents/districtwise-warning_mc.php?id=4';
  
  // Official Government Web Portals (for user attribution and direct external viewing)
  // Note: Processed satellite raster imagery and Doppler radar composite loops are protected
  // as Government Works under Section 2(k) and Section 17(d) of the Indian Copyright Act, 1957.
  // In accordance with copyright law, this application does not hotlink, scrape, or redistribute
  // proprietary raster imagery, directing users to official portals instead.
  static const String imdRadarWebPortal = 'https://mausam.imd.gov.in/imd_latest/contents/index_radar.php?id=Kochi';
  static const String imdSatelliteWebPortal = 'https://mausam.imd.gov.in/imd_latest/contents/satellite.php';
  static const String imdMainPortal = 'https://mausam.imd.gov.in';

  // PDF Bulletins
  static const String fishermenWarningPdf = '$imdTvmBase/mcdata/fishermen%20warning.pdf';
  static const String sabarimalaForecastPdf = '$imdTvmBase/mcdata/sabarimala_forecast.pdf';
  static const String blockLevelForecastPdf = '$imdTvmBase/mcdata/blocklevelforecast.pdf';
  static const String qpfBulletinPdf = '$imdTvmBase/mcdata/qpf.pdf';
  static const String dwr1Pdf = '$imdTvmBase/mcdata/dwr1.pdf';

  // Kerala SDMA Dam Water Level
  static const String sdmaDamWaterLevelUrl = 'https://sdma.kerala.gov.in/dam-water-level/';
  static const String sdmaBase = 'https://sdma.kerala.gov.in';
}
