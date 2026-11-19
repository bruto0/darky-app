class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.photoUrl,
    this.branchName,
    this.bonus = 0,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: (json['name'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      middleName: json['middleName'] as String?,
      photoUrl: json['fotoThumbUrl'] as String?,
      branchName: (json['branch'] as Map?)?['name'] as String?,
      bonus: (json['bonus'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? photoUrl;
  final String? branchName;
  final int bonus;

  String get fullName {
    final parts = [lastName, firstName, middleName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(' ').trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': firstName,
        'lastName': lastName,
        if (middleName != null) 'middleName': middleName,
        if (photoUrl != null) 'fotoThumbUrl': photoUrl,
        if (branchName != null) 'branch': {'name': branchName},
        'bonus': bonus,
      };
}

class Session {
  const Session({
    required this.clientId,
    required this.secret,
    required this.profile,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      clientId: (json['clientId'] as num).toInt(),
      secret: json['secret'] as String,
      profile: ClientProfile.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int clientId;
  final String secret;
  final ClientProfile profile;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'secret': secret,
        'profile': profile.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}
