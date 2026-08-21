import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/alarm.dart';

class FullScreenAlert extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;

  const FullScreenAlert({super.key, required this.alarm, required this.onDismiss});

  @override
  State<FullScreenAlert> createState() => _FullScreenAlertState();
}

class _FullScreenAlertState extends State<FullScreenAlert> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _playAlarm();
  }

  Future<void> _playAlarm() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    // Uses the default system notification sound — for a custom tune, bundle an asset
    await _player.play(AssetSource('alarm.mp3')).catchError((_) {
      // If no asset, fall back silently — the visual alert still works
    });
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8C00), Color(0xFFFF6600)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: const Icon(Icons.location_pin, size: 120, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text("You've arrived!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  widget.alarm.label.isNotEmpty ? widget.alarm.label : 'You reached the target location',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                GestureDetector(
                  onTap: () {
                    _player.stop();
                    widget.onDismiss();
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: const Center(
                      child: Text("I'm here", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
