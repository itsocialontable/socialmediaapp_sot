import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({
    super.key,
    required this.info,
  });

  static Future<void> show(
      BuildContext context,
      UpdateInfo info,
      ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F1629),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),

        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                'Update Available',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            if (!_downloading)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                ),
              ),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${widget.info.latestVersion}) is available.',
              style: GoogleFonts.sora(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            if (widget.info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.info.releaseNotes,
                  style: GoogleFonts.sora(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            if (_downloading) ...[
              const SizedBox(height: 16),

              Text(
                'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.sora(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF667EEA),
                  ),
                  minHeight: 6,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),

              Text(
                _error!,
                style: GoogleFonts.sora(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),

        actions: _downloading
            ? []
            : [
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update Now',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    await UpdateService.downloadAndInstall(
      widget.info,
      onProgress: (p) {
        setState(() {
          _progress = p;
        });
      },
      onError: (e) {
        setState(() {
          _error = e;
          _downloading = false;
        });
      },
    );
  }
}