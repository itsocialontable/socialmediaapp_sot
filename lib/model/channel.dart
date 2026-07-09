import 'package:flutter/material.dart';

class SocialChannel {
  final String id;
  final String name;
  final IconData icon;
  final bool connected;
  const SocialChannel({required this.id, required this.name, required this.icon, this.connected = false});
}
