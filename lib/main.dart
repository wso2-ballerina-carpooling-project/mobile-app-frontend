import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// A placeholder widget for MyRoutePage
class MyRoutePage extends StatelessWidget {
  const MyRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route Page'),
      ),
      body: const Center(
        child: Text('Welcome to My Route Page!'),
      ),
    );
  }
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Route App',
      debugShowCheckedModeBanner: false, // Hides debug banner
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto', // Optional: Set your font
      ),
      home: const MyRoutePage(), // Set our custom UI as the home screen
    );
  }
}
