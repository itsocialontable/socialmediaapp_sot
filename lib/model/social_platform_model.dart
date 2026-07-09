import 'package:flutter/material.dart';

/// Model used to represent each supported social platform and its connection state.
class SocialPlatformModel {
  final String platform;
  final String name;
  final IconData icon;
  final Color color;
  final bool connected;
  final String? accountId;
  final String? connectedAs;
  final String? statusMessage;

  const SocialPlatformModel({
    required this.platform,
    required this.name,
    required this.icon,
    required this.color,
    this.connected = false,
    this.accountId,
    this.connectedAs,
    this.statusMessage,
  });

  SocialPlatformModel copyWith({
    bool? connected,
    String? accountId,
    String? connectedAs,
    String? statusMessage,
  }) {
    return SocialPlatformModel(
      platform: platform,
      name: name,
      icon: icon,
      color: color,
      connected: connected ?? this.connected,
      accountId: accountId ?? this.accountId,
      connectedAs: connectedAs ?? this.connectedAs,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  String get connectionLabel {
    if (connected) {
      return connectedAs != null && connectedAs!.isNotEmpty ? connectedAs! : 'Connected';
    }
    return 'Not connected';
  }

  static const List<SocialPlatformModel> supportedPlatforms = [
    SocialPlatformModel(
      platform: 'instagram',
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE1306C),
    ),
    SocialPlatformModel(
      platform: 'youtube',
      name: 'YouTube',
      icon: Icons.play_circle_fill,
      color: Color(0xFFFF0000),
    ),
    SocialPlatformModel(
      platform: 'linkedin',
      name: 'LinkedIn',
      icon: Icons.business,
      color: Color(0xFF0A66C2),
    ),
    SocialPlatformModel(
      platform: 'twitter',
      name: 'Twitter',
      icon: Icons.alternate_email,
      color: Color(0xFF1DA1F2),
    ),
    SocialPlatformModel(
      platform: 'facebook',
      name: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
  ];

  factory SocialPlatformModel.fromConnectedAccountJson(Map<String, dynamic> json) {
    final platform = (json['platform'] ?? json['network'] ?? '').toString().toLowerCase();
    final accountId = json['id']?.toString() ?? json['accountId']?.toString();
    final connectedAs = json['username']?.toString() ?? json['name']?.toString() ?? json['displayName']?.toString();

    return SocialPlatformModel(
      platform: platform,
      name: platform,
      icon: Icons.public,
      color: const Color(0xFF607D8B),
      connected: true,
      accountId: accountId,
      connectedAs: connectedAs,
      statusMessage: connectedAs != null ? 'Connected as $connectedAs' : 'Connected',
    );
  }
}
