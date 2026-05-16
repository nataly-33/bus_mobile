class PosicionGPS {
  final int conductorId;
  final String placa;
  final int lineaId;
  final String sentido;
  final double lat;
  final double lng;
  final double velocidad;
  final double distancia;
  final int tiempoSeg;
  final bool activo;
  final DateTime? timestamp;

  const PosicionGPS({
    required this.conductorId,
    required this.placa,
    required this.lineaId,
    required this.sentido,
    required this.lat,
    required this.lng,
    this.velocidad = 0,
    this.distancia = 0,
    this.tiempoSeg = 0,
    this.activo = true,
    this.timestamp,
  });

  static List<PosicionGPS> mockPosiciones(int lineaId) => [
        PosicionGPS(
          conductorId: 1,
          placa: 'ABC-123',
          lineaId: lineaId,
          sentido: 'ida',
          lat: -17.7820,
          lng: -63.1860,
          velocidad: 32.0,
          activo: true,
        ),
        PosicionGPS(
          conductorId: 2,
          placa: 'DEF-456',
          lineaId: lineaId,
          sentido: 'ida',
          lat: -17.7850,
          lng: -63.1790,
          velocidad: 28.5,
          activo: true,
        ),
        PosicionGPS(
          conductorId: 3,
          placa: 'GHI-789',
          lineaId: lineaId,
          sentido: 'vuelta',
          lat: -17.7800,
          lng: -63.1920,
          velocidad: 40.0,
          activo: true,
        ),
      ];
}
