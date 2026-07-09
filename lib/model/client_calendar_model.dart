// lib/model/client_calendar_model.dart

import 'package:flutter/material.dart';

class ClientCalendarPost {
  final String id;
  final String title;
  final String platform;
  final String status;
  final String? caption;
  final String? scheduledTime;
  final DateTime? scheduledAt;

  const ClientCalendarPost({
    required this.id,
    required this.title,
    required this.platform,
    required this.status,
    this.caption,
    this.scheduledTime,
    this.scheduledAt,
  });

  factory ClientCalendarPost.fromJson(Map<String, dynamic> json) {
    DateTime? scheduledAt;
    final rawDate =
        json['scheduledAt'] ?? json['scheduledDate'] ?? json['date'];
    if (rawDate != null) {
      scheduledAt = DateTime.tryParse(rawDate.toString());
    }

    // Build a human-readable time string if not supplied by the API
    String? scheduledTime = json['scheduledTime'] as String?;
    if (scheduledTime == null && scheduledAt != null) {
      final h = scheduledAt.hour;
      final m = scheduledAt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      scheduledTime = '$hour:$m $period';
    }

    return ClientCalendarPost(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ??
          json['postTitle'] as String? ??
          'Untitled Post',
      platform: json['platform'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      caption: json['caption'] as String?,
      scheduledTime: scheduledTime,
      scheduledAt: scheduledAt,
    );
  }

  // ── Platform colour ──────────────────────────────────────────────────────
  Color get platformColor {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'twitter':
      case 'x':
        return const Color(0xFF1DA1F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF9B59B6);
    }
  }

  // ── Platform icon ────────────────────────────────────────────────────────
  IconData get platformIcon {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'linkedin':
        return Icons.work_rounded;
      case 'twitter':
      case 'x':
        return Icons.tag_rounded;
      case 'youtube':
        return Icons.play_circle_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  // ── Status colour ────────────────────────────────────────────────────────
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'published':
        return const Color(0xFF27AE60);
      case 'scheduled':
        return const Color(0xFF2980B9);
      case 'draft':
        return const Color(0xFF95A5A6);
      case 'failed':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String get displayStatus {
    if (status.isEmpty) return 'Scheduled';
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}
