// lib/models/partido.dart
// Este archivo define la estructura de datos para un Partido.

class Partido {
  String id; // Identificador único del partido
  DateTime fecha; // Fecha del partido
  String hora; // Hora del partido (ej: "20:00")
  String equipoLocalId; // ID del equipo local
  String equipoLocalNombre; // Nombre del equipo local
  int golesLocal; // Goles marcados por el equipo local
  String equipoVisitanteId; // ID del equipo visitante
  String equipoVisitanteNombre; // Nombre del equipo visitante
  int golesVisitante; // Goles marcados por el equipo visitante
  String cancha; // Nombre de la cancha
  String arbitro; // Nombre del árbitro
  String estado; // Estado del partido (ej: "Programado", "Jugado", "Aplazado")

  // Constructor de la clase Partido.
  // Todos los campos son obligatorios.
  Partido({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    this.golesLocal = 0, // Por defecto 0 goles
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    this.golesVisitante = 0, // Por defecto 0 goles
    required this.cancha,
    required this.arbitro,
    this.estado = 'Programado', // Estado inicial por defecto
  });

  // Método para convertir un objeto Partido a un formato JSON (Map).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(), // Convierte DateTime a String ISO 8601
      'hora': hora,
      'equipoLocalId': equipoLocalId,
      'equipoLocalNombre': equipoLocalNombre,
      'golesLocal': golesLocal,
      'equipoVisitanteId': equipoVisitanteId,
      'equipoVisitanteNombre': equipoVisitanteNombre,
      'golesVisitante': golesVisitante,
      'cancha': cancha,
      'arbitro': arbitro,
      'estado': estado,
    };
  }

  // Método de fábrica para crear un objeto Partido desde un formato JSON (Map).
  factory Partido.fromJson(Map<String, dynamic> json) {
    return Partido(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']), // Convierte String ISO 8601 a DateTime
      hora: json['hora'],
      equipoLocalId: json['equipoLocalId'],
      equipoLocalNombre: json['equipoLocalNombre'],
      golesLocal: json['golesLocal'] ?? 0,
      equipoVisitanteId: json['equipoVisitanteId'],
      equipoVisitanteNombre: json['equipoVisitanteNombre'],
      golesVisitante: json['golesVisitante'] ?? 0,
      cancha: json['cancha'],
      arbitro: json['arbitro'],
      estado: json['estado'] ?? 'Programado',
    );
  }
}
