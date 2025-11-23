import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class AuthController {
  AuthController(this.userName);
  final String userName;
}

abstract class ReportesService {
  Future<List<String>> fetchReports();
}

class MockReportesService extends Mock implements ReportesService {}

class ReportsListPage extends StatelessWidget {
  const ReportsListPage({super.key, required this.authController, required this.reportesService});

  final AuthController authController;
  final ReportesService reportesService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: reportesService.fetchReports(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(title: const Text('Reportes')),
          body: Column(
            children: [
              Text('Planillero: ${authController.userName}'),
              if (snapshot.hasData)
                ...snapshot.data!.map((report) => Text(report)),
              if (snapshot.connectionState == ConnectionState.waiting)
                const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  group('ReportsListPage', () {
    late AuthController authController;
    late MockReportesService reportesService;

    setUp(() {
      authController = AuthController('María Planillero');
      reportesService = MockReportesService();
    });

    testWidgets('renders planillero name', (tester) async {
      when(() => reportesService.fetchReports())
          .thenAnswer((_) async => ['Reporte A']);

      await tester.pumpWidget(MaterialApp(
        home: ReportsListPage(
          authController: authController,
          reportesService: reportesService,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Planillero: María Planillero'), findsOneWidget);
      expect(find.text('Reporte A'), findsOneWidget);
    });
  });
}
