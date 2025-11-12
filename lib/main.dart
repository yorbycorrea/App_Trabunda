import 'package:flutter/material.dart';
import 'pages/home_menu_page.dart';
import 'pages/reports_list_page.dart';
import 'pages/report_create_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(TrabundaApp(authService: AuthService()));
}

class TrabundaApp extends StatelessWidget {
  final AuthService authService;

  const TrabundaApp({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      service: authService,
      child: AnimatedBuilder(
        animation: authService,
        builder: (context, _) {
          return MaterialApp(
            title: 'TRABUNDA',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF0A7CFF),
            ),
            debugShowCheckedModeBanner: false,
            initialRoute: authService.currentUser == null ? '/login' : '/home',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginPage());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeMenuPage());
                case '/reports/list':
                  return MaterialPageRoute(
                    builder: (_) => const ReportsListPage(),
                  );
                case '/reports/create':
                  return MaterialPageRoute(
                    builder: (_) => ReportCreatePage(
                      planilleroInicial: authService.currentUser?.name,
                    ),
                  );
                default:
                  return MaterialPageRoute(builder: (_) => const LoginPage());
              }
            },
          );
        },
      ),
    );
  }
}
