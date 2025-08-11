// lib/data/app_data.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/models/situacion.dart';
import 'package:mi_app_futsal/models/partido.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppData extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // Lista de jugadores disponibles
  final List<Jugador> _jugadoresDisponibles = [
    Jugador(id: const Uuid().v4(), nombre: 'Victor'),
    Jugador(id: const Uuid().v4(), nombre: 'Fabio'),
    Jugador(id: const Uuid().v4(), nombre: 'Pablo'),
    Jugador(id: const Uuid().v4(), nombre: 'Nacho'),
    Jugador(id: const Uuid().v4(), nombre: 'Hugo'),
    Jugador(id: const Uuid().v4(), nombre: 'Carlos'),
    Jugador(id: const Uuid().v4(), nombre: 'Zequi'),
    Jugador(id: const Uuid().v4(), nombre: 'Arnaldo'),
    Jugador(id: const Uuid().v4(), nombre: 'Aranda'),
    Jugador(id: const Uuid().v4(), nombre: 'Enzo'),
    Jugador(id: const Uuid().v4(), nombre: 'Murilo'),
    Jugador(id: const Uuid().v4(), nombre: 'Titi'),
    Jugador(id: const Uuid().v4(), nombre: 'Pescio'),
    Jugador(id: const Uuid().v4(), nombre: 'Nicolas'),
  ];

  // ✅ NUEVO: Lista de todos los partidos
  final List<Partido> _partidos = [];
  
  // ✅ NUEVO: ID del partido actualmente seleccionado
  String? _partidoActualId;

  // === GETTERS ===
  List<Jugador> get jugadoresDisponibles => List.unmodifiable(_jugadoresDisponibles);
  List<Jugador> get jugadores => jugadoresDisponibles;
  
  // ✅ NUEVO: Getters para partidos
  List<Partido> get partidos => List.unmodifiable(_partidos);
  
  Partido? get partidoActual {
    if (_partidoActualId == null) return null;
    try {
      return _partidos.firstWhere((p) => p.id == _partidoActualId);
    } catch (e) {
      return null;
    }
  }

  String get partidoActualNombre => partidoActual?.equipoLocalNombre ?? 'Sin partido';

  // ✅ MODIFICADO: Ahora obtiene situaciones del partido actual
  List<Situacion> get situacionesRegistradas {
    final partido = partidoActual;
    if (partido == null) return [];
    return List.unmodifiable(partido.situaciones);
  }

  // === MÉTODOS DE PARTIDOS ===
  
  // ✅ NUEVO: Crear un nuevo partido
  String crearNuevoPartido(String nombreEquipoLocal, String nombreEquipoVisitante) {
    final nuevoPartido = Partido(
      id: _uuid.v4(),
      fecha: DateTime.now(),
      hora: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      equipoLocalId: _uuid.v4(),
      equipoLocalNombre: nombreEquipoLocal.trim(),
      golesLocal: 0,
      equipoVisitanteId: _uuid.v4(),
      equipoVisitanteNombre: nombreEquipoVisitante.trim(),
      golesVisitante: 0,
      jugadores: List.from(_jugadoresDisponibles),
      situaciones: [],
    );

    _partidos.add(nuevoPartido);
    _partidoActualId = nuevoPartido.id;
    
    notifyListeners();
    _saveToStorage();
    
    return nuevoPartido.id;
  }

  // ✅ NUEVO: Seleccionar un partido existente
  void seleccionarPartido(String partidoId) {
    if (_partidos.any((p) => p.id == partidoId)) {
      _partidoActualId = partidoId;
      notifyListeners();
      _saveToStorage();
    }
  }

  // ✅ NUEVO: Eliminar un partido
  void eliminarPartido(String partidoId) {
    _partidos.removeWhere((p) => p.id == partidoId);
    
    // Si eliminamos el partido actual, seleccionar otro o ninguno
    if (_partidoActualId == partidoId) {
      _partidoActualId = _partidos.isNotEmpty ? _partidos.last.id : null;
    }
    
    notifyListeners();
    _saveToStorage();
  }

  // === MÉTODOS EXISTENTES MODIFICADOS ===
  
  void addJugador(String nombre) {
    if (nombre.trim().isEmpty) return;
    if (_jugadoresDisponibles.any((j) => j.nombre.toLowerCase() == nombre.toLowerCase())) return;
    
    final nuevoJugador = Jugador(id: _uuid.v4(), nombre: nombre.trim());
    _jugadoresDisponibles.add(nuevoJugador);
    
    // ✅ NUEVO: Agregar jugador a todos los partidos existentes
    for (var partido in _partidos) {
      if (!partido.jugadores.any((j) => j.nombre.toLowerCase() == nombre.toLowerCase())) {
        partido.jugadores.add(nuevoJugador);
      }
    }
    
    notifyListeners();
    _saveToStorage();
  }

  void addSituacion(bool esAFavor, String tipoLlegada, List<Jugador> jugadoresEnCancha) {
    final partido = partidoActual;
    if (partido == null) {
      // Si no hay partido actual, crear uno automáticamente
      crearNuevoPartido('Equipo Local', 'Equipo Visitante');
      return addSituacion(esAFavor, tipoLlegada, jugadoresEnCancha);
    }

    final situacion = Situacion(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      esAFavor: esAFavor,
      tipoLlegada: tipoLlegada,
      jugadoresEnCanchaIds: jugadoresEnCancha.map((j) => j.id).toList(),
      jugadoresEnCanchaNombres: jugadoresEnCancha.map((j) => j.nombre).toList(),
    );
    
    partido.situaciones.add(situacion);
    notifyListeners();
    _saveToStorage();
  }

  void deleteSituacion(String id) {
    final partido = partidoActual;
    if (partido == null) return;
    
    partido.situaciones.removeWhere((s) => s.id == id);
    notifyListeners();
    _saveToStorage();
  }

  // === ESTADÍSTICAS (MODIFICADAS) ===
  Map<String, Map<String, int>> getStatsPorJugador() {
    final partido = partidoActual;
    if (partido == null) return {};

    final Map<String, Map<String, int>> stats = {};
    for (final jugador in partido.jugadores) {
      stats[jugador.id] = {'favor': 0, 'contra': 0};
    }

    for (final situacion in partido.situaciones) {
      for (final jugadorId in situacion.jugadoresEnCanchaIds) {
        stats.putIfAbsent(jugadorId, () => {'favor': 0, 'contra': 0});
        if (situacion.esAFavor) {
          stats[jugadorId]!['favor'] = stats[jugadorId]!['favor']! + 1;
        } else {
          stats[jugadorId]!['contra'] = stats[jugadorId]!['contra']! + 1;
        }
      }
    }

    return stats;
  }

  Map<String, Map<String, int>> getPlayerStats() => getStatsPorJugador();

  Map<String, Map<String, int>> getStatsPorTipo() {
    final partido = partidoActual;
    if (partido == null) return {};

    final Map<String, Map<String, int>> stats = {};
    for (final situacion in partido.situaciones) {
      final tipo = situacion.tipoLlegada;
      stats.putIfAbsent(tipo, () => {'favor': 0, 'contra': 0});
      if (situacion.esAFavor) {
        stats[tipo]!['favor'] = stats[tipo]!['favor']! + 1;
      } else {
        stats[tipo]!['contra'] = stats[tipo]!['contra']! + 1;
      }
    }
    return stats;
  }

  Map<String, Map<String, int>> getSituacionTypeStats() => getStatsPorTipo();

  Map<String, int> getTotalesReales() {
    final partido = partidoActual;
    if (partido == null) return {'favor': 0, 'contra': 0, 'total': 0};

    final int favor = partido.situaciones.where((s) => s.esAFavor).length;
    final int contra = partido.situaciones.where((s) => !s.esAFavor).length;
    final int total = favor + contra;
    return {
      'favor': favor,
      'contra': contra,
      'total': total,
    };
  }

  // === PERSISTENCIA MODIFICADA ===
  static const String _kKeyPartidos = 'partidos_guardados_v2';
  static const String _kKeyPartidoActual = 'partido_actual_id_v2';

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar todos los partidos
      final listaPartidos = _partidos.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_kKeyPartidos, listaPartidos);
      
      // Guardar ID del partido actual
      if (_partidoActualId != null) {
        await prefs.setString(_kKeyPartidoActual, _partidoActualId!);
      } else {
        await prefs.remove(_kKeyPartidoActual);
      }
    } catch (_) {
      // Ignorar errores de guardado
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar partidos
      final listaPartidos = prefs.getStringList(_kKeyPartidos) ?? [];
      _partidos
        ..clear()
        ..addAll(listaPartidos.map((s) => Partido.fromJson(jsonDecode(s))).toList());
      
      // Cargar ID del partido actual
      _partidoActualId = prefs.getString(_kKeyPartidoActual);
      
      // Verificar que el partido actual existe
      if (_partidoActualId != null && !_partidos.any((p) => p.id == _partidoActualId)) {
        _partidoActualId = _partidos.isNotEmpty ? _partidos.first.id : null;
      }
      
      notifyListeners();
    } catch (_) {
      // Ignorar errores de carga
    }
  }

  // ✅ NUEVO: Método para limpiar todos los datos
  Future<void> limpiarTodosLosDatos() async {
    _partidos.clear();
    _partidoActualId = null;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyPartidos);
    await prefs.remove(_kKeyPartidoActual);
  }
}
