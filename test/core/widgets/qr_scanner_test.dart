     import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeQrScanner extends StatelessWidget {
  const FakeQrScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Scan'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('shows Scan button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeQrScanner()));

    expect(find.text('Scan'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
