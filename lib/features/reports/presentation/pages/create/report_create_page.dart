import 'package:flutter/material.dart';

import 'package:scanner_trabunda/features/auth/presentation/controllers/auth_controller.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/create/report_create_planillero_page.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/create/report_create_saneamiento_page.dart';

class ReportCreatePage extends StatelessWidget {
  const ReportCreatePage({
    super.key,
    this.planilleroInicial,
  });

  final String? planilleroInicial;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.watch(context).currentUser;
    final esSaneamiento =
        (user?.role ?? '').toLowerCase().trim() == 'saneamiento';

    if (esSaneamiento) {
      return ReportCreateSaneamientoPage(
        planilleroInicial: planilleroInicial,
      );
    }

    return ReportCreatePlanilleroPage(
      planilleroInicial: planilleroInicial,
    );
  }
}
