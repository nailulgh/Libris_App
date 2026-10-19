import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/libris_theme.dart';
import 'views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LibrisApp());
}

/// Aplikasi Utama Libris — Modern Book Discovery & Digital Literacy App
class LibrisApp extends StatelessWidget {
  const LibrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libris — Modern Book Discovery',
      debugShowCheckedModeBanner: false,
      theme: LibrisTheme.lightEditorialTheme,
      home: const HomePage(),
    );
  }
}
