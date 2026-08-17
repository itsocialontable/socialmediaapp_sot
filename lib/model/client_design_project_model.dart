// lib/model/client_design_project_model.dart

// ─────────────────────────────────────────────────────────────────────────────
// Status enum (mirrors backend enum)
// ─────────────────────────────────────────────────────────────────────────────

enum ClientDesignProjectStatus {
  pending,
  inProgress,
  smmReview,
  clientReview,
  revision,
  completed,
  cancelled,
}

extension ClientDesignProjectStatusX on ClientDesignProjectStatus {
  /// Exact string value as used by the backend.
  String get value {
    switch (this) {
      case ClientDesignProjectStatus.pending:
        return 'Pending';
      case ClientDesignProjectStatus.inProgress:
        return 'In Progress';
      case ClientDesignProjectStatus.smmReview:
        return 'SMM Review';
      case ClientDesignProjectStatus.clientReview:
        return 'Client Review';
      case ClientDesignProjectStatus.revision:
        return 'Revision';
      case ClientDesignProjectStatus.completed:
        return 'Completed';
      case ClientDesignProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ClientDesignProjectStatus fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return ClientDesignProjectStatus.pending;
      case 'in progress':
      case 'inprogress':
        return ClientDesignProjectStatus.inProgress;
      case 'smm review':
        return ClientDesignProjectStatus.smmReview;
      case 'client review':
        return ClientDesignProjectStatus.clientReview;
      case 'revision':
        return ClientDesignProjectStatus.revision;
      case 'completed':
        return ClientDesignProjectStatus.completed;
      case 'cancelled':
        return ClientDesignProjectStatus.cancelled;
      default:
        return ClientDesignProjectStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-models
// ─────────────────────────────────────────────────────────────────────────────

class ClientDesignProjectAssignee {
  final String id;
  final String name;
  final String email;

  const ClientDesignProjectAssignee({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ClientDesignProjectAssignee.fromJson(Map<String, dynamic> json) {
    return ClientDesignProjectAssignee(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class ClientDesignProjectFile {
  final String id;
  final String fileName;
  final String fileType;
  final String fileUrl;
  final DateTime? uploadedAt;

  const ClientDesignProjectFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    this.uploadedAt,
  });

  factory ClientDesignProjectFile.fromJson(Map<String, dynamic> json) {
    return ClientDesignProjectFile(
      id: json['_id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main model — ClientDesignProject
// ─────────────────────────────────────────────────────────────────────────────

class ClientDesignProject {
  final String id;
  final String title;
  final String designType;
  final String priority;
  final String status;
  final String description;
  final int progressPercentage;
  final DateTime? deadline;
  final DateTime? createdAt;
  final ClientDesignProjectAssignee? assignedTo;
  final List<ClientDesignProjectFile> files;

  // Optional feedback from previous review
  final String? clientFeedback;
  final String? reviewAction; // 'approved' | 'changes_requested'

  const ClientDesignProject({
    required this.id,
    required this.title,
    required this.designType,
    required this.priority,
    required this.status,
    required this.description,
    required this.progressPercentage,
    this.deadline,
    this.createdAt,
    this.assignedTo,
    this.files = const [],
    this.clientFeedback,
    this.reviewAction,
  });

  factory ClientDesignProject.fromJson(Map<String, dynamic> json) {
    // Parse assignedTo — may be a nested object or null
    ClientDesignProjectAssignee? assignee;
    final raw = json['assignedTo'];
    if (raw is Map<String, dynamic>) {
      assignee = ClientDesignProjectAssignee.fromJson(raw);
    }

    // Parse files list
    final rawFiles = json['files'];
    final filesList = <ClientDesignProjectFile>[];
    if (rawFiles is List) {
      for (final f in rawFiles) {
        if (f is Map<String, dynamic>) {
          filesList.add(ClientDesignProjectFile.fromJson(f));
        }
      }
    }

    // designType may come back as a single String or a List<String>
    // (design type is now multi-select on assign-task screens).
    final rawType = json['designType'];
    final designTypeStr = rawType is List
        ? rawType.map((e) => e.toString()).join(', ')
        : (rawType as String? ?? '');

    return ClientDesignProject(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      designType: designTypeStr,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      assignedTo: assignee,
      files: filesList,
      clientFeedback: json['clientFeedback'] as String?,
      reviewAction: json['reviewAction'] as String?,
    );
  }

  // Convenience helpers
  bool get isPendingReview =>
      status.toLowerCase() == 'review' ||
          status.toLowerCase() == 'pending review';

  bool get isApproved => status.toLowerCase() == 'approved';

  bool get isInProgress =>
      status.toLowerCase() == 'in progress' ||
          status.toLowerCase() == 'inprogress';

  bool get isCompleted => status.toLowerCase() == 'completed';

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
      default:
        return status;
    }
  }

  double get progressFraction =>
      (progressPercentage.clamp(0, 100)) / 100.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Review request body
// ─────────────────────────────────────────────────────────────────────────────

class ClientDesignProjectReviewRequest {
  /// 'approved' or 'changes_requested'
  final String action;
  final String feedback;

  const ClientDesignProjectReviewRequest({
    required this.action,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'feedback': feedback,
  };
}