class ApiConfig {
  // URL de producción alojada en Render
  static String baseUrl = 'https://personfit.onrender.com/api/v1';

  static void updateBaseUrl(String newUrl) {
    if (newUrl.endsWith('/api/v1')) {
      baseUrl = newUrl;
    } else {
      baseUrl = newUrl.endsWith('/') ? '${newUrl}api/v1' : '$newUrl/api/v1';
    }
  }
}
