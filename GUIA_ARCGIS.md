# Guía: Configurar ArcGIS Online para el proyecto

> Completa estos pasos cuando tengas acceso a internet. No necesitas instalar nada extra.

---

## PASO 1 — Crear cuenta gratuita de desarrollador

1. Ve a **https://developers.arcgis.com**
2. Clic en **"Sign Up for Free"**
3. Completa el registro con tu email universitario
4. Confirma tu email

---

## PASO 2 — Crear una API Key

1. En el portal de desarrolladores, ve a **Dashboard → API Keys**
2. Clic en **"New API Key"**
3. Ponle nombre: `buses_sig_scz`
4. En permisos activa:
   - ✅ **Basemaps** (para los mapas de fondo)
   - ✅ **Feature Layer (read)** (para leer rutas y posiciones)
   - ✅ **Feature Layer (write)** (para enviar posiciones GPS)
5. Clic **"Save"** y copia la API Key generada

6. **Abre el archivo** `lib/services/arcgis_service.dart` y reemplaza:
   ```dart
   const String _apiKey = 'TU_API_KEY_AQUI';
   ```
   con tu API Key real.

---

## PASO 3 — Crear el Feature Layer "Rutas de Líneas"

1. Ve a **https://www.arcgis.com** e inicia sesión
2. Clic en **Content → New Item → Feature Layer (define your own)**
3. Elige tipo de geometría: **Polyline**
4. Agrega estos campos:

| Nombre campo | Tipo       | Longitud |
|-------------|------------|----------|
| `linea_id`  | Integer    | —        |
| `nombre`    | String     | 50       |
| `sentido`   | String     | 10       |
| `color_hex` | String     | 7        |

5. Nombre del layer: `RutasLineas`
6. Clic **"Save"** y anota la **URL del servicio** (la necesitas en el paso 6)

### Cargar las rutas de SCZ

**Opción más rápida — geojson.io:**
1. Ve a https://geojson.io
2. En el buscador escribe: `Santa Cruz de la Sierra, Bolivia`
3. Con la herramienta de línea (icono del polígono) traza el recorrido de 5 líneas
4. Para cada línea, en el panel derecho agrega los atributos:
   ```json
   { "linea_id": 12, "nombre": "Línea 12", "sentido": "ida", "color_hex": "#1565C0" }
   ```
5. Exporta como **GeoJSON**
6. En ArcGIS Online: **Content → New Item → arrastra el .geojson** → importa

**Líneas sugeridas para el proyecto:**
- Línea 12 (color `#1565C0`)
- Línea 20 (color `#2E7D32`)
- Línea 26 (color `#C62828`)
- Trufí 4 (color `#E65100`)
- Línea 33 (color `#6A1B9A`)

---

## PASO 4 — Crear el Feature Layer "Posiciones GPS"

1. En ArcGIS Online: **Content → New Item → Feature Layer (define your own)**
2. Tipo de geometría: **Point**
3. Campos:

| Nombre         | Tipo    | Longitud |
|---------------|---------|----------|
| `conductor_id` | Integer | —        |
| `microbus_placa`| String | 10       |
| `linea_id`    | Integer | —        |
| `sentido`     | String  | 10       |
| `velocidad`   | Double  | —        |
| `distancia`   | Double  | —        |
| `tiempo_seg`  | Integer | —        |
| `activo`      | Integer | —        |
| `timestamp`   | Date    | —        |

4. Nombre del layer: `PosicionesGPS`
5. Anota la URL del servicio

---

## PASO 5 — Crear las tablas (sin geometría)

### Tabla Conductores
En ArcGIS Online: **Content → New Item → Feature Layer (Table)**

| Campo             | Tipo    | Longitud |
|------------------|---------|----------|
| `nombre`         | String  | 50       |
| `apellido`       | String  | 50       |
| `ci`             | String  | 15       |
| `telefono`       | String  | 15       |
| `sexo`           | String  | 1        |
| `fecha_nacimiento`| String | 10       |
| `foto_url`       | String  | 500      |

Nombre: `Conductores`

### Tabla Microbuses
| Campo         | Tipo    | Longitud |
|--------------|---------|----------|
| `placa`      | String  | 10       |
| `modelo`     | String  | 50       |
| `color`      | String  | 30       |
| `anio`       | Integer | —        |
| `num_asientos`| Integer| —        |
| `conductor_id`| Integer| —        |
| `linea_id`   | Integer | —        |
| `foto_url`   | String  | 500      |

Nombre: `Microbuses`

---

## PASO 6 — Actualizar las URLs en el código

Abre `lib/services/arcgis_service.dart` y actualiza:

```dart
// Cambia TU_ORG_ID por el ID de tu organización ArcGIS
// Lo encuentras en la URL cuando estás en tu portal:
// https://www.arcgis.com/home/user.html → anota el "username"
static const String _baseUrl =
    'https://services.arcgis.com/TU_ORG_ID/arcgis/rest/services';
```

También:
```dart
// Cambia false a true para usar datos reales
const bool _useMock = false;  // ← CAMBIAR ESTO
```

---

## PASO 7 — Activar el SDK de ArcGIS (mapa real)

Cuando tengas la API Key y los Feature Layers listos:

1. En `pubspec.yaml`, descomenta:
   ```yaml
   arcgis_maps: ^200.6.0
   ```

2. Sigue la guía oficial de setup nativo:
   https://developers.arcgis.com/flutter/install-and-set-up/

3. El setup nativo requiere:
   - **Android**: agregar el repositorio Maven de Esri en `android/build.gradle`
   - **iOS**: no requiere cambios extra

4. En `lib/services/arcgis_service.dart` ya están los comentarios `// TODO:` que marcan exactamente dónde poner el código real de ArcGIS SDK.

---

## Resumen de lo que debes hacer tú

| # | Tarea | Dónde |
|---|-------|-------|
| 1 | Crear cuenta en developers.arcgis.com | Web |
| 2 | Generar API Key con permisos correctos | Portal ArcGIS |
| 3 | Crear Feature Layer "RutasLineas" (Polyline) | ArcGIS Online |
| 4 | Dibujar 5 líneas de SCZ en geojson.io e importarlas | geojson.io + ArcGIS |
| 5 | Crear Feature Layer "PosicionesGPS" (Point) | ArcGIS Online |
| 6 | Crear tablas Conductores y Microbuses | ArcGIS Online |
| 7 | Copiar URLs de los servicios al código | `arcgis_service.dart` |
| 8 | Cambiar `_useMock = false` | `arcgis_service.dart` |
| 9 | (Opcional) Descomentar `arcgis_maps` para mapa real | `pubspec.yaml` |

---

> El APK actual (`build/app/outputs/flutter-apk/app-debug.apk`) ya funciona con datos de prueba
> (mock). Puedes instalarlo en un Android para ver todas las pantallas ahora mismo.
