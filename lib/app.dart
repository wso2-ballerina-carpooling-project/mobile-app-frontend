import 'package:flutter/material.dart';
import 'views/loading_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      home: LoadingPage(), // Start with the loading screen
    );
  }
}
