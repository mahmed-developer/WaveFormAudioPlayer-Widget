import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class WaveFormAudioPlayer extends StatefulWidget {
  final String audioPath;
  final bool isAsset;

  const WaveFormAudioPlayer({
    Key? key,
    required this.audioPath,
    this.isAsset = false,
  }) : super(key: key);

  @override
  State<WaveFormAudioPlayer> createState() => _WaveFormAudioPlayerState();
}

class _WaveFormAudioPlayerState extends State<WaveFormAudioPlayer>
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
    // Generate smoother waveform data with more points
    waveformData = _generateSmoothWaveform(85);

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Create a curved animation for smoother progress
    smoothProgress = CurvedAnimation(
      parent: progressController,
      curve: Curves.easeInOut,
    );
  }

  List<double> _generateSmoothWaveform(int points) {
    List<double> smoothData = [];
    final random = math.Random();

    // Generate initial random points
    List<double> basePoints = List.generate(points ~/ 2, (index) => 0.3 + random.nextDouble() * 0.4);

    // Interpolate between points for smoothness
    for (int i = 0; i < basePoints.length - 1; i++) {
      smoothData.add(basePoints[i]);
      double mid = (basePoints[i] + basePoints[i + 1]) / 2;
      smoothData.add(mid);
    }
    smoothData.add(basePoints.last);

    return smoothData;
  }

  void _initializePlayer() async {
    try {
      audioPlayer = AudioPlayer();

      if (widget.isAsset) {
        await audioPlayer.setSource(AssetSource(widget.audioPath));
      } else {
        if (kIsWeb) {
          await audioPlayer.setSourceUrl(widget.audioPath);
        } else {
          await audioPlayer.setSource(DeviceFileSource(widget.audioPath));
        }
      }

      audioPlayer.onPositionChanged.listen((Duration p) {
        if (mounted) {
          setState(() {
            position = p;
            if (duration.inMilliseconds > 0) {
              progressController.value = p.inMilliseconds / duration.inMilliseconds;
            }
          });
        }
      });

      audioPlayer.onDurationChanged.listen((Duration d) {
        if (mounted) {
          setState(() {
            duration = d;
          });
        }
      });

      audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            isPlaying = state == PlayerState.playing;
          });
        }
      });

      setState(() {
        isPlayerReady = true;
      });
    } catch (e) {
      print('Error initializing player: $e');
    }
  }


  void _seekToPosition(double tapPosition, BoxConstraints constraints) {
    if (!isPlayerReady) return;

    final seekPosition = (tapPosition / constraints.maxWidth) * duration.inMilliseconds;
    audioPlayer.seek(Duration(milliseconds: seekPosition.toInt()));
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    progressController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button with animation
          AnimatedScale(
            scale: isPlayerReady ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  key: ValueKey<bool>(isPlaying),
                  color: Colors.blue,
                  size: 32,
                ),
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
          ),

          // Waveform with touch interaction
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapDown: (details) {
                  _seekToPosition(details.localPosition.dx, constraints);
                },
                onHorizontalDragUpdate: (details) {
                  _seekToPosition(details.localPosition.dx, constraints);
                },
                child: Container(
                  width: 350,
                  height: 80,
                  color: Colors.transparent,
                  child: AnimatedBuilder(
                    animation: smoothProgress,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          waveformData: waveformData,
                          progress: progressController.value,
                          activeColor: Colors.blue,
                          inactiveColor: Colors.blue.shade200,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Duration with animation
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 100),
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 12,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(_formatDuration(isPlaying ? duration - position : duration)),
            ),
          ),
        ],
      ),
    );
  }
}

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
      ..strokeWidth = 3.0 // Increased stroke width for better visibility
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / (waveformData.length * 1); // Adjusted for wider waveform
    final middleY = size.height / 2;
    final progressX = size.width * progress;

    for (var i = 0; i < waveformData.length; i++) {
      final x = i * spacing;
      final magnitude = waveformData[i] * size.height / 2;

      final distanceToProgress = (x - progressX).abs();
      final hoverEffect = math.max(0, 1 - distanceToProgress / 20);

      paint.color = x <= progressX
          ? activeColor.withOpacity(0.7 + hoverEffect * 0.3)
          : inactiveColor.withOpacity(0.5 + hoverEffect * 0.3);

      final wave = math.sin(x / 50 + progress * 10) * 2;

      canvas.drawLine(
        Offset(x, middleY + magnitude / 2 + (x <= progressX ? wave : 0)),
        Offset(x, middleY - magnitude / 2 + (x <= progressX ? wave : 0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveformData != waveformData;
  }
}