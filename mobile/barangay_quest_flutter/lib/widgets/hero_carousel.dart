// lib/widgets/hero_carousel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // For colors

// Data from HeroCarousel.jsx
class HeroSlide {
  final int id;
  final String image;
  final String headline;
  final String sub;

  HeroSlide({
    required this.id,
    required this.image,
    required this.headline,
    required this.sub,
  });
}

final List<HeroSlide> _slides = [
  HeroSlide(
    id: 1,
    image:
        "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=1600&auto=format&fit=crop",
    headline: "Find Your Quest. Empower Your Community",
    sub: "Barangay-vouched jobs & services",
  ),
  HeroSlide(
    id: 2,
    image:
        "https://images.unsplash.com/photo-1586880244543-8c56d1d0f6ef?q=80&w=1600&auto=format&fit=crop",
    headline: "Post Tasks That Matter",
    sub: "Get trusted help from verified members",
  ),
  HeroSlide(
    id: 3,
    image:
        "https://images.unsplash.com/photo-1522206024047-9c9254216756?q=80&w=1600&auto=format&fit=crop",
    headline: "Earn Safely with Escrow",
    sub: "Barangay-endorsed quests, secure payouts",
  ),
];

class HeroCarousel extends StatefulWidget {
  final VoidCallback onBrowse;
  final VoidCallback onPost;

  const HeroCarousel({
    super.key,
    required this.onBrowse,
    required this.onPost,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-advance timer
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500, // You can adjust this height
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias, // Clips the child stack
      child: Stack(
        children: [
          // --- PageView for Images ---
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _buildSlide(context, slide);
            },
          ),

          // --- Navigation Arrows ---
          Align(
            alignment: Alignment.centerLeft,
            child: _buildNavArrow(
              context,
              Icons.chevron_left,
              () => _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildNavArrow(
              context,
              Icons.chevron_right,
              () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ),

          // --- Dots Indicator ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Builds a single slide ---
  Widget _buildSlide(BuildContext context, HeroSlide slide) {
    return Stack(
      children: [
        // 1. Image
        Positioned.fill(
          child: Image.network(
            slide.image,
            fit: BoxFit.cover,
            // Add a subtle brightness filter like the CSS
            color: Colors.black.withOpacity(0.22),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        // 2. Gradient Overlay (from HeroCarousel.css)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0x00060E26), // rgba(6, 14, 38, .0)
                  const Color(0x59060E26), // rgba(6, 14, 38, .35)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.2, 0.85],
              ),
            ),
          ),
        ),
        // 3. Text and Buttons
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.headline,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          const Shadow(
                              blurRadius: 10, color: Colors.black54),
                        ],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  slide.sub,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        shadows: [
                          const Shadow(
                              blurRadius: 8, color: Colors.black45),
                        ],
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: widget.onBrowse,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent2, // Orange
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Browse Quests'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onPost,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Post a Quest'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper for nav arrows ---
  Widget _buildNavArrow(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF), // #ffffffd9
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black, size: 26),
        onPressed: onPressed,
      ),
    );
  }
}