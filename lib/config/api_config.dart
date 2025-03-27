class ApiConfig {
  // Base URL for the Google Kubernetes Engine API endpoint
  static const String baseUrl = 'https://api.your-gke-cluster.com';
  
  // API paths
  static const String generateHanbokEndpoint = '/api/v1/generate-hanbok';
  
  // API Key - In a real app, this should be secured properly and not hard-coded
  // You might want to use environment variables or Flutter's secure storage
  static const String apiKey = 'YOUR_API_KEY';
  
  // Timeout values
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 60000; // 60 seconds
  
  // Maximum image size to download (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
}