import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const GlassVideoPlayerApp());
}

class GlassVideoPlayerApp extends StatelessWidget {
  const GlassVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _showSpeedPanel = false;
  double _currentSpeed = 1.0;

  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    // Sample high-definition open-source video stream
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
    )..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _currentSpeed = speed;
      _controller.setPlaybackSpeed(speed);
      _showSpeedPanel = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
            if (!_showControls) _showSpeedPanel = false;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Video Canvas
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white70),
            ),

            // 2. Play/Pause Big Center Indicator on Tap
            if (_showControls && _controller.value.isInitialized)
              IconButton(
                iconSize: 64,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.85),
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
              ),

            // 3. Floating Glassy Bottom Bar (Curved, Blur + Translucent)
            if (_showControls && _controller.value.isInitialized)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _buildGlassyBottomBar(),
              ),

            // 4. Compact 1/4th Screen iOS-Style Liquid Glass Speed Panel
            if (_showSpeedPanel)
              Positioned(
                right: 16,
                bottom: 95, // Positioned right above the speed button in the bottom bar
                width: (screenWidth * 0.28).clamp(95.0, 140.0), // Restrained to ~1/4 screen width
                child: _buildGlassySpeedPanel(),
              ),
          ],
        ),
      ),
    );
  }

  /// Glassy Bottom Bar with 85-90% transparency and frosted backdrop
  Widget _buildGlassyBottomBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10), // 90% transparent tint
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Slider
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                colors: VideoProgressColors(
                  playedColor: Colors.white.withOpacity(0.9),
                  bufferedColor: Colors.white.withOpacity(0.3),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Row(
                children: [
                  // Play / Pause Mini Toggle
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                  ),
                  // Time Counter
                  Text(
                    "${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),

                  // Integrated Bottom Bar Speed Indicator & Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSpeedPanel = !_showSpeedPanel;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showSpeedPanel
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            "${_currentSpeed}x",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1/4th Display Speed Popup: 90% transparent, blurred, iPhone-style rounded card
  Widget _buildGlassySpeedPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10), // Strict 90% transparency
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Playback Speed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withOpacity(0.15)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _speedOptions.length,
                  itemBuilder: (context, index) {
                    final speed = _speedOptions[index];
                    final isSelected = speed == _currentSpeed;

                    return InkWell(
                      onTap: () => _setPlaybackSpeed(speed),
                      child: Container(
                        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        alignment: Alignment.center,
                        child: Text(
                          "${speed}x",
                          style: TextStyle(
                            color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
