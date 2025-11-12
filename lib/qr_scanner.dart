import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'result_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  try {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return '${android.brand}-${android.model}'.replaceAll(' ', '_'); // ej: samsung-SM_A065M
  } catch (_) {
    return 'unknown_device';
  }
}

class AttendanceApi {
  static const _url   = 'https://script.google.com/macros/s/AKfycbz3scmQapwYJTQlcoaeaNejMxhqJg1HDZDoUUzCB-ZskQcNG56clU0xPnZN9nMTSkYMZQ/exec';
  static const _token = '12345';

  static Future<bool> send({
    required String employeeId,
    required String deviceId,
    required String status,
  }) async {
    final body = {
      'employee_id': employeeId,
      'device_id': deviceId,
      'status': status,
      'token': _token,
    };

    final resp = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('GAS status: ${resp.statusCode} body: ${resp.body}');
    if (resp.statusCode != 200) return false;

    final json = jsonDecode(resp.body);
    return json is Map && json['ok'] == true;
  }
}

const bgColor = Color(0xfffafafa);

class QrScanner extends StatefulWidget {
  final bool pickOnly; // ← NUEVO

  const QrScanner({super.key, this.pickOnly = false}); // ← NUEVO (default false)

  @override
  State<QrScanner> createState() => QRScannerState();
}
class QRScannerState extends State<QrScanner> {
  bool isScannCompleted = false;
  bool isFlashOn = false;
  bool isFrontCamera = false;

  // ✅ Usa un solo controller para todo
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  void closeScreen() {
    isScannCompleted = false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              setState(() => isFlashOn = !isFlashOn);
              await controller.toggleTorch();
            },
            icon: Icon(
              Icons.flashlight_on_rounded,
              color: isFlashOn ? Colors.green : Colors.grey,
            ),
          ),
          IconButton(
            onPressed: () async {
              setState(() => isFrontCamera = !isFrontCamera);
              await controller.switchCamera();
            },
            icon: Icon(
              Icons.camera_front_rounded,
              color: isFrontCamera ? Colors.green : Colors.grey,
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Scanner QR',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Por favor coloque el código QR en el área',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'El escaneo se iniciará automáticamente',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MobileScanner(
                      controller: controller, // ✅ mismo controller
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;

                        if (barcodes.isNotEmpty && !isScannCompleted) {
                          final code = barcodes.first.rawValue ?? '';
                          if (code.isEmpty) return;

                          setState(() => isScannCompleted = true);

                          final deviceId = await getDeviceId();

                          final ok = await AttendanceApi.send(
                            employeeId: code,
                            deviceId: deviceId,
                            status: 'PRESENTE',
                          );

                          if (!mounted) return;

                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo registrar la asistencia'),
                              ),
                            );
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(
                                code: code,
                                closeScreen: closeScreen,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment
                          .center, // ✅ valor correcto (no el tipo AlignmentGeometry)
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 44, 87, 230),
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Developed Trabunda  Version: 1.0.0', // ✅ primero el string
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
