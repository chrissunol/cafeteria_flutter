# FlowStock — Rediseño UI profesional

Este paquete conserva la lógica, modelos, provider y base de datos existentes. Se reemplazó la capa visual.

## Cambios principales

- Nueva identidad Graphite + Amber centralizada en `lib/ui/theme/app_theme.dart`.
- Componentes reutilizables en `lib/ui/widgets/app_ui.dart`.
- Dashboard con una jerarquía más clara y menos tarjetas compitiendo.
- Navegación inferior simplificada; se eliminó la curva exagerada.
- Catálogo con tarjetas propias, indicador visual de stock y menú de acciones.
- Formulario de productos convertido en bottom sheet.
- Entradas y cierres con selección visible y resúmenes dinámicos.
- Reportes y detalles de cierre completamente rediseñados.
- Splash screen más sobrio.
- Se eliminaron iconos de cafetería para que la app funcione como inventario general.

## Paleta

- Fondo: `#F4F5F7`
- Superficie: `#FFFFFF`
- Grafito: `#17181C`
- Ámbar: `#F4B740`
- Texto secundario: `#737781`
- Bordes: `#E6E8EC`
- Éxito: `#199A63`
- Error: `#D84B4B`

## Instalación

Reemplaza tu carpeta `lib` por la incluida en el ZIP. Conserva tus carpetas `assets`, `android`, `ios` y tu `pubspec.yaml` corregido.

Ejecuta:

```bash
flutter clean
flutter pub get
flutter run
```
