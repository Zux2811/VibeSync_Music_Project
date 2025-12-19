class User {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String tierCode; // 'free' or 'pro'
  final String role; // 'user', 'artist', or 'admin'

  User({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.tierCode = 'free',
    this.role = 'user',
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
      role: json['role'] ?? 'user',
    );
  }

  /// Check if user has pro tier
  bool get isPro => tierCode == 'pro';

  /// Check if user has free tier
  bool get isFree => tierCode == 'free';

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is artist
  bool get isArtist => role == 'artist';

  /// Check if user is regular user
  bool get isUser => role == 'user';
}
