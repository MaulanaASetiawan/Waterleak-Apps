import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  final AudioPlayer audioPlayer = AudioPlayer();

  NotificationService() {
    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'leaks_detector',
          channelName: 'Leaks Detector',
          channelDescription: 'Notification channel for leak detections',
          importance: NotificationImportance.Max,
          playSound: false,
          enableVibration: true,
        )
      ],
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedNotification) async {
        if (receivedNotification.buttonKeyPressed == 'STOP_ALARM') {
          stopAlarm();
        }
      },
    );
  }

  Future<void> showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'leaks_detector',
        title: title,
        body: body,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_ALARM',
          label: 'Stop Alarm',
        ),
      ],
    );

    playAlarm();
  }

  void playAlarm() async {
    print("Playing alarm sound");
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource('danger.mp3'), volume: 1.0);
  }

  void stopAlarm() async {
    print("Stopping alarm sound");
    await audioPlayer.stop();
    await AwesomeNotifications().cancel(0);
  }
}
