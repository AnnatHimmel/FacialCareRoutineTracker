abstract class AppLayout {
  /// Safe zone top: status bar / notch area (iPhone-matched metrics).
  static const double safeTop = 47.0;

  /// Safe zone bottom: system home indicator (34px) + app bottom nav bar (~50px) = 84px.
  /// This ensures content is never blocked by either system UI or the app's own nav.
  static const double safeBottom = 84.0;
}
