// ─────────────────────────────────────────
// ADMIN USER MODEL
// Used by: AdminClientsPage, AdminTeamPage (SMM + Graphic Designers)
// APIs:
//   GET /api/admin/users/clients
//   GET /api/admin/users/smm
//   GET /api/admin/users/graphic-designers
//   DELETE /api/admin/users/:id
// ─────────────────────────────────────────

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? companyName;
  final String? industry;
  final String? budget;
  final String? address;
  final String? specialization;
  final String? status;
  final String? projectTitle;
  final String? duration;
  final String? gstNumber;
  final String? profileImage;
  final List<String> platform;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.companyName,
    this.industry,
    this.budget,
    this.address,
    this.specialization,
    this.status,
    this.projectTitle,
    this.duration,
    this.gstNumber,
    this.profileImage,
    this.platform = const [],
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id:             (json['_id'] ?? json['id'] ?? '').toString(),
      name:           (json['name'] ?? 'Unknown').toString(),
      email:          (json['email'] ?? '').toString(),
      role:           (json['role'] ?? '').toString(),
      phone:          json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      companyName:    json['companyName']?.toString(),
      industry:       json['industry']?.toString(),
      budget:         json['budget']?.toString(),
      address:        json['address']?.toString(),
      specialization: json['specialization'] is List
          ? (json['specialization'] as List).join(', ')
          : json['specialization']?.toString(),
      status:         json['status']?.toString() ?? 'Active',
      projectTitle:   json['projectTitle']?.toString(),
      duration:       json['duration']?.toString(),
      gstNumber:      json['gstNumber']?.toString(),
      profileImage:   json['profileImage']?.toString(),
      platform:       (json['platforms'] ?? json['platform']) is List
          ? ((json['platforms'] ?? json['platform']) as List).map((e) => e.toString().toLowerCase()).toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':           id,
    'name':          name,
    'email':         email,
    'role':          role,
    'phoneNumber':   phone,
    'companyName':   companyName,
    'industry':      industry,
    'budget':        budget,
    'address':       address,
    'specialization': specialization,
    'status':        status,
    'projectTitle':  projectTitle,
    'duration':      duration,
    'gstNumber':     gstNumber,
    'profileImage':  profileImage,
    'platform':      platform,
  };

  AdminUserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? companyName,
    String? industry,
    String? budget,
    String? address,
    String? specialization,
    String? status,
    String? projectTitle,
    String? duration,
    String? gstNumber,
    String? profileImage,
    List<String>? platform,
  }) {
    return AdminUserModel(
      id:             id,
      name:           name ?? this.name,
      email:          email ?? this.email,
      role:           role,
      phone:          phone ?? this.phone,
      companyName:    companyName ?? this.companyName,
      industry:       industry ?? this.industry,
      budget:         budget ?? this.budget,
      address:        address ?? this.address,
      specialization: specialization ?? this.specialization,
      status:         status ?? this.status,
      projectTitle:   projectTitle ?? this.projectTitle,
      duration:       duration ?? this.duration,
      gstNumber:      gstNumber ?? this.gstNumber,
      profileImage:   profileImage ?? this.profileImage,
      platform:       platform ?? this.platform,
    );
  }

  /// True when a usable profile image URL is present.
  bool get hasProfileImage => profileImage != null && profileImage!.trim().isNotEmpty;

  /// First letter of name, safe fallback to '?'
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Display-friendly budget with ₹ prefix
  String get displayBudget =>
      (budget != null && budget!.isNotEmpty) ? '\u20B9$budget' : '';

  /// Subtitle line shown on list card
  String get subtitle {
    if (companyName != null && companyName!.isNotEmpty) return companyName!;
    if (specialization != null && specialization!.isNotEmpty)
      return specialization!;
    if (industry != null && industry!.isNotEmpty) return industry!;
    return role;
  }
}