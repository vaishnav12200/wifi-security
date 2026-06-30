import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';
import 'package:cybershield_wifi/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;

  int _bootStep = 0;
  final List<String> _bootMessages = [
    'Initializing security modules...',
    'Loading threat engine...',
    'Calibrating heuristic algorithms...',
    'Scanning wireless adapters...',
    'CyberShield is ready.',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _cycleBootMessages();
    _navigateAfterDelay();
  }

  void _cycleBootMessages() {
    Timer.periodic(const Duration(milliseconds: 560), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_bootStep < _bootMessages.length - 1) {
          _bootStep++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Shield Logo
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyberCyan.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppTheme.cyberCyan.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyberCyan.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppTheme.cyberCyan,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // App Name
              Text(
                'CYBERSHIELD',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'WiFi SECURITY ANALYZER',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.cyberCyan,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 48),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            minHeight: 3,
                            backgroundColor:
                                AppTheme.cyberCyan.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.cyberCyan),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _bootMessages[_bootStep],
                        key: ValueKey(_bootStep),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // Version tag
              Text(
                'v1.0.0  •  Defensive Mode',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
