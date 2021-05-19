import 'dart:convert';

import 'package:generation_official/BackendAndDatabaseManager/Dataset/data_type.dart';
import 'package:http/http.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SendNotification {
  Future<void> messageNotificationClassifier(MediaTypes? mediaTypes,
      {String textMsg = '',
      required String? connectionToken,
      required String? currAccountUserName}) async {
    print('Token is: $connectionToken');

    // ignore: missing_enum_constant_in_switch
    switch (mediaTypes) {
      case MediaTypes.Text:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Message",
          body: textMsg,
        );
        break;

      case MediaTypes.Voice:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Voice",
          body: '',
        );
        break;

      case MediaTypes.Image:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Image",
          body: textMsg,
        );
        break;

      case MediaTypes.Video:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Video",
          body: textMsg,
        );
        break;

      case MediaTypes.Sticker:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Sticker",
          body: '',
        );
        break;

      case MediaTypes.Location:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You Device Location",
          body: textMsg,
        );
        break;

      case MediaTypes.Document:
        await sendNotification(
          token: connectionToken.toString(),
          title: "$currAccountUserName Send You a Document",
          body: textMsg,
        );
        break;

      case MediaTypes.Indicator:
        break;
    }
  }

  Future<int> sendNotification(
      {required String token,
      required String title,
      required String body}) async {
    try {
      print('Send');

      final String _serverKey =
          'AAAAhYAupkM:APA91bENB9fuZLd3VKNaDLMordtXDJAggph3pp4SJRnJBQs8ZOodjS05url3ef0AILjoI2FE6qf3xImVGrfjymZX2jIBXN1QqBXLRt_VVG7wnduCtw8ntbHBTHT133_gy7weQ5eNMhk0';

      final Response response = await post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            "collapse_key": "type_a",
          },
          'to': token,
        }),
      );

      print('Response is: ${response.statusCode}');

      return response.statusCode;
    } catch (e) {
      print(' Send Notification Error : ${e.toString()}');

      return 404;
    }
  }
}

class ForeGroundNotificationReceiveAndShow {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings _androidInitializationSettings =
      AndroidInitializationSettings('app_icon');

  ForeGroundNotificationReceiveAndShow() {
    final InitializationSettings _initializationSettings =
        InitializationSettings(android: _androidInitializationSettings);

    print('Noti Here');

    initAll(_initializationSettings);
  }

  initAll(InitializationSettings initializationSettings) async {
    Future<bool?> response = (await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: notificationSelected)) as Future<bool?>;

    print('Local Notification Initialization Status: $response');
  }

  Future<void> showNotification(
      {required String? title, required String? body}) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
              "Channel ID", "Generation Official", "This is Generation App",
              importance: Importance.max);

      final NotificationDetails generalNotificationDetails =
          NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin
          .show(0, title, body, generalNotificationDetails, payload: title);
    } catch (e) {
      print('Show Notification Error: ${e.toString()}');
    }
  }

  Future notificationSelected(String? payload) async {
    print('On Select Notification Payload: $payload');
  }
}
