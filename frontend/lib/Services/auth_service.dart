import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize the GoogleSignIn instance
      await _googleSignIn.initialize();

      // Trigger the Google Authentication flow
      final googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details (contains idToken)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Request authorization to obtain accessToken
      final auth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
        'openid',
      ]);

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: googleAuth.idToken,
      );



      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }
  }
}

