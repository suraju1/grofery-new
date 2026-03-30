import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'global_keys.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
    icon: 'notification', // Small icon
    largeIcon: const DrawableResourceAndroidBitmap('notification'),
    fullScreenIntent: true,
  );

  DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    subtitle: 'Background Notification',
    threadIdentifier: 'foreground_threat', // Optional: thread identifier
    presentAlert: true, // Show the alert
    presentBadge: true, // Show the badge
    presentSound: true, // Show the sound
  );

  // Show default notification for background messages
  FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

class NotificationService {
  late BuildContext? context;
  NotificationService({this.context});

  // Static flag to prevent concurrent requestPermission() calls
  static bool _permissionRequested = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initFirebaseMessaging(BuildContext context) async {
    // Firebase is already initialized in main() — do NOT call initializeApp() again here
    await _requestNotificationPermissions();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground Title: ${message.notification?.title}');
      log('Foreground Body: ${message.notification?.body}');
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Message opened app: ${message.notification?.title}');
      _handleNavigation(message);
    });

    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      log('New FCM Token: $newToken');
    });

    // Get FCM token right after permissions are settled
    final token = await getFcmToken();
    if (token != null) {
      log('FCM Token (post-permission): $token');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    // Guard: only one requestPermission() call at a time
    if (_permissionRequested) {
      log('Notification permission request already in progress, skipping.');
      return;
    }
    _permissionRequested = true;
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      log('Error requesting notification permission: $e');
    } finally {
      _permissionRequested = false;
    }
  }

  Future<String?> getFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        log('FCM Token retrieved successfully');
      }
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  void _showForegroundNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
            'order-foreground', 'order-foreground-channel',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification',
            largeIcon:
                const DrawableResourceAndroidBitmap('@drawable/notification'),
            fullScreenIntent: true,
            enableVibration: true,
            enableLights: true);

    final DarwinNotificationDetails iosDetails =
        const DarwinNotificationDetails(
      subtitle: 'Foreground Notification',
      // sound: notificationSoundIOS,
      threadIdentifier: 'foreground_threat',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
        1,
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body',
        notificationDetails,
        payload: message.data['order_slug']);
  }

  Future<void> showBackgroundNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
            'order-background', 'order-background-channel',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification',
            largeIcon: DrawableResourceAndroidBitmap('@drawable/notification'),
            fullScreenIntent: true,
            enableVibration: true,
            enableLights: true);

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Background Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
    );
  }

  void _handleNavigation(RemoteMessage message) {
    final type = message.data['type'];
    final orderStatus = message.data['type'];
    final orderSlug = message.data['order_slug'];
    final navigatorContext = GlobalKeys.navigatorKey.currentContext;

    if (navigatorContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (type == 'order' || type == 'delivered') {
          if (orderStatus == 'assigned' ||
              orderStatus == 'collected' ||
              orderStatus == 'out_for_delivery') {
            GoRouter.of(navigatorContext).push(AppRoutes.deliveryTracking,
                extra: {'order-slug': orderSlug});
          } else {
            GoRouter.of(navigatorContext)
                .push(AppRoutes.orderDetail, extra: {'order-slug': orderSlug});
          }
        }
      });
    }
  }
}

/// Gets the FCM token. Permissions must already have been requested
/// via [NotificationService.initFirebaseMessaging] before calling this.
Future<String?> getFCMToken() async {
  try {
    // Do NOT call requestPermission() here — it is already handled by
    // NotificationService.initFirebaseMessaging() at app startup.
    // Calling it again simultaneously causes a crash.
    final fcmToken = await FirebaseMessaging.instance.getToken();
    log('FCM Token: $fcmToken');
    return fcmToken;
  } catch (e) {
    log('Error getting FCM token: $e');
    return null;
  }
}
