import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/widgets/qr_scanner.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_use_case.dart';
import 'features/auth/domain/usecases/logout_use_case.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/reports/presentation/pages/home_menu_page.dart';
import 'features/reports/presentation/pages/report_create_page.dart';
import 'features/reports/presentation/pages/reports_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =====================================================
  // 🔥 INICIALIZACIÓN DE SUPABASE
  // =====================================================
  await Supabase.initialize(
    url: 'https://jufkbwrspbzgmaadeckm.supabase.co',
    anonKey: 'sb_publishable_SgAf13M6G3motP2gRTpuQA_sTUjzxcB',
  );
  // =====================================================

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(Supabase.instance.client),
  );

  final authController = AuthController(
    repository: authRepository,
    loginUseCase: LoginUseCase(authRepository),
    logoutUseCase: LogoutUseCase(authRepository),
  );

  runApp(TrabundaApp(authController: authController));
}

class TrabundaApp extends StatelessWidget {
  final AuthController authController;

  const TrabundaApp({
    super.key,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: authController,
      child: AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          return MaterialApp(
            title: 'TRABUNDA',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF0A7CFF),
            ),
            debugShowCheckedModeBanner: false,
            initialRoute:
                authController.currentUser == null ? '/login' : '/home',
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
                      planilleroInicial: authController.currentUser?.name,
                    ),
                  );

                case '/scanner':
                  bool pickOnly = false;
                  final args = settings.arguments;
                  if (args is bool) {
                    pickOnly = args;
                  } else if (args is Map) {
                    final pick = args['pickOnly'];
                    if (pick is bool) pickOnly = pick;
                  }

                  return MaterialPageRoute(
                    builder: (_) => QrScanner(pickOnly: pickOnly),
                    settings: settings,
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
