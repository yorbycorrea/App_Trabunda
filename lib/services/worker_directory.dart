import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

String _stripDiacritics(String input) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'Á': 'A',
    'À': 'A',
    'Ä': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Å': 'A',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'É': 'E',
    'È': 'E',
    'Ë': 'E',
    'Ê': 'E',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'Í': 'I',
    'Ì': 'I',
    'Ï': 'I',
    'Î': 'I',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'Ó': 'O',
    'Ò': 'O',
    'Ö': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'Ú': 'U',
    'Ù': 'U',
    'Ü': 'U',
    'Û': 'U',
    'ñ': 'n',
    'Ñ': 'N',
    'ç': 'c',
    'Ç': 'C',
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

String _normalizeValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  return _stripDiacritics(text).toUpperCase();
}

String _normalizeKey(Object? key) {
  final text = key?.toString() ?? '';
  if (text.isEmpty) return '';
  return _stripDiacritics(text)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .trim();
}

const List<String> _primaryCodeKeys = [
  'code',
  'codigo',
  'cod',
  'codigotrabajador',
  'trabajadorcodigo',
  'workerid',
  'employeeid',
  'empleadoid',
];

const List<String> _secondaryCodeKeys = [
  'dni',
  'document',
  'documento',
  'doc',
  'cedula',
  'rut',
  'numerodocumento',
  'numdocumento',
  'nrodocumento',
  'nrodoc',
];

const List<String> _indexableKeys = [
  ..._primaryCodeKeys,
  ..._secondaryCodeKeys,
  'barcode',
  'codigobarras',
  'codigodebarras',
  'qr',
  'qrcode',
  'codigoqr',
  'qrtext',
];

const List<String> _nameKeys = [
  'name',
  'nombre',
  'fullname',
  'nombrecompleto',
  'trabajador',
];

const Set<String> _knownFieldKeys = {
  ..._indexableKeys,
  ..._nameKeys,
};

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
      final normalizedKey = _normalizeKey(key);
      if (_knownFieldKeys.contains(normalizedKey)) {
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

        final normalizedData = <String, dynamic>{};
        for (final entry in data.entries) {
          final normalizedKey = _normalizeKey(entry.key);
          if (normalizedKey.isEmpty) continue;
          normalizedData[normalizedKey] = entry.value;
        }

        String? _firstMatching(List<String> keys) {
          for (final key in keys) {
            final value = normalizedData[key];
            if (value == null) continue;
            final text = value.toString().trim();
            if (text.isNotEmpty) return text;
          }
          return null;
        }

        final preferredCode = _firstMatching(_primaryCodeKeys);
        final fallbackCode = _firstMatching(_secondaryCodeKeys);
        final displayCode = (preferredCode ?? fallbackCode ?? '').trim();
        if (displayCode.isEmpty) {
          return;
        }

        var name = _firstMatching(_nameKeys) ?? '';
        if (name.isEmpty) {
          final nombres = normalizedData['nombres']?.toString().trim() ?? '';
          final apellidos = normalizedData['apellidos']?.toString().trim() ?? '';
          final apellido = apellidos.isNotEmpty
              ? apellidos
              : [
            normalizedData['apellidopaterno']?.toString().trim() ?? '',
            normalizedData['apellidomaterno']?.toString().trim() ?? '',
            normalizedData['apellido']?.toString().trim() ?? '',
            normalizedData['primerapellido']?.toString().trim() ?? '',
            normalizedData['segundoapellido']?.toString().trim() ?? '',
          ].where((value) => value.isNotEmpty).join(' ').trim();

          final parts = <String>[
            if (nombres.isNotEmpty) nombres,
            if (apellido.isNotEmpty) apellido,
          ];
          name = parts.join(' ').trim();
        }

        final record = WorkerRecord(
          code: preferredCode?.trim().isNotEmpty == true ? preferredCode!.trim() : displayCode,
          name: name,
          raw: data,
        );

        final aliases = <String>{displayCode};
        for (final entry in normalizedData.entries) {
          if (_indexableKeys.contains(entry.key)) {
            final value = entry.value;
            if (value == null) continue;
            final text = value.toString().trim();
            if (text.isNotEmpty) {
              aliases.add(text);
            }
          }
        }

        for (final alias in aliases) {
          final normalized = _normalizeValue(alias);
          if (normalized.isEmpty) continue;
          map[normalized] = record;
        }
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
    return _normalizeValue(value);
  }
}