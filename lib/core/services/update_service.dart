import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String apkUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    latestVersion: json['version']?.toString() ?? '',
    latestBuild: int.tryParse(json['build']?.toString() ?? '0') ?? 0,
    apkUrl: json['apk_url']?.toString() ?? '',
    releaseNotes: json['release_notes']?.toString() ?? '',
  );
}

class UpdateService {
  static const String _versionCheckUrl =
      'https://raw.githubusercontent.com/Growthcraft360/SocialMediaApp/main/version.json';

  static final Dio _dio = Dio(BaseOptions(
    responseType: ResponseType.plain, // JSON string ke roop mein lo
  ));

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      print('=== UPDATE CHECK === App build: $currentBuild');

      final res = await _dio
          .get(_versionCheckUrl)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 || res.data == null) return null;

      // ResponseType.plain se string milti hai — json decode karo
      final jsonData = json.decode(res.data.toString()) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(jsonData);

      print('GitHub build: ${info.latestBuild}, App build: $currentBuild');

      if (info.latestBuild > currentBuild) return info;
      return null;
    } catch (e) {
      print('UPDATE CHECK ERROR: $e');
      return null;
    }
  }

  static Future<void> downloadAndInstall(
      UpdateInfo info, {
        required void Function(double progress) onProgress,
        required void Function(String error) onError,
      }) async {
    try {
      if (!await Permission.requestInstallPackages.isGranted) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          onError('Install permission nahi mili. Settings mein jaake allow karo.');
          return;
        }
      }

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/growthcraft_update.apk';

      final dlDio = Dio();
      await dlDio.download(
        info.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onError('APK open nahi hua: ${result.message}');
      }
    } on DioException catch (e) {
      onError('Download fail: ${e.message ?? 'Network error'}');
    } catch (e) {
      onError('Kuch galat hua. Dobara try karo.');
    }
  }
}