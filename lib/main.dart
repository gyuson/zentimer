import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:ui' as ui;

// Forest Green color definition
const Color forestGreen = Color(0xFF228B22);

// Forest Green swatch definition
const Map<int, Color> forestGreenSwatch = {
  50: Color(0xFFE6F2E6),
  100: Color(0xFFC0DFC0),
  200: Color(0xFF97CB97),
  300: Color(0xFF6FB76F),
  400: Color(0xFF52A852),
  500: Color(0xFF228B22), // main shade
  600: Color(0xFF1E821E),
  700: Color(0xFF197619),
  800: Color(0xFF146A14),
  900: Color(0xFF0C580C),
};

const MaterialColor customForestGreen =
    MaterialColor(0xFF228B22, forestGreenSwatch);

class EnsoPainter extends CustomPainter {
  final double progress;

  EnsoPainter({this.progress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 28; // Define the stroke width
    final double adjustedRadius =
        size.width / 2 - strokeWidth / 2; // Adjust the radius

    Paint basePaint = Paint()
      ..color = Colors.black.withOpacity(0.2) // Semi-transparent for the base
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1); // Slight blur effect

    Paint progressPaint = Paint()
      ..shader = ui.Gradient.linear(
        size.center(Offset.zero),
        size.center(Offset(size.width, size.height)),
        [Colors.black.withOpacity(0.1), Colors.black],
      )
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1); // Slight blur effect

    Rect arcRect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: adjustedRadius);

    // Draw the base Enso circle
    double baseAngle = 2 * pi;
    canvas.drawArc(arcRect, 0, baseAngle, false, basePaint);

    // Draw the progress arc
    double progressAngle = 2 * pi * progress;
    canvas.drawArc(arcRect, -pi / 2, progressAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

void main() {
  runApp(ZenTimer());
}

class ZenTimer extends StatefulWidget {
  @override
  _ZenTimerState createState() => _ZenTimerState();
}

class _ZenTimerState extends State<ZenTimer> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenTimer',
      theme: ThemeData(
        primarySwatch: customForestGreen,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int totalDuration =
      60 * 60; // Total duration for a full Enso circle in seconds (60 minutes)
  int _selectedTime = 10 * 60; // Default selected time in seconds (10 minutes)
  int _timeLeft; // Time left in seconds
  Timer? _timer; // Timer instance
  bool _isRunning = false; // Timer state
  double _ensoProgress; // Progress of the Enso

  final player = AudioPlayer();

  // Constructor
  _MyHomePageState()
      : _timeLeft = 10 * 60,
        _ensoProgress = 10 / 60;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  Future<void> _playStartSound() async {
    await player.setSource(AssetSource('sounds/zenbellstart.mp3'));
    await player.resume();
  }

  Future<void> _playEndSound() async {
    await player.setSource(AssetSource('sounds/zenbellend.mp3'));
    await player.resume();
  }


  void _startPauseTimer() {
    if (_isRunning) {
      // Pause the timer
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      // Play the start sound
      _playStartSound();
      // Check if the timer is at 0 and reset to the selected time if needed
      if (_timeLeft == 0) {
        setState(() {
          _timeLeft = _selectedTime;
          _ensoProgress = _selectedTime / totalDuration;
        });
      }
      // Start the timer
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
            _ensoProgress =
                _timeLeft / totalDuration; // Update the Enso progress
          });
        } else {
          _timer!.cancel();
          setState(() {
            _isRunning = false;
            _ensoProgress = 0; // Reset the Enso progress when timer finishes
          });
          // Play the end sound
          _playEndSound();
        }
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _stopResetTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    // It's safe to call setState only if the widget is mounted.
    if (mounted) {
      setState(() {
        _timeLeft = 0;
        _ensoProgress = 0;
        _isRunning = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZenTimer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onPanUpdate: (DragUpdateDetails details) {
                // Get the position of the drag gesture relative to the widge
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);

                // Assuming the center of the dial is at the cneter o fthe render box
                double centerX = renderBox.size.width / 2;
                double centerY = renderBox.size.height / 2;

                // Calculate the angle and map it to a time value
                double dx = localPosition.dx - centerX;
                double dy = localPosition.dy - centerY;
                double angle = atan2(dy, dx);

                // Normalize the angle to a 0 - 360 degrees range
                if (angle < 0) {
                  angle += 2 * pi;
                }

                // convert angle to degrees
                double angleInDegrees = angle * 180 / pi;

                // Map the angle to a time value (360 degrees = 60 minutes)
                int timeValue = (angleInDegrees / 360 * 60).round();

                // Update the timer duration
                setState(() {
                  _timeLeft = max(0, min(timeValue, 60));
                });

                double progress = angleInDegrees / 360;

                setState(() {
                  _ensoProgress = progress;
                });
              },
              child: CustomPaint(
                painter: EnsoPainter(progress: _ensoProgress),
                size: Size(300, 300), // Define a suitable size for the dial
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${(_timeLeft ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
                height:
                    20), // Adds some space between the timer and the progress indicator
            const SizedBox(
                height:
                    30), // Adds some space between the progress indicator and the buttons
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // Spreads out buttons evenly in a row
              children: <Widget>[
                ElevatedButton(
                  onPressed:
                      _startPauseTimer, // Replace with actual functionality
                  child: Icon(_isRunning
                      ? Icons.pause
                      : Icons.play_arrow), // Play/pause button
                ),
                ElevatedButton(
                  onPressed:
                      _stopResetTimer, // Replace with actual functionality
                  child: Icon(Icons.stop), // Stop button
                ),
                ElevatedButton(
                  onPressed:
                      _stopResetTimer, // Replace with actual functionality
                  child: Icon(Icons.refresh), // Reset button
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
