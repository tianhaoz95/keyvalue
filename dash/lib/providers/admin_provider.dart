import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback_item.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAuthReady = false;
  bool get isAuthReady => _isAuthReady;

  AdminProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    debugPrint('AdminProvider: Initializing auth state listener...');
    _auth.authStateChanges().listen((user) async {
      debugPrint('AdminProvider: Auth state changed. User: ${user?.email ?? "Null"}');
      _user = user;
      _isAuthReady = true;
      
      if (user == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('rememberMe');
        } catch (e) {
          debugPrint('AdminProvider: Error clearing prefs: $e');
        }
      }
      
      notifyListeners();
    }, onError: (e) {
      debugPrint('AdminProvider: Auth state stream error: $e');
      _isAuthReady = true;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _db.collection('feedbacks').doc(feedbackId).delete();
  }

  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    await _db.collection('feedbacks').doc(feedbackId).update({
      'status': status,
    });
  }

  Future<String?> getEmailByUid(String uid) async {
    final doc = await _db.collection('advisors').doc(uid).get();
    return doc.data()?['email'] as String?;
  }

  Stream<List<FeedbackItem>> getFeedbacks() {
    return _db
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FeedbackItem.fromFirestore(doc)).toList());
  }
}
