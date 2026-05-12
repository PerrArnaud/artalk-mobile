class ApiConfig {
  // URL du backend Symfony.
  // - Développement (ngrok) : https://VOTRE_ID.ngrok-free.dev
  // - Production            : https://votre-domaine.com
  // Modifier uniquement cette constante pour changer l'environnement.
  static const String baseUrl = 'https://unwept-marleen-confineable.ngrok-free.dev';
  static const String apiPath = '/api';
  
  static String get apiUrl => '$baseUrl$apiPath';
  
  // Endpoints
  static String get registerUrl => '$apiUrl/register';
  static String get loginUrl => '$apiUrl/login';
  static String get meUrl => '$apiUrl/me';
  static String get motwUrl => '$apiUrl/motw';
  static String get commentsUrl => '$apiUrl/comments';
  
  static String motwDetailUrl(String slug) => '$apiUrl/motw/$slug';
  static String motwCommentsUrl(String slug) => '$apiUrl/motw/$slug/comments';
  static String reportCommentUrl(int id) => '$apiUrl/comments/$id/report';
  
  // Image URL helper
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
