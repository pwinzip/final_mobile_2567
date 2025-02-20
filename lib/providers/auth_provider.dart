import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  MyAuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // ฟังก์ชันสมัครสมาชิก
  Future<String?> registerUser(String username, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: "$username@naphatapp.com",
        password: password,
      );
      return null; // ไม่มี error แปลว่าสำเร็จ
    } catch (e) {
      return e.toString();
    }
  }

  // ฟังก์ชันล็อกอิน
  Future<String?> loginUser(String username, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: "$username@naphatapp.com",
        password: password,
      );
      return null; // ไม่มี error แปลว่าสำเร็จ
    } catch (e) {
      return e.toString();
    }
  }

  // ฟังก์ชันล็อกเอาต์
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
