import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg_override_1v0/firebase_options.dart';

void main() async {
  // 1. Initialize Firebase (The Engine)
  // Ensure you have widgets initialized if this is Flutter,
  // but for CLI we just start the app.
  // Note: For pure Dart CLI, ensure you are using a compatible setup.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;

  stdout.writeln('--- FIREBASE AUTH SYSTEM ---');

  while (true) {
    // Check if someone is already logged in
    User? currentUser = auth.currentUser;

    if (currentUser != null) {
      stdout.writeln('\n🟢 LOGGED IN AS: ${currentUser.email}');
      stdout.writeln('1. Add Task to Database');
      stdout.writeln('2. Logout');
    } else {
      stdout.writeln('\n🔴 NOT LOGGED IN');
      stdout.writeln('1. Register (New Account)');
      stdout.writeln('2. Login');
    }
    stdout.writeln('3. Exit');

    stdout.write('> ');
    String? choice = stdin.readLineSync();

    try {
      if (currentUser == null) {
        // --- GUEST MENU ---
        if (choice == '1') {
          // REGISTER
          stdout.write('Email: ');
          String email = stdin.readLineSync()!;
          stdout.write('Password (min 6 chars): ');
          String password = stdin.readLineSync()!;

          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          stdout.writeln('✅ Account Created!');
        } else if (choice == '2') {
          // LOGIN
          stdout.write('Email: ');
          String email = stdin.readLineSync()!;
          stdout.write('Password: ');
          String password = stdin.readLineSync()!;

          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          stdout.writeln('✅ Welcome back!');
        }
      } else {
        // --- USER MENU ---
        if (choice == '1') {
          // TEST DATABASE (This will fail if you are not logged in!)
          stdout.write('Enter Task Name: ');
          String taskName = stdin.readLineSync()!;

          await db.collection('tasks').add({
            'name': taskName,
            'owner_id': currentUser.uid, // Save WHO owns this task
            'created_at': DateTime.now().toIso8601String(),
          });
          stdout.writeln('💾 Saved to Database!');
        } else if (choice == '2') {
          await auth.signOut();
          stdout.writeln('👋 Signed out.');
        }
      }

      if (choice == '3') break;
    } catch (e) {
      stdout.writeln('❌ ERROR: $e');
    }
  }
}
