import 'package:flutter/material.dart';
import '../Login/sign_in.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/public/get_started_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.63),
                  ],
                  stops: const [0.4, 0.95],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 37.5),
                  child: Text(
                    'You want Authentic Products, here you go!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.34,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 37.5),
                  child: Text(
                    'Find it here, buy it now!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      height: 1.54,
                      letterSpacing: 0.14,
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const SignIn(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 0.05);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          final offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 55.0),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF83758),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
