import 'jugador.dart';
import 'situacion.dart';

class Partido {
  String id;
  DateTime fecha;
  String hora;
  String equipoLocalId;
  String equipoLocalNombre;
  int golesLocal;
  String equipoVisitanteId;
  String equipoVisitanteNombre;
  int golesVisitante;
  List<Jugador> jugadores;
  List<Situacion> situaciones;

  Partido({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    required this.golesLocal,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    required this.golesVisitante,
    required this.jugadores,
    required this.situaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'equipoLocalId': equipoLocalId,
      'equipoLocalNombre': equipoLocalNombre,
      'golesLocal': golesLocal,
      'equipoVisitanteId': equipoVisitanteId,
      'equipoVisitanteNombre': equipoVisitanteNombre,
      'golesVisitante': golesVisitante,
      'jugadores': jugadores.map((j) => j.toJson()).toList(),
      'situaciones': situaciones.map((s) => s.toJson()).toList(),
    };
  }

  factory Partido.fromJson(Map<String, dynamic> json) {
    return Partido(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      hora: json['hora'],
      equipoLocalId: json['equipoLocalId'],
      equipoLocalNombre: json['equipoLocalNombre'],
      golesLocal: json['golesLocal'],
      equipoVisitanteId: json['equipoVisitanteId'],
      equipoVisitanteNombre: json['equipoVisitanteNombre'],
      golesVisitante: json['golesVisitante'],
      jugadores: (json['jugadores'] as List)
          .map((j) => Jugador.fromJson(j))
          .toList(),
      situaciones: (json['situaciones'] as List)
          .map((s) => Situacion.fromJson(s))
          .toList(),
    );
  }
}
