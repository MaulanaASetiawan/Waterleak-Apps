import 'package:firebase_database/firebase_database.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'notification_service.dart';

class MqttService {
  final MqttServerClient client = MqttServerClient('broker.mqtt.cool', '');
  final NotificationService notificationService;
  final String deviceId;
  final List<String> _subscribedTopics = [];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  MqttService(this.notificationService, this.deviceId) {
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;
  }

  Future<void> connect() async {
    try {
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('MqttClient')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      print('Connecting to the MQTT broker...');
      await client.connect();
      listen();
    } catch (e) {
      print('Error: $e');
      client.disconnect();
    }
  }

  void onConnected() {
    print('Connected');
    for (var topic in _subscribedTopics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void onDisconnected() {
    print('Disconnected');
    connect();
  }

  void onSubscribed(String topic) {
    print('Subscribed: $topic');
  }

  void onUnsubscribed(String topic) {
    print('Unsubscribed: $topic');
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void subscribe(String topic) {
    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
      client.subscribe(topic, MqttQos.atMostOnce);
      _saveSubscriptionToDatabase(topic);
    }
  }

  void unsubscribe(String topic) {
    if (_subscribedTopics.contains(topic)) {
      _subscribedTopics.remove(topic);
      client.unsubscribe(topic);
      _removeSubscriptionFromDatabase(topic);
    }
  }

  List<String> get subscribedTopics => _subscribedTopics;

  void listen() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMessage = messages[0].payload as MqttPublishMessage;
      final String message = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('Received message: $message on topic: ${messages[0].topic}');

      if (message.contains('1')) {
        print('Leakage detected!');
        notificationService.showNotification('Leakage Alert', 'Leakage detected from tool ${messages[0].topic}');
      }
    });
  }

  String sanitizeDeviceId(String deviceId) {
    return deviceId.replaceAll(RegExp(r'[.#$[\]]'), '_');
  }

  Future<void> subscribes(String topic) async {
    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
      client.subscribe(topic, MqttQos.atMostOnce);
      _saveSubscriptionToDatabase(topic);
    }
  }

  Future<void> _saveSubscriptionToDatabase(String topic) async {
    final sanitizedDeviceId = sanitizeDeviceId(deviceId);
    await _dbRef.child('subscriptions/$sanitizedDeviceId/$topic').set({
      'topic': topic,
    });
  }

  Future<void> _removeSubscriptionFromDatabase(String topic) async {
    final sanitizedDeviceId = sanitizeDeviceId(deviceId);
    await _dbRef.child('subscriptions/$sanitizedDeviceId/$topic').remove();
  }

  Future<void> loadSubscribedTopics() async {
    final sanitizedDeviceId = sanitizeDeviceId(deviceId);
    final snapshot = await _dbRef.child('subscriptions/$sanitizedDeviceId').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        _subscribedTopics.add(value['topic']);
      });

      for (var topic in _subscribedTopics) {
        client.subscribe(topic, MqttQos.atMostOnce);
      }
    }
  }
}
