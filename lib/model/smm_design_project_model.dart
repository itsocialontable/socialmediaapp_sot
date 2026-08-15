// lib/model/smm_design_project_model.dart

// ─────────────────────────────────────────────────────────────────────────────
// Sub-models
// ─────────────────────────────────────────────────────────────────────────────

class SmmDesignProjectPerson {
  final String id;
  final String name;
  final String? email;

  const SmmDesignProjectPerson({
    required this.id,
    required this.name,
    this.email,
  });

  factory SmmDesignProjectPerson.fromJson(Map<String, dynamic> json) {
    return SmmDesignProjectPerson(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? 'Unknown').toString(),
      email: json['email']?.toString(),
    );
  }
}

class SmmDesignProjectFile {
  final String id;
  final String fileName;
  final String fileType;
  final String fileUrl;
  final DateTime? uploadedAt;

  const SmmDesignProjectFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    this.uploadedAt,
  });

  factory SmmDesignProjectFile.fromJson(Map<String, dynamic> json) {
    return SmmDesignProjectFile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main model — SmmDesignProject
// ─────────────────────────────────────────────────────────────────────────────

class SmmDesignProject {
  final String id;
  final String title; // Brand name
  final String designType; // kept as comma-joined string from backend
  final String priority;
  final String status;
  final String description;
  final int progressPercentage;
  final DateTime? deadline;
  final DateTime? createdAt;
  final SmmDesignProjectPerson? client;
  final SmmDesignProjectPerson? designer;
  final List<SmmDesignProjectFile> files;

  const SmmDesignProject({
    required this.id,
    required this.title,
    required this.designType,
    required this.priority,
    required this.status,
    required this.description,
    required this.progressPercentage,
    this.deadline,
    this.createdAt,
    this.client,
    this.designer,
    this.files = const [],
  });

  factory SmmDesignProject.fromJson(Map<String, dynamic> json) {
    SmmDesignProjectPerson? client;
    final rawClient = json['client'] ?? json['clientId'];
    if (rawClient is Map<String, dynamic>) {
      client = SmmDesignProjectPerson.fromJson(rawClient);
    }

    SmmDesignProjectPerson? designer;
    final rawDesigner = json['designer'] ?? json['designerId'] ?? json['assignedTo'];
    if (rawDesigner is Map<String, dynamic>) {
      designer = SmmDesignProjectPerson.fromJson(rawDesigner);
    }

    final rawFiles = json['files'];
    final filesList = <SmmDesignProjectFile>[];
    if (rawFiles is List) {
      for (final f in rawFiles) {
        if (f is Map<String, dynamic>) {
          filesList.add(SmmDesignProjectFile.fromJson(f));
        }
      }
    }

    // designType may come back as a String or a List<String> (multi-select).
    final rawType = json['designType'];
    String typeStr;
    if (rawType is List) {
      typeStr = rawType.map((e) => e.toString()).join(', ');
    } else {
      typeStr = rawType?.toString() ?? '';
    }

    return SmmDesignProject(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      designType: typeStr,
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      client: client,
      designer: designer,
      files: filesList,
    );
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'inprogress':
        return 'In Progress';
      case 'review':
      case 'pending review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'changes requested':
        return 'Changes Requested';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update request body — PUT /api/smm/design-projects/:id
// ─────────────────────────────────────────────────────────────────────────────

class SmmDesignProjectUpdateRequest {
  final String? title;
  final List<String>? designType;
  final String? priority;
  final String? description;
  final DateTime? deadline;

  const SmmDesignProjectUpdateRequest({
    this.title,
    this.designType,
    this.priority,
    this.description,
    this.deadline,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (designType != null) map['designType'] = designType;
    if (priority != null) map['priority'] = priority;
    if (description != null) map['description'] = description;
    if (deadline != null) map['deadline'] = deadline!.toUtc().toIso8601String();
    return map;
  }
}
