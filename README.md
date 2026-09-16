# FlowStock

FlowStock es una aplicación Flutter para controlar el inventario diario de una
cafetería. Permite gestionar productos, registrar entradas, realizar cierres de
existencias y consultar ventas y ganancias.

## Funciones principales

- Catálogo con costo, precio de venta, existencias y nivel mínimo.
- Entradas de mercancía con historial.
- Cierre diario mediante conteo físico.
- Reportes de ventas, unidades y ganancia.
- Alertas de inventario bajo.
- Exportación y restauración de copias de seguridad en formato JSON.
- Datos locales en SQLite; no requiere conexión a internet.

## Desarrollo

Requisitos:

- Flutter estable.
- Android Studio y un SDK de Android para compilar Android.
- Xcode en macOS para compilar iOS.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Datos y migraciones

La base de datos se almacena localmente como `cafeteria.db`. El esquema utiliza
migraciones versionadas para conservar los datos existentes al actualizar la
aplicación. Los productos eliminados se archivan para no romper su historial.

## Versiones de producción

Android requiere un identificador propio y una clave de firma de producción.
El flujo de GitHub Actions valida el código y genera un IPA de iOS sin firmar;
la firma final debe realizarse con una cuenta y certificados de Apple válidos.
