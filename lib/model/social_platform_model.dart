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

  /// Known platform → (label, color, icon) lookup, used only to style
  /// whatever platform key comes back from the API. This does NOT decide
  /// which platforms are shown — that list comes entirely from the API.
  static const Map<String, _PlatformMeta> _meta = {
    'instagram': _PlatformMeta('Instagram', Color(0xFFE1306C), Icons.camera_alt),
    'facebook': _PlatformMeta('Facebook', Color(0xFF1877F2), Icons.facebook),
    'twitter': _PlatformMeta('Twitter / X', Color(0xFF1DA1F2), Icons.alternate_email),
    'x': _PlatformMeta('Twitter / X', Color(0xFF1DA1F2), Icons.alternate_email),
    'linkedin': _PlatformMeta('LinkedIn', Color(0xFF0A66C2), Icons.business),
    'youtube': _PlatformMeta('YouTube', Color(0xFFFF0000), Icons.play_circle_fill),
    'pinterest': _PlatformMeta('Pinterest', Color(0xFFE60023), Icons.push_pin),
    'threads': _PlatformMeta('Threads', Color(0xFF000000), Icons.tag),
  };

  factory SocialPlatformModel.fromConnectedAccountJson(Map<String, dynamic> json) {
    final key = (json['platform'] ?? json['network'] ?? '').toString().toLowerCase();
    final meta = _meta[key] ?? _PlatformMeta(key.isEmpty ? 'Unknown' : key, const Color(0xFF607D8B), Icons.public);

    final accountId = json['id']?.toString() ?? json['accountId']?.toString() ?? json['_id']?.toString();
    final connectedAs = json['username']?.toString() ?? json['name']?.toString() ?? json['displayName']?.toString();

    // The API item itself decides connected/not — default to true only
    // when there's no explicit flag (e.g. it appeared in a "connected"
    // sub-list without its own status field).
    final connected = json.containsKey('connected')
        ? json['connected'] == true
        : json.containsKey('status')
        ? json['status'].toString().toLowerCase() == 'connected'
        : true;

    return SocialPlatformModel(
      platform: key,
      name: meta.label,
      icon: meta.icon,
      color: meta.color,
      connected: connected,
      accountId: accountId,
      connectedAs: connectedAs,
      statusMessage: connected ? (connectedAs != null ? 'Connected as $connectedAs' : 'Connected') : 'Not connected',
    );
  }
}

class _PlatformMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _PlatformMeta(this.label, this.color, this.icon);
}