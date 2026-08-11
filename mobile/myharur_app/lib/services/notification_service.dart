import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';
import '../api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _bgTimer;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> showNotification({required String title, required String body}) async {
    if (await Permission.notification.isGranted) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'myharur_channel',
        'MyHarur Notifications',
        channelDescription: 'General updates and alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
      );
    }
  }

  void startSimulatedUpdates() {
    _bgTimer?.cancel();
    // Simulate background updates every hour, but for testing, let's just do it every 15 minutes.
    _bgTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final random = Random().nextInt(3);
      if (random == 0) {
        // Fetch weather
        try {
          final res = await ApiClient.dio.get('/news/weather');
          final temp = res.data['temperature'];
          final condition = res.data['condition'];
          await showNotification(
            title: 'Weather Update ⛅',
            body: 'Current weather in Harur: $temp°C, $condition.',
          );
        } catch (e) {
          // Ignore
        }
      } else if (random == 1) {
        // Fetch a recent news item
        try {
          final res = await ApiClient.dio.get('/news', queryParameters: {'limit': 1});
          if (res.data != null && res.data.isNotEmpty) {
            final news = res.data[0];
            await showNotification(
              title: 'Harur News 📰',
              body: news['title'] ?? 'Check out the latest local updates!',
            );
          }
        } catch (e) {
           // Ignore
        }
      } else {
        await showNotification(
          title: 'MyHarur Reminder 💡',
          body: 'Check out the latest town discussions in the Community tab!',
        );
      }
    });
  }
}
