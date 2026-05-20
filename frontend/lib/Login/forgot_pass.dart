import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forgot\npassword?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  height: 1.19,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  hintText: 'Enter your email address',
                  hintStyle: const TextStyle(
                    color: Color(0xFF676767),
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF676767)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '* ',
                      style: TextStyle(
                        color: Color(0xFFFF4B26),
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: 'We will send you a message to set or reset your new password',
                      style: TextStyle(
                        color: Color(0xFF676767),
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isLoading ? null : _resetPassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: ShapeDecoration(
                    color: _isLoading ? Colors.grey : const Color(0xFFF73658),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : const Text(
                          'Submit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}