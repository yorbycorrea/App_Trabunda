# Resumen de archivos modificados

El commit `Add support for area and cuadrilla schedules and category breakdowns` introdujo cambios manuales en varios archivos del proyecto además de actualizar el archivo generado de Drift. A continuación se listan todos los archivos que debes revisar o copiar en tu entorno si estás replicando el trabajo:

- `lib/data/app_database.dart`: nuevas columnas para horarios de áreas, tablas auxiliares para desgloses por categoría y actualizaciones en los DAOs correspondientes.
- `lib/pages/area_detalle_page.dart`: captura y guardado de horarios por área, totales por categoría y propagación de los nuevos datos al flujo de guardado.
- `lib/pages/cuadrilla_config_page.dart`: formulario extendido para registrar horarios de cuadrilla, integrantes y el desglose por categoría.
- `lib/pages/report_create_page.dart`: pasa los nuevos parámetros al crear un área.
- `lib/pages/report_detail_page.dart`: muestra los horarios y desgloses registrados para cada área y sus cuadrillas.
- `lib/data/app_database.g.dart`: archivo generado por Drift que refleja el nuevo esquema y los mapeos de datos.

## Cómo obtener el contenido completo

1. Sitúate en la raíz del proyecto y asegúrate de estar en la rama que contiene el commit mencionado.
2. Para revisar cualquier archivo fuente manual (todos excepto `app_database.g.dart`), puedes abrirlo directamente desde `lib/` con tu editor o ejecutar:
   ```bash
   git show HEAD:lib/pages/area_detalle_page.dart
   git show HEAD:lib/pages/cuadrilla_config_page.dart
   git show HEAD:lib/pages/report_detail_page.dart
   git show HEAD:lib/pages/report_create_page.dart
   git show HEAD:lib/data/app_database.dart
   ```
   Sustituye `HEAD` por el identificador del commit si lo necesitas en otra rama.
3. Para regenerar `lib/data/app_database.g.dart` en tu entorno, ejecuta:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   Esto recreará el archivo generado con exactamente el mismo contenido que se encuentra en este repositorio.

Con estos pasos tendrás a la mano todas las piezas modificadas en el cambio anterior, no solo el archivo generado.
