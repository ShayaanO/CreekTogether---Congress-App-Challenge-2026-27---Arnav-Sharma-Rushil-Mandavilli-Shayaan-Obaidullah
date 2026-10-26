import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';


final FlutterTts tts = FlutterTts();

Future<void> speak(String text) async {
  await tts.setLanguage('en-US');
  await tts.setSpeechRate(0.5);
  await tts.stop();
  await tts.speak(text);
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Include CO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Read this screen aloud',
            onPressed: () => speak('Welcome to Include Creek Together. Find resources for students, parents, and adults.'),
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to Include Creek Together')),
    );
  }
}