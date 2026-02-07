import 'dart:io';
import 'user_model.dart';

void main() {
  List<User> database = [];

  print('--- SYSTEM ONLINE ---');

  while (true) {
    print('\nChoose action:');
    print('1. Register (New User)');
    print('2. Login (Existing User)');
    print('3. Exit');
    stdout.write('> ');

    String? choice = stdin.readLineSync();

    if (choice == '1') {
      // --- Registration Logic ---
    } else if (choice == '2') {
      // --- Login Logic ---
    } else if (choice == '3') {
      // --- Exit ---
      print('--- SYSTEM OFFLINE ---');
      break;
    } else {
      print('Invalid choice. Please try again.');
    }
  }
}