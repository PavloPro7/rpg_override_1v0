import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(create: (context) => AppState(), child: const MyApp()),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pink,
        textTheme: GoogleFonts.robotoTextTheme(),
        brightness: Brightness.dark,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
