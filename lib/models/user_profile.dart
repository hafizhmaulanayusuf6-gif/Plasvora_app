class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool whatsappPublic;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.whatsappPublic = false,
    this.createdAt,
  });

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    bool clearPhone = false,
    bool? whatsappPublic,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      whatsappPublic: whatsappPublic ?? this.whatsappPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawPhone = json['phone']?.toString().trim();
    final rawPublic = json['whatsapp_public'];
    final isWhatsappPublic = rawPublic is bool
        ? rawPublic
        : (rawPublic?.toString() == '1' || rawPublic?.toString() == 'true');

    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: (rawPhone != null && rawPhone.isNotEmpty) ? rawPhone : null,
      whatsappPublic: isWhatsappPublic,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'whatsapp_public': whatsappPublic,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

