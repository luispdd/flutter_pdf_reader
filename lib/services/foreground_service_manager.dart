import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(NarrationTaskHandler());
}

class NarrationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isDestroyed) async {}
}

class ForegroundServiceManager {
  static bool _isInitialized = false;

  static void init() {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'narration_foreground_service',
        channelName: 'Document Narration Service',
        channelDescription: 'Active narration playback keeps Dart runtime active',
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final NotificationPermission notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (e) {
      debugPrint('Error requesting foreground permissions: $e');
    }
  }

  static Future<void> startService({
    required String title,
    required String text,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await requestPermissions();

      if (await FlutterForegroundTask.isRunningService) {
        await updateService(title: title, text: text);
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: title,
        notificationText: text,
        callback: startForegroundCallback,
      );
    } catch (e) {
      debugPrint('Error starting foreground service: $e');
    }
  }

  static Future<void> updateService({
    required String title,
    required String text,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (e) {
      debugPrint('Error updating foreground service: $e');
    }
  }

  static Future<void> stopService() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('Error stopping foreground service: $e');
    }
  }
}
