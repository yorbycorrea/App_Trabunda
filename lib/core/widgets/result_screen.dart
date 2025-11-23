import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanner_trabunda/core/theme/app_colors.dart';
import 'package:scanner_trabunda/core/utils/worker_directory.dart';

class ResultScreen extends StatelessWidget {
  final String code;
  final Function() closeScreen;
  final WorkerRecord? worker;
  const ResultScreen({
    super.key,
    required this.closeScreen,
    required this.code,
    this.worker,
  });

  void abrirEnlace(String url) async {
    if (!url.startsWith("http")) {
      url = "https://" + url;
    }

    Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("No se pudo abrir el enlace: $url");
    }
  }

  List<Widget> _buildWorkerDetails() {
    final data = worker;
    if (data == null) return const [];

    final widgets = <Widget>[];

    if (data.name.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        Text(
          data.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }

    final extra = [
      for (final entry in data.extraFields)
        if (entry.value.trim().isNotEmpty) entry,
    ];

    if (extra.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(extra.map(
            (entry) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${entry.key}: ${entry.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        closeScreen();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.scannerBackground,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              closeScreen();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          ),
          centerTitle: true,
          title: const Text(
            "Scanner QR",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Vista del codigo QR
              QrImageView(data: code, size: 150, version: QrVersions.auto),

              const Text(
                "Resultado del escaneo",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
              ..._buildWorkerDetails(),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width - 100,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Fluttertoast.showToast(
                      msg: "Código copiado correctamente",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.green,
                      textColor: Colors.black87,
                      fontSize: 16,
                    );
                  },
                  child: const Text(
                    "Copiar",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width - 100,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => abrirEnlace(code),
                  child: const Text(
                    "Abrir Enlace",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
