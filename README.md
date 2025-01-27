# WaveFormAudioPlayer-Widget
🎵 Flutter Audio Player with Waveform Visualization &amp; Seek Functionality
👋 Welcome!

🚀 We will build a 📱 WhatsApp-style 🎶 Player that includes:

▶️/⏸️ Functionality

📊 Visualization

🔄 Seek by 📍 or 📦

🎨 UI Elements

Let's go! 🏁


## **🔧 Step 1: Setup 🛠️**
📦 Add this to `pubspec.yaml`:
```yaml
  dependencies:
    flutter:
      sdk: flutter
    audioplayers: ^5.2.1
```
Run `flutter pub get` 🏃‍♂️

---

## **🛠️ Step 2: Widget 📦**
```dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class WhatsAppStyleAudioPlayer extends StatefulWidget {
  final String audioPath;
  final bool isAsset;

  const WhatsAppStyleAudioPlayer({
    Key? key,
    required this.audioPath,
    this.isAsset = false,
  }) : super(key: key);

  @override
  State<WhatsAppStyleAudioPlayer> createState() => _WhatsAppStyleAudioPlayerState();
}
```
📌 **Params:**
- 🎵 Path
- 📂 Local or 📁 Asset?

---

## **🔊 Step 3: Init 🎛️**
```dart
class _WhatsAppStyleAudioPlayerState extends State<WhatsAppStyleAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlayerReady = false;
  late List<double> waveformData;
  late AnimationController progressController;
  late Animation<double> smoothProgress;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    waveformData = _generateSmoothWaveform(85);
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    smoothProgress = CurvedAnimation(
      parent: progressController,
      curve: Curves.easeInOut,
    );
  }
```
📌 **Key Points:**
- 🎶 Player
- 🎚️ Waveform
- 🎞️ Animation

---

## **📊 Step 4: Generate Waveform**
```dart
List<double> _generateSmoothWaveform(int points) {
  List<double> smoothData = [];
  final random = math.Random();
  List<double> basePoints = List.generate(points ~/ 2, (index) => 0.3 + random.nextDouble() * 0.4);
  for (int i = 0; i < basePoints.length - 1; i++) {
    smoothData.add(basePoints[i]);
    double mid = (basePoints[i] + basePoints[i + 1]) / 2;
    smoothData.add(mid);
  }
  smoothData.add(basePoints.last);
  return smoothData;
}
```
🎨 **Random Smooth Waveform!**

---

## **🎯 Step 5: Seek 🎚️**
```dart
void _seekToPosition(double tapPosition, BoxConstraints constraints) {
  if (!isPlayerReady) return;
  final seekPosition = (tapPosition / constraints.maxWidth) * duration.inMilliseconds;
  audioPlayer.seek(Duration(milliseconds: seekPosition.toInt()));
}
```
📌 **Tap 📍 to Seek!**

---

## **🎨 Step 6: UI 🖌️**
```dart
@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.blue,
            size: 32,
          ),
          onPressed: isPlayerReady
              ? () async {
                  if (isPlaying) {
                    await audioPlayer.pause();
                  } else {
                    await audioPlayer.resume();
                  }
                }
              : null,
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (details) {
              _seekToPosition(details.localPosition.dx, BoxConstraints.tight(Size(300, 50)));
            },
            child: CustomPaint(
              painter: WaveformPainter(
                waveformData: waveformData,
                progress: progressController.value,
                activeColor: Colors.blue,
                inactiveColor: Colors.blue.shade200,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(_formatDuration(isPlaying ? duration - position : duration)),
        ),
      ],
    ),
  );
}
```
📌 **🖼️ Play, Seek, Waveform!**

---

## **🖊️ Step 7: Draw 📊**
```dart
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / waveformData.length;
    final middleY = size.height / 2;
    final progressX = size.width * progress;

    for (var i = 0; i < waveformData.length; i++) {
      final x = i * spacing;
      final magnitude = waveformData[i] * size.height / 2;
      paint.color = x <= progressX ? activeColor : inactiveColor;
      canvas.drawLine(
        Offset(x, middleY + magnitude / 2),
        Offset(x, middleY - magnitude / 2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```
📊 **Dynamic Waveform Drawing!**

---

## **🎉 Final Thoughts!**
🎵 Congrats! You've built a **cool 🎧 Player** with:
✅ **Waveform 📊**
✅ **Seek 📍**
✅ **Smooth UI 🎨**

🛠️ **Try:**
- 🎨 Colors
- 🔊 Volume
- 🌍 Streaming URLs

🚀 **Happy Coding!** 🎶

