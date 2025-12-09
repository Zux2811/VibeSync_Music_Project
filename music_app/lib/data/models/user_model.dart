class User {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String tierCode; // 'free' or 'pro'

  User({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.tierCode = 'free',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      name: json['name'],
      email: json['email'],
      avatarUrl:
          json['avatar_url'] ??
          json['avatarUrl'], // Handle both snake_case and camelCase
      bio: json['bio'],
      tierCode: json['tierCode'] ?? json['tier_code'] ?? 'free',
    );
  }

  /// Check if user has pro tier
  bool get isPro => tierCode == 'pro';

  /// Check if user has free tier
  bool get isFree => tierCode == 'free';
}
