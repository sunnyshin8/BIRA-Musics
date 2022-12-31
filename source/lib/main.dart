import 'package:flutter/material.dart';
import 'package:bira/screens/app.dart';
// import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
  //   androidNotificationChannelName: 'Audio playback',
  //   androidNotificationOngoing: true,
  // );
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIRA Musics',
      theme: ThemeData(
        disabledColor: Colors.grey,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
    );
  }
}