class ApiConfig {
  // Para emulador Android usar http://10.0.2.2:3000
  // Para Web o Windows usar http://127.0.0.1:3000
  // Para Render usar https://tu-servicio.onrender.com
  static String baseUrl = 'http://127.0.0.1:3000/api/v1';

  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.endsWith('/') ? '${newUrl}api/v1' : '$newUrl/api/v1';
  }
}
