// lib/models/equipo.dart
// Este archivo define la estructura de datos para un Equipo.

class Equipo {
  String id; // Identificador único del equipo
  String nombre; // Nombre del equipo (ej: "Los Invencibles")
  String entrenador; // Nombre del entrenador
  String colores; // Colores del uniforme (ej: "Azul y Blanco")
  int pj; // Partidos Jugados
  int pg; // Partidos Ganados
  int pe; // Partidos Empatados
  int pp; // Partidos Perdidos
  int gf; // Goles a Favor
  int gc; // Goles en Contra
  int dg; // Diferencia de Goles (GF - GC)
  int puntos; // Puntos en la tabla (3 por victoria, 1 por empate)

  // Constructor de la clase Equipo.
  // Los campos 'id', 'nombre', 'entrenador' y 'colores' son obligatorios.
  // Los campos de estadísticas tienen valores predeterminados de 0.
  Equipo({
    required this.id,
    required this.nombre,
    required this.entrenador,
    required this.colores,
    this.pj = 0,
    this.pg = 0,
    this.pe = 0,
    this.pp = 0,
    this.gf = 0,
    this.gc = 0,
    this.dg = 0,
    this.puntos = 0,
  });

  // Método para convertir un objeto Equipo a un formato JSON (Map).
  // Útil si en el futuro quieres guardar los datos en un archivo o base de datos.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'entrenador': entrenador,
      'colores': colores,
      'pj': pj,
      'pg': pg,
      'pe': pe,
      'pp': pp,
      'gf': gf,
      'gc': gc,
      'dg': dg,
      'puntos': puntos,
    };
  }

  // Método de fábrica para crear un objeto Equipo desde un formato JSON (Map).
  // Útil si en el futuro quieres cargar los datos desde un archivo o base de datos.
  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'],
      nombre: json['nombre'],
      entrenador: json['entrenador'],
      colores: json['colores'],
      pj: json['pj'] ?? 0, // Si el campo es nulo, usa 0
      pg: json['pg'] ?? 0,
      pe: json['pe'] ?? 0,
      pp: json['pp'] ?? 0,
      gf: json['gf'] ?? 0,
      gc: json['gc'] ?? 0,
      dg: json['dg'] ?? 0,
      puntos: json['puntos'] ?? 0,
    );
  }
}
