// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// import 'package:mindfreak/main.dart';
// import 'package:mindfreak/notification_service.dart';
// import 'package:mindfreak/mqtt_service.dart';

// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     final notificationService = NotificationService();
//     final mqttService = MqttService(notificationService);

//     await tester.pumpWidget(MyApp(notificationService: notificationService, mqttService: mqttService));
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);

//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();

//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindfreak/main.dart';
import 'package:mindfreak/notification_service.dart';

void main() {
  testWidgets('Subscription form test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final notificationService = NotificationService();

    await tester.pumpWidget(MyApp(notificationService: notificationService));

    // Verify that we start on the subscription page.
    expect(find.text('Leakage Detector - Subscribe'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter a topic and tap subscribe.
    await tester.enterText(find.byType(TextField), 'test/topic');
    await tester.tap(find.text('Subscribe'));
    await tester.pump();

    // Verify the topic has been added.
    expect(find.text('test/topic'), findsOneWidget);
  });

  testWidgets('Silence Notification button test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final notificationService = NotificationService();

    await tester.pumpWidget(MyApp(notificationService: notificationService));

    // Tap the silence notification button.
    await tester.tap(find.byIcon(Icons.notifications_off));
    await tester.pump();

    // Here you can add further assertions to verify the expected behavior
    // when the silence notification button is pressed.
  });
}
