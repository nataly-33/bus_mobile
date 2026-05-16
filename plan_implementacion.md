# Plan de Implementación — Sistema SIG Microbuses SCZ
> Proyecto desde cero · Flutter + ArcGIS Online · 2026

---

## STACK TECNOLÓGICO RECOMENDADO

| Capa | Herramienta | Por qué |
|------|------------|---------|
| Apps móviles | **Flutter** (Dart) | Una sola base de código → iOS y Android |
| Mapas en app | **ArcGIS Maps SDK for Flutter** (`arcgis_maps`) | Es lo que enseña tu ing (ArcGIS/Arcmap = ecosistema Esri) |
| Base de datos y servicios GIS | **ArcGIS Online** (cuenta gratuita) | Reemplaza al backend: maneja Feature Layers, GPS en tiempo real, rutas |
| Datos en tiempo real | **ArcGIS Feature Service** vía REST API | El conductor POST ubicación → la app usuario la lee |
| Datos de rutas | **ArcGIS Online Feature Layer** (geometrías LineString) | Rutas de líneas almacenadas como capas en la nube |
| Autenticación | **ArcGIS API Key** (para el proyecto) | Sencillo, gratuito en cuentas de desarrollo |

> **Nota importante sobre ArcGIS Online:** Con una cuenta gratuita de ArcGIS Developer (developers.arcgis.com) puedes alojar Feature Layers, hacer consultas espaciales y recibir datos en tiempo real — sin pagar ni instalar servidores. Es exactamente lo que tu ing probablemente espera que usen.

---

## ARQUITECTURA DEL SISTEMA

```
┌─────────────────────┐         ┌──────────────────────────┐
│   APP CONDUCTOR     │  POST   │                          │
│   (Flutter)         │────────►│   ArcGIS Online          │
│                     │  cada   │   Feature Services       │
│  - Login            │  30 seg │                          │
│  - GPS activo       │         │  ┌─────────────────────┐ │
│  - Envía posición   │         │  │ Layer: Posiciones   │ │
└─────────────────────┘         │  │ (puntos GPS activos)│ │
                                │  ├─────────────────────┤ │
┌─────────────────────┐  GET   │  │ Layer: Rutas        │ │
│   APP USUARIO       │◄───────│  │ (LineStrings líneas)│ │
│   (Flutter)         │         │  ├─────────────────────┤ │
│                     │         │  │ Table: Conductores  │ │
│  - Ver rutas        │         │  ├─────────────────────┤ │
│  - Ver micros       │         │  │ Table: Microbuses   │ │
│  - ¿Pasan aquí?     │         │  └─────────────────────┘ │
└─────────────────────┘         └──────────────────────────┘
```

---

## FASES DE IMPLEMENTACIÓN

---

### FASE 0 — Configuración inicial (Semana 1)

**Objetivo:** Tener el entorno listo antes de escribir una sola línea de app.

#### 0.1 Cuenta ArcGIS Developer (gratuita)
1. Ir a https://developers.arcgis.com → crear cuenta gratuita
2. Crear una **API Key** con permisos: `Feature layers (read/write)`, `Basemaps`
3. Guardar la API Key en un archivo `.env` (nunca en el código)

#### 0.2 Proyecto Flutter
```bash
flutter create microbuses_sig
cd microbuses_sig
```

Estructura de carpetas a usar:
```
lib/
├── app/
│   ├── conductor/          # Pantallas de la app conductor
│   ├── usuario/            # Pantallas de la app usuario
│   └── shared/             # Widgets, constantes, servicios comunes
├── services/
│   ├── arcgis_service.dart # Toda la comunicación con ArcGIS Online
│   └── location_service.dart
├── models/
│   ├── linea.dart
│   ├── conductor.dart
│   ├── microbus.dart
│   └── posicion_gps.dart
└── main.dart
```

#### 0.3 Dependencias en `pubspec.yaml`
```yaml
dependencies:
  arcgis_maps: ^200.6.0      # SDK de ArcGIS para Flutter
  geolocator: ^12.0.0        # GPS del dispositivo
  flutter_dotenv: ^5.0.0     # Variables de entorno (.env)
  shared_preferences: ^2.2.0 # Persistencia de sesión conductor
  image_picker: ^1.0.0       # Fotos conductor/microbús
  http: ^1.2.0               # Llamadas REST a ArcGIS
```

---

### FASE 1 — Datos geográficos en ArcGIS Online (Semana 1-2)

**Objetivo:** Tener las rutas de las líneas de microbús cargadas como Feature Layers.

> Esta es la parte más "SIG" del proyecto. ArcGIS Online reemplaza a PostGIS — tú creas Feature Layers directamente en el portal y los consumes desde Flutter.

#### 1.1 Crear el Feature Layer "Rutas de Líneas"

En ArcGIS Online (arcgis.com):
1. Ir a **Content → New Item → Feature Layer**
2. Definir el esquema:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `linea_id` | Integer | ID único de la línea |
| `nombre` | String(50) | Ej: "Línea 12", "Trufí 4" |
| `sentido` | String(10) | "ida" o "vuelta" |
| `color_hex` | String(7) | Color para mostrar en mapa |
| Geometría | **Polyline** | El recorrido trazado |

3. Tipo de geometría: **Polyline** (no Point ni Polygon)

#### 1.2 Cargar las rutas — Opción práctica para el proyecto

Como no tienes QGIS ni PostGIS, usa este flujo 100% dentro de ArcGIS:

**Opción A — ArcGIS Online Map Viewer (sin herramientas extra):**
1. Abrir el Map Viewer en arcgis.com
2. Ir a **Edit → Add Features**
3. Dibujar la ruta de cada línea siguiendo las calles de SCZ
4. Llenar los atributos (nombre, sentido)
5. Guardar

**Opción B — Importar GeoJSON (más rápido):**
1. Ir a https://geojson.io
2. El mapa ya muestra Santa Cruz de la Sierra si centras en `-17.783, -63.182`
3. Usar la herramienta de línea para trazar la ruta
4. Exportar como GeoJSON
5. En ArcGIS Online: **Content → New Item → Drag & drop el .geojson**

Mínimo necesario para que el proyecto funcione: **5 líneas, cada una con ida y vuelta.**

Coordenadas de referencia para centrar el mapa en SCZ:
```dart
// En tu app Flutter
final scz = ArcGISPoint(
  x: -63.1824,
  y: -17.7833,
  spatialReference: SpatialReference.wgs84,
);
```

#### 1.3 Crear el Feature Layer "Posiciones GPS"

Este layer recibe los datos en tiempo real del conductor.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `conductor_id` | Integer | FK al conductor |
| `microbus_placa` | String(10) | Identificador del micro |
| `linea_id` | Integer | Línea que está recorriendo |
| `sentido` | String(10) | "ida" / "vuelta" |
| `velocidad` | Double | km/h |
| `distancia` | Double | Metros recorridos |
| `tiempo_seg` | Integer | Segundos desde inicio |
| `activo` | Boolean | Si está en recorrido activo |
| `timestamp` | Date | Fecha y hora |
| Geometría | **Point** | Ubicación actual |

#### 1.4 Crear las tablas (sin geometría)

En ArcGIS Online también puedes crear tablas normales:
- **Tabla Conductores** (campos del alcance: CI, nombre, nacimiento, sexo, etc.)
- **Tabla Microbuses** (placa, modelo, asientos, conductor, línea, etc.)

---

### FASE 2 — Servicio de comunicación con ArcGIS (Semana 2)

**Objetivo:** Una clase Dart que encapsula todas las llamadas a ArcGIS Online REST API.

```dart
// lib/services/arcgis_service.dart

class ArcGISService {
  static const String _baseUrl = 'https://services.arcgis.com/TU_ORG_ID/arcgis/rest/services';
  static const String _apiKey = String.fromEnvironment('ARCGIS_API_KEY');

  // --- RUTAS ---
  
  // Obtener recorrido de una línea
  Future<List<ArcGISPoint>> getRutaLinea(int lineaId, String sentido) async {
    final url = '$_baseUrl/RutasLineas/FeatureServer/0/query'
        '?where=linea_id=$lineaId AND sentido=\'$sentido\''
        '&outFields=*&f=geojson&token=$_apiKey';
    // ... hacer GET y parsear geometría
  }

  // Líneas que pasan cerca de un punto
  Future<List<Map>> getLineasCercanas(double lat, double lng, double radioMetros) async {
    final url = '$_baseUrl/RutasLineas/FeatureServer/0/query'
        '?geometry={"x":$lng,"y":$lat}'
        '&geometryType=esriGeometryPoint'
        '&spatialRel=esriSpatialRelIntersects'   // ← consulta espacial ArcGIS
        '&distance=$radioMetros&units=esriSRUnit_Meter'
        '&outFields=linea_id,nombre&f=json&token=$_apiKey';
    // ...
  }

  // --- GPS EN TIEMPO REAL ---

  // Conductor envía su posición (cada 30 seg)
  Future<void> enviarPosicion({
    required int conductorId,
    required String placa,
    required int lineaId,
    required String sentido,
    required double lat,
    required double lng,
    required double velocidad,
    required double distancia,
    required int tiempoSeg,
  }) async {
    final url = '$_baseUrl/PosicionesGPS/FeatureServer/0/applyEdits';
    final body = {
      'adds': jsonEncode([{
        'geometry': {'x': lng, 'y': lat, 'spatialReference': {'wkid': 4326}},
        'attributes': {
          'conductor_id': conductorId,
          'microbus_placa': placa,
          'linea_id': lineaId,
          'sentido': sentido,
          'velocidad': velocidad,
          'distancia': distancia,
          'tiempo_seg': tiempoSeg,
          'activo': 1,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      }])
    };
    // POST con http
  }

  // Usuario consulta microbuses activos de una línea
  Future<List<Map>> getMicrobusesActivos(int lineaId) async {
    final url = '$_baseUrl/PosicionesGPS/FeatureServer/0/query'
        '?where=linea_id=$lineaId AND activo=1'
        '&outFields=*&f=geojson&token=$_apiKey';
    // ...
  }
}
```

---

### FASE 3 — App Conductor (Semana 2-3)

#### Pantallas a desarrollar:

**3.1 Login / Registro**
- Verificar si ya existe sesión guardada (`shared_preferences`)
- Si no hay sesión → formulario de registro con todos los campos del alcance
- Incluir `image_picker` para la foto
- Al guardar → POST a la tabla Conductores en ArcGIS Online
- Guardar `conductor_id` localmente para no registrarse de nuevo

**3.2 Registro de Microbús**
- Formulario con todos los campos del alcance
- Fotos con `image_picker`
- Asociar al conductor logueado

**3.3 Pantalla principal conductor**
```
┌──────────────────────────────┐
│  Bienvenido, [Nombre]        │
│  Microbús: [Placa]           │
│                              │
│  [Línea 12 ▾]  [Ida / Vuelta]│
│                              │
│  ┌──────────────────────┐    │
│  │  INICIAR RECORRIDO   │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────┐ ┌────────┐ │
│  │  TERMINAR    │ │ SALIR  │ │
│  │  RECORRIDO   │ │ RUTA   │ │
│  └──────────────┘ └────────┘ │
└──────────────────────────────┘
```

**3.4 Lógica del recorrido activo**
```dart
// Timer que dispara cada 30 segundos
Timer.periodic(const Duration(seconds: 30), (timer) async {
  final pos = await Geolocator.getCurrentPosition();
  await arcgisService.enviarPosicion(
    conductorId: session.conductorId,
    placa: session.placa,
    lineaId: lineaSeleccionada,
    sentido: sentidoSeleccionado,
    lat: pos.latitude,
    lng: pos.longitude,
    velocidad: pos.speed * 3.6, // m/s → km/h
    distancia: distanciaAcumulada,
    tiempoSeg: stopwatch.elapsed.inSeconds,
  );
});
```

**3.5 Terminar recorrido / Salir por fuerza mayor**
- Detener el Timer
- Marcar `activo = 0` en ArcGIS (UPDATE al feature)
- Para "salir": mostrar picker de motivo (avería, accidente, fin de turno, otro)

---

### FASE 4 — App Usuario (Semana 3-4)

#### Pantallas a desarrollar:

**4.1 Pantalla principal usuario — menú de opciones**
```
┌──────────────────────────────┐
│        MicroBus SCZ          │
│                              │
│  ┌──────────────────────┐    │
│  │ 🗺  Recorrido de      │    │
│  │     línea            │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │ 📍 ¿Qué líneas       │    │
│  │    pasan aquí?       │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │ 🚌 Esperando         │    │
│  │    microbús          │    │
│  └──────────────────────┘    │
└──────────────────────────────┘
```

**4.2 Funcionalidad: Recorrido de línea**

```dart
// Widget del mapa con ArcGIS SDK
ArcGISMapView(
  controllerProvider: () => ArcGISMapViewController()
    ..arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets),
)

// Al seleccionar una línea + sentido:
final puntos = await arcgisService.getRutaLinea(lineaId, sentido);
// Dibujar polyline en el mapa
final graphic = Graphic(
  geometry: Polyline(points: puntos),
  symbol: SimpleLineSymbol(color: Colors.blue, width: 3),
);
graphicsOverlay.graphics.add(graphic);

// Marcador verde (inicio)
final inicio = Graphic(
  geometry: puntos.first,
  symbol: SimpleMarkerSymbol(color: Colors.green, size: 12),
);
// Marcador rojo (fin)
final fin = Graphic(
  geometry: puntos.last,
  symbol: SimpleMarkerSymbol(color: Colors.red, size: 12),
);
```

**4.3 Funcionalidad: ¿Qué líneas pasan aquí?**
- Por defecto: usar GPS del dispositivo
- Opción: tocar el mapa para seleccionar un punto manualmente
- Llamar a `getLineasCercanas()` con radio configurable (ej. 200m)
- Mostrar lista de líneas resultantes
- Al seleccionar una → mostrar recorrido completo

**4.4 Funcionalidad: Esperando microbús**
- Actualizar posiciones cada 15 segundos con `Timer.periodic`
- Mostrar icono de microbús en cada posición activa
- Mostrar también el recorrido de la línea como referencia

```dart
// Íconos de microbús en el mapa
for (final micro in microbusesActivos) {
  graphicsOverlay.graphics.add(Graphic(
    geometry: ArcGISPoint(x: micro['lng'], y: micro['lat'],
      spatialReference: SpatialReference.wgs84),
    symbol: PictureMarkerSymbol.withUrl(
      Uri.parse('assets/icons/microbus.png'))
      ..width = 30 ..height = 30,
  ));
}
```

---

### FASE 5 — Integración y pruebas (Semana 4-5)

#### Checklist de integración:

- [ ] El conductor envía posición y aparece en la app del usuario (end-to-end)
- [ ] Las rutas dibujadas corresponden geográficamente a SCZ
- [ ] El marcador verde/rojo aparece en los extremos correctos
- [ ] El radio de búsqueda de "líneas que pasan aquí" funciona correctamente
- [ ] Al terminar recorrido, el microbús desaparece del mapa del usuario
- [ ] La sesión del conductor persiste al cerrar y reabrir la app
- [ ] El motivo de "salir del recorrido" se guarda correctamente

---

## DATOS PARA EL SEEDER — Sin QGIS ni herramientas extra

Como tu ing solo ha mostrado ArcGIS, el flujo más limpio es:

### Flujo recomendado para cargar datos reales de SCZ:

1. **Abrir Google Maps** en el navegador
2. Buscar una línea de micro conocida de SCZ (ej. "Línea 26 Santa Cruz")
3. Activar Street View o seguir la ruta visualmente
4. Anotar 10-15 puntos clave del recorrido (esquinas) como coordenadas lat/lng
   - Clic derecho en Google Maps → "¿Qué hay aquí?" → te muestra lat,lng
5. Ir a **https://geojson.io** y dibujar la ruta conectando esos puntos
6. Exportar como GeoJSON
7. Importar en ArcGIS Online

### Script de ejemplo para generar GeoJSON de una línea:

```python
# Puedes correr esto en Google Colab (gratuito, sin instalar nada)
import json

# Puntos de ejemplo para "Línea 26" SCZ (coordenadas reales del centro)
puntos_ida = [
    [-63.1940, -17.7937],  # Terminal bimodal
    [-63.1872, -17.7889],  # Av. Cañoto
    [-63.1812, -17.7844],  # Plaza 24 de Septiembre
    [-63.1754, -17.7801],  # Av. Monseñor Rivero
    [-63.1698, -17.7762],  # Punto final
]

geojson = {
    "type": "FeatureCollection",
    "features": [{
        "type": "Feature",
        "properties": {"linea_id": 26, "nombre": "Línea 26", "sentido": "ida"},
        "geometry": {"type": "LineString", "coordinates": puntos_ida}
    }]
}

with open('linea_26.geojson', 'w') as f:
    json.dump(geojson, f)
print("Archivo generado: linea_26.geojson")
```

> Repite esto para 4-5 líneas y tendrás suficientes datos para demostrar todas las funcionalidades.

---

## PREGUNTAS FRECUENTES

**¿Necesito servidor propio / backend?**
No. ArcGIS Online actúa como backend + base de datos espacial. El conductor hace POST directo al Feature Layer, y el usuario hace GET. No hay servidor intermedio.

**¿ArcGIS Online es gratis?**
La cuenta de desarrollador en developers.arcgis.com es gratuita con un límite generoso (suficiente para un proyecto académico). Si tu universidad tiene licencia de ArcGIS, úsala — tendrás más capacidad.

**¿Puedo usar Google Maps en vez de ArcGIS SDK?**
Técnicamente sí, pero si tu ing enseña ArcGIS, es mejor que el stack sea coherente con la materia.

**¿El proyecto necesita dos apps separadas?**
El alcance dice "dos aplicaciones". Pueden ser dos módulos dentro del mismo proyecto Flutter (un `main_conductor.dart` y un `main_usuario.dart`), o dos apps completamente distintas. Lo más práctico para el proyecto es un solo repo con dos entry points.

---

## ENTREGABLES ESPERADOS

| Entregable | Descripción |
|-----------|-------------|
| Repositorio Flutter | Código de ambas apps |
| Feature Layers en ArcGIS Online | Rutas, Posiciones GPS, Conductores, Microbuses |
| Script/instrucciones de datos | Cómo se cargaron las rutas |
| README con instrucciones | Cómo correr el proyecto (API Key, dependencias) |
| APK de prueba | Al menos una compilación funcional en Android |
