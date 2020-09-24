import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foodapp/scr/helpers/user.dart';
import 'package:flutter_foodapp/scr/models/user.dart';

enum Status { Uninitialized, Unauthenticated, Authenticating, Authenticated }

class AuthProvider with ChangeNotifier {
  FirebaseAuth _auth;
  FirebaseUser _user;
  Status _status = Status.Uninitialized;
  UserServices _userServices = UserServices();
  UserModel _userModel;

  //getters

  Status get status => _status;
  FirebaseUser get user => _user;
  UserModel get userModel => _userModel;

  final formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  AuthProvider.initalize() : _auth = FirebaseAuth.instance {
    _auth.onAuthStateChanged.listen(_onStateChanged);
  }

  Future<bool> signIn() async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(
          email: email.text, password: password.text);
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      print("Error: " + e.toString());
    }
  }

  Future<bool> signUp() async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth
          .createUserWithEmailAndPassword(
              email: email.text, password: password.text)
          .then((user) {
        Map<String, dynamic> values = {
          "name": username.text,
          "email": email.text,
          "id": user.user.uid,
        };

        _userServices.createUser(values);
      });
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      print(e.toString());
      return false;
    }
  }

  Future<void> signOut() {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
  }

  void CleanControllers() {
    email.text = "";
    password.text = "";
    username.text = "";
  }

  Future<void> _onStateChanged(FirebaseUser firebaseUser) async {
    if (user == null) {
      _status = Status.Uninitialized;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;

      _userModel = await _userServices.getUserbyId(firebaseUser.uid);
    }
    notifyListeners();
  }
}
