import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:quizzer/data/services/database_service.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  
  const TutorialScreen({super.key, required this.onDone});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  // Custom durations for each slide based on the amount of text
  final List<Duration> _slideDurations = [
    const Duration(seconds: 15),
    const Duration(seconds: 15),
    const Duration(seconds: 15),
    const Duration(seconds: 15),
  ];
  
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _currentProgress = 0.0;
    const tickInterval = Duration(milliseconds: 50);
    _timer = Timer.periodic(tickInterval, (timer) {
      setState(() {
        final totalDuration = _slideDurations[_currentPage].inMilliseconds;
        _currentProgress += tickInterval.inMilliseconds / totalDuration;
        if (_currentProgress >= 1.0) {
          _timer?.cancel();
          _nextPage();
        }
      });
    });
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }
  
  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _finishTutorial() async {
    _timer?.cancel();
    // Mark tutorial as seen
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();
    if (!settings.hasSeenTutorial) {
      settings.hasSeenTutorial = true;
      await db.saveSettings(settings);
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode == 'ru' ? 'ru' : 'en';

    final slides = [
      _SlideData(
        imagePath: 'assets/images/tutorial/$locale/1.png',
      ),
      _SlideData(
        imagePath: 'assets/images/tutorial/$locale/2.png',
      ),
      _SlideData(
        imagePath: 'assets/images/tutorial/$locale/3.png',
      ),
      _SlideData(
        imagePath: 'assets/images/tutorial/$locale/4.png',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for a stories feel
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _prevPage();
            } else {
              _nextPage();
            }
          },
          onLongPressDown: (_) {
            _timer?.cancel();
          },
          onLongPressUp: () {
            _startTimer();
          },
          onLongPressCancel: () {
            _startTimer();
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _startTimer();
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(slides[index]);
                },
              ),
              // Progress bars at the top
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(slides.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _buildProgressBar(index),
                      ),
                    );
                  }),
                ),
              ),
              // Skip / Done buttons at the bottom
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _finishTutorial,
                      child: Text(
                        loc.tutorialSkip,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _currentPage == slides.length - 1 ? loc.tutorialDone : loc.tutorialNext,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    double value = 0.0;
    if (index < _currentPage) {
      value = 1.0;
    } else if (index == _currentPage) {
      value = _currentProgress;
    }

    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.white38,
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      minHeight: 3,
      borderRadius: BorderRadius.circular(1.5),
    );
  }

  Widget _buildSlide(_SlideData data) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 40.0, // Space for progress bars
        bottom: 80.0, // Space for buttons
        left: 16.0,
        right: 16.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          data.imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SlideData {
  final String imagePath;

  _SlideData({
    required this.imagePath,
  });
}
