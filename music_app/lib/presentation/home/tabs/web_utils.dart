// Web-specific utilities
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens the React admin dashboard in a new tab with the JWT token
void openAdminDashboard(String token) {
  // URL to React admin dashboard - adjust port if needed
  const adminDashboardUrl = 'http://localhost:5174';

  // Open with token as query parameter
  html.window.open('$adminDashboardUrl?token=$token', '_blank');
}
