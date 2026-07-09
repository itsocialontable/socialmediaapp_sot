// lib/model/gd_project_model.dart

class GdProjectClient {
  final String id;
  final String name;
  final String email;
  final String companyName;

  const GdProjectClient({
    required this.id,
    required this.name,
    required this.email,
    required this.companyName,
  });

  factory GdProjectClient.fromJson(Map<String, dynamic> json) {
    return GdProjectClient(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
    );
  }
}

class GdProject {
  final String id;
  final GdProjectClient client;
  final String title;
  final String designType;
  final String priority;
  final DateTime? deadline;
  final String status;
  final int progressPercentage;
  final DateTime? createdAt;

  const GdProject({
    required this.id,
    required this.client,
    required this.title,
    required this.designType,
    required this.priority,
    this.deadline,
    required this.status,
    required this.progressPercentage,
    this.createdAt,
  });

  factory GdProject.fromJson(Map<String, dynamic> json) {
    return GdProject(
      id: json['_id'] as String? ?? '',
      client: GdProjectClient.fromJson(
          json['client'] as Map<String, dynamic>? ?? {}),
      title: json['title'] as String? ?? '',
      designType: json['designType'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      status: json['status'] as String? ?? '',
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class GdProjectPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const GdProjectPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory GdProjectPagination.fromJson(Map<String, dynamic> json) {
    return GdProjectPagination(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}