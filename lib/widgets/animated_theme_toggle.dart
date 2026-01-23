// lib/widgets/animated_theme_toggle.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

/// Animated theme toggle widget with smooth transitions
/// Similar to modern night mode switches with icon animations
class AnimatedThemeToggle extends StatefulWidget {
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedThemeToggle({
    super.key,
    this.size = 48,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 0.7,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Set initial state based on current theme
    final themeService = Provider.of<ThemeService>(context, listen: false);
    if (themeService.isDarkMode) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onToggle(bool isDark) {
    if (isDark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    // Update animation when theme changes externally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDark && _controller.value < 1.0) {
        _controller.forward();
      } else if (!isDark && _controller.value > 0.0) {
        _controller.reverse();
      }
    });

    return GestureDetector(
      onTap: () {
        themeService.toggleTheme();
        _onToggle(!isDark);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.indigo.shade700, Colors.purple.shade700]
                    : [Colors.orange.shade300, Colors.yellow.shade300],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.indigo : Colors.orange).withOpacity(
                    0.4,
                  ),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background stars/moon for dark mode
                if (isDark)
                  ...List.generate(3, (index) {
                    return Positioned(
                      left: 10 + (index * 8),
                      top: 8 + (index % 2) * 6,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          Icons.star,
                          size: 6 - (index * 1),
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    );
                  }),

                // Sun/Moon icon with rotation
                Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny,
                      color: Colors.white,
                      size: widget.size * 0.5,
                    ),
                  ),
                ),

                // Smooth transition overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
