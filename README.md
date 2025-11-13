# scanner_trabunda

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
## Directorio de trabajadores para el escáner QR

Para que el escáner pueda completar automáticamente los datos de cada
trabajador (código, nombre y otros campos opcionales) debes proporcionar un
archivo JSON con tu base de datos:

1. Exporta tu archivo de Excel a un formato tabular (CSV) y luego conviértelo a
   JSON. Cada registro debe ser un objeto con, al menos, las llaves `code` (o
   `codigo`) y `name` (o `nombre`).
2. Copia el archivo generado en `assets/data/workers.json`. El repositorio trae
   un ejemplo con dos registros que puedes reemplazar.
3. Si la aplicación ya estaba abierta, ejecuta `flutter pub get` o vuelve a
   compilarla para que Flutter recargue los assets.

Ejemplo del formato esperado:

```json
[
  {"code": "EMP001", "name": "Ana Pérez", "document": "12345678"},
  {"code": "EMP002", "name": "Luis Gómez", "area": "Lavado Filete"}
]
```

Puedes agregar cualquier otro dato personalizado; aparecerá en la pantalla de
resultado del escaneo y se devuelve al flujo de cuadrillas para que se rellene
automáticamente el integrante correspondiente.