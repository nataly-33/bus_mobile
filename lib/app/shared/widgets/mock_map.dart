import 'package:flutter/material.dart';

class MockBusMarker {
  final String label;
  final double relX;
  final double relY;
  final Color color;
  const MockBusMarker({
    required this.label,
    required this.relX,
    required this.relY,
    this.color = const Color(0xFFFF8F00),
  });
}

class MockRouteOverlay {
  final Color color;
  final String nombre;
  const MockRouteOverlay({required this.color, required this.nombre});
}

class MockMapWidget extends StatelessWidget {
  final List<MockBusMarker> busMarkers;
  final List<MockRouteOverlay> routes;
  final bool showUserPin;
  final bool showConnectBanner;

  const MockMapWidget({
    super.key,
    this.busMarkers = const [],
    this.routes = const [],
    this.showUserPin = false,
    this.showConnectBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _StreetGridPainter())),
        ...routes.map(
          (r) => Positioned.fill(
            child: CustomPaint(painter: _RoutePainter(color: r.color)),
          ),
        ),
        ...busMarkers.map((m) => _BusMarkerWidget(marker: m)),
        if (showUserPin)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: Colors.red, size: 44),
                SizedBox(height: 2),
                Text(
                  'Tu ubicación',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    backgroundColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        if (showConnectBanner)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Mapa real disponible tras configurar ArcGIS API Key',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StreetGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EAF0),
    );

    final blockPaint = Paint()..color = const Color(0xFFD5DAE8);
    const cols = 6;
    const rows = 8;
    final bw = size.width / cols;
    final bh = size.height / rows;
    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * bw + 4, r * bh + 4, bw - 8, bh - 8),
            const Radius.circular(4),
          ),
          blockPaint,
        );
      }
    }

    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    final avPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;

    for (var r = 0; r <= rows; r++) {
      final y = size.height * r / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          r == rows ~/ 2 ? avPaint : streetPaint);
    }
    for (var c = 0; c <= cols; c++) {
      final x = size.width * c / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          c == cols ~/ 2 ? avPaint : streetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RoutePainter extends CustomPainter {
  final Color color;
  const _RoutePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.52)
      ..lineTo(size.width * 0.18, size.height * 0.50)
      ..lineTo(size.width * 0.33, size.height * 0.48)
      ..lineTo(size.width * 0.50, size.height * 0.50)
      ..lineTo(size.width * 0.65, size.height * 0.45)
      ..lineTo(size.width * 0.80, size.height * 0.48)
      ..lineTo(size.width * 0.95, size.height * 0.46);

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.52),
      7,
      Paint()..color = Colors.green.shade700,
    );
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.46),
      7,
      Paint()..color = Colors.red.shade700,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.color != color;
}

class _BusMarkerWidget extends StatelessWidget {
  final MockBusMarker marker;
  const _BusMarkerWidget({required this.marker});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Positioned(
        left: marker.relX * constraints.maxWidth - 18,
        top: marker.relY * constraints.maxHeight - 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: marker.color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3)
                ],
              ),
              child: Text(
                marker.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.directions_bus_rounded,
                color: marker.color, size: 28),
          ],
        ),
      );
    });
  }
}
