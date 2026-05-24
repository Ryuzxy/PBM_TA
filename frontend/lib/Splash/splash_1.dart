import 'package:flutter/material.dart';
import 'splash_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Buyer/dashboard/dashboard.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: Scaffold(body: ListView(children: [SplashScreen1()])),
    );
  }
}

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;
  late Animation<double> _animation4;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800), // Diperlama menjadi 1.8 detik per siklus
      vsync: this,
    )..repeat();

    final scaleSequence = [
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 50.0), // Skala NAIK
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 50.0), // Skala TURUN
    ];

    _animation1 = TweenSequence<double>(scaleSequence).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.00, 0.25, curve: Curves.easeInOut))
    );

    _animation2 = TweenSequence<double>(scaleSequence).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.50, curve: Curves.easeInOut))
    );

    _animation3 = TweenSequence<double>(scaleSequence).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.50, 0.75, curve: Curves.easeInOut))
    );

    _animation4 = TweenSequence<double>(scaleSequence).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.75, 1.00, curve: Curves.easeInOut))
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen2()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const Center(
              child: Text(
                'SmartDrop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF3B26B7),
                  fontSize: 40,
                  fontFamily: 'Libre Caslon Text',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(_animation1),
                const SizedBox(width: 6),
                _buildDot(_animation2),
                const SizedBox(width: 6),
                _buildDot(_animation3),
                const SizedBox(width: 6),
                _buildDot(_animation4),
              ],
            ),
            const Spacer(flex: 1),
            Container(
              width: 134,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: ShapeDecoration(
                color: const Color(0xFFA8A8A9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: animation.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: const ShapeDecoration(
                color: Color.fromARGB(255, 5, 0, 0),
                shape: OvalBorder(),
              ),
            ),
          ),
        );
      },
    );
  }
}
