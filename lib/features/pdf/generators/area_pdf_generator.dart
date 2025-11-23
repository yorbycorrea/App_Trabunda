import 'dart:typed_data';

abstract class AreaPdfGenerator {
  Future<Uint8List> build();
}
