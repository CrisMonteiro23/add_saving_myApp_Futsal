// lib/models/situacion.dart
// Este archivo define la estructura de datos para una "Situación" o evento registrado en cancha.

class Situacion {
  String id; // Identificador único de la situación
  DateTime timestamp; // Momento exacto en que se registró la situación
  bool esAFavor; // True si es "Llegada a favor", False si es "Llegada en contra"
  String tipoLlegada; // Tipo de llegada (ej: "Ataque Posicional", "5x4")
  List<String> jugadoresEnCanchaIds; // IDs de los 5 jugadores que estaban en cancha
  List<String> jugadoresEnCanchaNombres; // Nombres de los 5 jugadores (para fácil visualización)

  // Constructor de la clase Situacion.
  Situacion({
    required this.id,
    required this.timestamp,
    required this.esAFavor,
    required this.tipoLlegada,
    required this.jugadoresEnCanchaIds,
    required this.jugadoresEnCanchaNombres,
  });

  // Método para convertir un objeto Situacion a un formato JSON (Map).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(), // Guarda la fecha y hora como String
      'esAFavor': esAFavor,
      'tipoLlegada': tipoLlegada,
      'jugadoresEnCanchaIds': jugadoresEnCanchaIds,
      'jugadoresEnCanchaNombres': jugadoresEnCanchaNombres,
    };
  }

  // Método de fábrica para crear un objeto Situacion desde un formato JSON (Map).
  factory Situacion.fromJson(Map<String, dynamic> json) {
    return Situacion(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']), // Convierte String a DateTime
      esAFavor: json['esAFavor'],
      tipoLlegada: json['tipoLlegada'],
      jugadoresEnCanchaIds: List<String>.from(json['jugadoresEnCanchaIds']),
      jugadoresEnCanchaNombres: List<String>.from(json['jugadoresEnCanchaNombres']),
    );
  }
}
