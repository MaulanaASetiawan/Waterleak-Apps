import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'mqtt_service.dart';
import 'notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "firebase.env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  final notificationService = NotificationService();
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MqttService mqttService;
  late String _deviceId;
  int _selectedIndex = 0;
  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _deviceId = await getDeviceId();
    mqttService = MqttService(widget.notificationService, _deviceId);
    await requestNotificationPermission();
    await mqttService.connect();
    await mqttService.loadSubscribedTopics();
    mqttService.listen();
    setState(() {});
  }

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'Unknown Android ID';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown iOS ID';
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: _selectedIndex == 0
              ? const Text('Leakage Detector - Subscribe')
              : const Text('Subscribed Topics'),
        ),
        body: _selectedIndex == 0
            ? _buildSubscriptionForm()
            : _buildSubscribedTopicsList(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Subscribe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Topics',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            widget.notificationService.stopAlarm();
          },
          tooltip: 'Silence Notification',
          child: const Icon(Icons.notifications_off),
        ),
      ),
    );
  }

  Widget _buildSubscriptionForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: 'MQTT Topic'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final topic = _topicController.text;
              if (topic.isNotEmpty) {
                mqttService.subscribe(topic);
                setState(() {});
                _topicController.clear();
              }
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribedTopicsList() {
    final topics = mqttService.subscribedTopics;
    return ListView.builder(
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return ListTile(
          title: Text(topic),
          trailing: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              mqttService.unsubscribe(topic);
              setState(() {});
            },
          ),
        );
      },
    );
  }
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.request().isGranted) {
    print("Access Granted");
  } else {
    print("Access Denied");
  }
}