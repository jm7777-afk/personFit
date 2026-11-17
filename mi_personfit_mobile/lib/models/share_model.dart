class SharedProfileToken {
  final int id;
  final String shareToken;
  final int durationMinutes;
  final String expiresAt;
  final String shareUrl;

  SharedProfileToken({
    required this.id,
    required this.shareToken,
    required this.durationMinutes,
    required this.expiresAt,
    required this.shareUrl,
  });

  factory SharedProfileToken.fromJson(Map<String, dynamic> json) {
    return SharedProfileToken(
      id: json['id'] ?? 0,
      shareToken: json['share_token'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 60,
      expiresAt: json['expires_at'] ?? '',
      shareUrl: json['share_url'] ?? '',
    );
  }
}

class UserShareItem {
  final int id;
  final String shareToken;
  final int durationMinutes;
  final String expiresAt;
  final bool isActive;
  final int minutesRemaining;
  final bool isExpired;

  UserShareItem({
    required this.id,
    required this.shareToken,
    required this.durationMinutes,
    required this.expiresAt,
    required this.isActive,
    required this.minutesRemaining,
    required this.isExpired,
  });

  factory UserShareItem.fromJson(Map<String, dynamic> json) {
    return UserShareItem(
      id: json['id'],
      shareToken: json['share_token'],
      durationMinutes: json['duration_minutes'] ?? 60,
      expiresAt: json['expires_at'] ?? '',
      isActive: json['is_active'] == 1,
      minutesRemaining: json['minutes_remaining'] ?? 0,
      isExpired: json['is_expired'] ?? false,
    );
  }
}

class SharedProfileData {
  final bool isValid;
  final bool isExpired;
  final String? message;
  final Map<String, dynamic>? accessMeta;
  final Map<String, dynamic>? financialOverview;
  final Map<String, dynamic>? payroll;
  final List<dynamic>? debtsOverview;

  SharedProfileData({
    required this.isValid,
    required this.isExpired,
    this.message,
    this.accessMeta,
    this.financialOverview,
    this.payroll,
    this.debtsOverview,
  });

  factory SharedProfileData.fromJson(Map<String, dynamic> json) {
    return SharedProfileData(
      isValid: json['is_valid'] ?? false,
      isExpired: json['is_expired'] ?? false,
      message: json['message'],
      accessMeta: json['access_meta'],
      financialOverview: json['financial_overview'],
      payroll: json['payroll'],
      debtsOverview: json['debts_overview'] as List?,
    );
  }
}
