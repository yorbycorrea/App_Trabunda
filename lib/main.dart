import 'package:flutter/material.dart';
import 'pages/home_menu_page.dart';
import 'pages/reports_list_page.dart';
import 'pages/report_create_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const TrabundaApp());
}

class TrabundaApp extends StatelessWidget {
  const TrabundaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRABUNDA',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A7CFF),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',            // 👈 comienza en Login
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomeMenuPage(),
        '/reports/list': (_) => const ReportsListPage(),
        '/reports/create': (_) => const ReportCreatePage(),
      },
    );
  }
}
