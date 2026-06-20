class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const calendarId = String.fromEnvironment(
    'CALENDAR_ID',
    defaultValue: 'primary',
  );
}
