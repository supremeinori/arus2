/// Feature Flags
class FeatureFlags {
  // Client-side features
  final bool lbs;
  final bool sensors;
  final bool biometric;

  // Server-synced features
  final bool integrity;
  final bool notifications;
  final bool fx;
  final bool game;
  final bool ai;

  const FeatureFlags({
    this.lbs = true,
    this.sensors = false,
    this.biometric = true,
    this.integrity = false,
    this.notifications = true,
    this.fx = false,
    this.game = false,
    this.ai = false,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      lbs: json['lbs'] as bool? ?? true,
      sensors: json['sensors'] as bool? ?? false,
      biometric: json['biometric'] as bool? ?? true,
      integrity: json['integrity'] as bool? ?? false,
      notifications: json['notifications'] as bool? ?? true,
      fx: json['fx'] as bool? ?? false,
      game: json['game'] as bool? ?? false,
      ai: json['ai'] as bool? ?? false,
    );
  }

  static const FeatureFlags coreOnly = FeatureFlags(
    lbs: true,
    sensors: false,
    biometric: false,
    integrity: false,
    notifications: false,
    fx: false,
    game: false,
    ai: false,
  );
}
