import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Representa un trabajador dentro del directorio local.
class WorkerRecord {
  WorkerRecord({
    required this.code,
    required this.name,
    required Map<String, dynamic> raw,
  }) : raw = Map.unmodifiable(raw);

  /// Código único del trabajador (ID usado en los códigos QR/códigos de barras).
  final String code;

  /// Nombre del trabajador.
  final String name;

  /// Datos crudos provenientes del archivo JSON.
  final Map<String, dynamic> raw;

  /// Campos adicionales distintos a [code] y [name].
  Iterable<MapEntry<String, String>> get extraFields sync* {
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final lower = key.toLowerCase();
      if (lower == 'code' || lower == 'codigo' || lower == 'name' || lower == 'nombre') {
        continue;
      }
      yield MapEntry(key, entry.value?.toString() ?? '');
    }
  }
}

/// Carga un directorio de trabajadores desde un archivo en `assets/data/workers.json`.
class WorkerDirectory {
  WorkerDirectory._(this._byCode);

  final Map<String, WorkerRecord> _byCode;

  static WorkerDirectory? _cache;

  /// Carga el directorio en memoria si todavía no se inicializó.
  static Future<WorkerDirectory> _ensureLoaded() async {
    if (_cache != null) return _cache!;

    try {
      final raw = await rootBundle.loadString('assets/data/workers.json');
      final decoded = jsonDecode(raw);
      final map = <String, WorkerRecord>{};

      void addRecord(Map<String, dynamic> source) {
        final data = Map<String, dynamic>.from(source);

        final rawCodeValue = data['code'] ?? data['codigo'] ?? '';
        final normalized = _normalize(rawCodeValue);
        if (normalized.isEmpty) return;

        final nameValue = data['name'] ?? data['nombre'] ?? '';
        final name = nameValue.toString().trim();

        map[normalized] = WorkerRecord(
          code: rawCodeValue.toString().trim(),
          name: name,
          raw: data,
        );
      }

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            addRecord(item);
          } else if (item is Map) {
            addRecord(item.map((key, value) => MapEntry(key.toString(), value)));
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        decoded.forEach((_, value) {
          if (value is Map<String, dynamic>) {
            addRecord(value);
          } else if (value is Map) {
            addRecord(value.map((key, val) => MapEntry(key.toString(), val)));
          }
        });
      } else if (decoded is Map) {
        decoded.forEach((_, value) {
          if (value is Map) {
            addRecord(value.map((key, val) => MapEntry(key.toString(), val)));
          }
        });
      }

      _cache = WorkerDirectory._(map);
    } catch (error, stack) {
      debugPrint('No se pudo cargar workers.json: $error');
      debugPrint('$stack');
      _cache = WorkerDirectory._({});
    }

    return _cache!;
  }

  /// Garantiza que el archivo esté cargado en memoria (útil para precarga).
  static Future<void> preload() async {
    await _ensureLoaded();
  }

  /// Busca un trabajador por código. Regresa `null` si no existe.
  static Future<WorkerRecord?> findByCode(String code) async {
    final normalized = _normalize(code);
    if (normalized.isEmpty) return null;

    final directory = await _ensureLoaded();
    return directory._byCode[normalized];
  }

  static String _normalize(Object? value) {
    return value?.toString().trim().toUpperCase() ?? '';
  }
}