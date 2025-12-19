/// Artist profile model
class Artist {
  final int id;
  final String username;
  final String email;
  final String? createdAt;
  final ArtistProfile? artistProfile;
  final int songCount;
  final int albumCount;
  final bool isFollowing;

  Artist({
    required this.id,
    required this.username,
    required this.email,
    this.createdAt,
    this.artistProfile,
    this.songCount = 0,
    this.albumCount = 0,
    this.isFollowing = false,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'],
      artistProfile:
          json['artistProfile'] != null
              ? ArtistProfile.fromJson(json['artistProfile'])
              : null,
      songCount: json['songCount'] ?? 0,
      albumCount: json['albumCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  String get displayName => artistProfile?.stageName ?? username;
  String? get avatarUrl => artistProfile?.avatarUrl;
  String? get coverUrl => artistProfile?.coverUrl;
  String? get bio => artistProfile?.bio;
  int get followers => artistProfile?.totalFollowers ?? 0;
  int get totalPlays => artistProfile?.totalPlays ?? 0;
  bool get isVerified => artistProfile?.verified ?? false;
  Map<String, String?> get socialLinks => artistProfile?.socialLinks ?? {};
}

/// Artist profile details
class ArtistProfile {
  final String stageName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final Map<String, String?> socialLinks;
  final int totalFollowers;
  final int totalPlays;
  final bool verified;
  final String? contactEmail;
  final String? country;
  final List<String> genres;

  ArtistProfile({
    required this.stageName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.socialLinks = const {},
    this.totalFollowers = 0,
    this.totalPlays = 0,
    this.verified = false,
    this.contactEmail,
    this.country,
    this.genres = const [],
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    Map<String, String?> parseSocialLinks(dynamic links) {
      if (links == null) return {};
      if (links is Map) {
        return Map<String, String?>.from(
          links.map(
            (key, value) => MapEntry(key.toString(), value?.toString()),
          ),
        );
      }
      return {};
    }

    List<String> parseGenres(dynamic genres) {
      if (genres == null) return [];
      if (genres is List) {
        return genres.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ArtistProfile(
      stageName: json['stageName'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      coverUrl: json['coverUrl'],
      socialLinks: parseSocialLinks(json['socialLinks']),
      totalFollowers: json['totalFollowers'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      verified: json['verified'] ?? false,
      contactEmail: json['contactEmail'],
      country: json['country'],
      genres: parseGenres(json['genres']),
    );
  }

  Map<String, dynamic> toJson() => {
    'stageName': stageName,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'coverUrl': coverUrl,
    'socialLinks': socialLinks,
    'totalFollowers': totalFollowers,
    'totalPlays': totalPlays,
    'verified': verified,
    'contactEmail': contactEmail,
    'country': country,
    'genres': genres,
  };
}

/// Album model
class Album {
  final int id;
  final int artistId;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? releaseDate;
  final String? genre;
  final int totalTracks;
  final int totalDuration;
  final int totalPlays;
  final bool isPublished;
  final String albumType;
  final String? createdAt;

  Album({
    required this.id,
    required this.artistId,
    required this.title,
    this.description,
    this.coverUrl,
    this.releaseDate,
    this.genre,
    this.totalTracks = 0,
    this.totalDuration = 0,
    this.totalPlays = 0,
    this.isPublished = false,
    this.albumType = 'album',
    this.createdAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? 0,
      artistId: json['artistId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      coverUrl: json['coverUrl'],
      releaseDate: json['releaseDate'],
      genre: json['genre'],
      totalTracks: json['totalTracks'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      isPublished: json['isPublished'] ?? false,
      albumType: json['albumType'] ?? 'album',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artistId': artistId,
    'title': title,
    'description': description,
    'coverUrl': coverUrl,
    'releaseDate': releaseDate,
    'genre': genre,
    'totalTracks': totalTracks,
    'totalDuration': totalDuration,
    'totalPlays': totalPlays,
    'isPublished': isPublished,
    'albumType': albumType,
  };
}

/// Artist verification request model
class ArtistVerificationRequest {
  final int? id;
  final int userId;
  final String stageName;
  final String? realName;
  final String? bio;
  final String? facebookUrl;
  final String? youtubeUrl;
  final String? spotifyUrl;
  final String? instagramUrl;
  final String? websiteUrl;
  final List<String> releasedSongLinks;
  final String? idDocumentUrl;
  final String? authorizationDocUrl;
  final String? profileImageUrl;
  final String contactEmail;
  final String? contactPhone;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  ArtistVerificationRequest({
    this.id,
    required this.userId,
    required this.stageName,
    this.realName,
    this.bio,
    this.facebookUrl,
    this.youtubeUrl,
    this.spotifyUrl,
    this.instagramUrl,
    this.websiteUrl,
    this.releasedSongLinks = const [],
    this.idDocumentUrl,
    this.authorizationDocUrl,
    this.profileImageUrl,
    required this.contactEmail,
    this.contactPhone,
    this.status = 'pending',
    this.rejectionReason,
    this.createdAt,
  });

  factory ArtistVerificationRequest.fromJson(Map<String, dynamic> json) {
    List<String> parseLinks(dynamic links) {
      if (links == null) return [];
      if (links is List) {
        return links.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ArtistVerificationRequest(
      id: json['id'],
      userId: json['userId'] ?? 0,
      stageName: json['stageName'] ?? '',
      realName: json['realName'],
      bio: json['bio'],
      facebookUrl: json['facebookUrl'],
      youtubeUrl: json['youtubeUrl'],
      spotifyUrl: json['spotifyUrl'],
      instagramUrl: json['instagramUrl'],
      websiteUrl: json['websiteUrl'],
      releasedSongLinks: parseLinks(json['releasedSongLinks']),
      idDocumentUrl: json['idDocumentUrl'],
      authorizationDocUrl: json['authorizationDocUrl'],
      profileImageUrl: json['profileImageUrl'],
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

/// Artist stats
class ArtistStats {
  final int totalFollowers;
  final int totalPlays;
  final int totalSongs;
  final int totalAlbums;
  final bool verified;

  ArtistStats({
    this.totalFollowers = 0,
    this.totalPlays = 0,
    this.totalSongs = 0,
    this.totalAlbums = 0,
    this.verified = false,
  });

  factory ArtistStats.fromJson(Map<String, dynamic> json) {
    return ArtistStats(
      totalFollowers: json['totalFollowers'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      totalSongs: json['totalSongs'] ?? 0,
      totalAlbums: json['totalAlbums'] ?? 0,
      verified: json['verified'] ?? false,
    );
  }
}
