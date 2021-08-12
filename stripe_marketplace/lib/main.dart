import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stripe_marketplace/stripe/list_of_users.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ListOfUsersPage());
}
