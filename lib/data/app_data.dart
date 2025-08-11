// lib/data/app_data.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/models/situacion.dart';
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

  final List<Situacion> _situacionesRegistradas = [];

  // ✅ NUEVO: Nombre del partido actual
  String _partidoActual = '';

  // Getter público para acceder a la lista de jugadores
  List<Jugador> get jugadoresDisponibles => List.unmodifiable(_jugadoresDisponibles);

  // Getter para uso directo (estadísticas)
  List<Situacion> get situacionesRegistradas => List.unmodifiable(_situacionesRegistradas);

  // ✅ NUEVO: Getter/setter partido actual
  String get partidoActual => _partidoActual;
  void setPartidoActual(String nombre) {
    _partidoActual = nombre.trim();
    notifyListeners();
    _saveToStorage();
  }

  void addJugador(String nombre) {
    if (nombre.trim().isEmpty) return;
    if (_jugadoresDisponibles.any((j) => j.nombre.toLowerCase() == nombre.toLowerCase())) return;
    _jugadoresDisponibles.add(Jugador(id: _uuid.v4(), nombre: nombre.trim()));
    notifyListeners();
  }

  void addSituacion(bool esAFavor, String tipoLlegada, List<Jugador> jugadoresEnCancha) {
    final situacion = Situacion(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      esAFavor: esAFavor,
      tipoLlegada: tipoLlegada,
      jugadoresEnCanchaIds: jugadoresEnCancha.map((j) => j.id).toList(),
      jugadoresEnCanchaNombres: jugadoresEnCancha.map((j) => j.nombre).toList(),
    );
    _situacionesRegistradas.add(situacion);
    notifyListeners();
    _saveToStorage();
  }

  void deleteSituacion(String id) {
    _situacionesRegistradas.removeWhere((s) => s.id == id);
    notifyListeners();
    _saveToStorage();
  }

  Map<String, Map<String, int>> getStatsPorJugador() {
    final Map<String, Map<String, int>> stats = {};
    for (final jugador in _jugadoresDisponibles) {
      stats[jugador.id] = {'favor': 0, 'contra': 0};
    }

    for (final situacion in _situacionesRegistradas) {
      for (final jugadorId in situacion.jugadoresEnCanchaIds) {
        if (!stats.containsKey(jugadorId)) {
          stats[jugadorId] = {'favor': 0, 'contra': 0};
        }
        if (situacion.esAFavor) {
          stats[jugadorId]!['favor'] = stats[jugadorId]!['favor']! + 1;
        } else {
          stats[jugadorId]!['contra'] = stats[jugadorId]!['contra']! + 1;
        }
      }
    }

    return stats;
  }

  Map<String, Map<String, int>> getStatsPorTipo() {
    final Map<String, Map<String, int>> stats = {};
    for (final situacion in _situacionesRegistradas) {
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

  // ✅ NUEVO: Totales reales (llegadas únicas, no duplicadas por jugador)
  Map<String, int> getTotalesReales() {
    final int favor = _situacionesRegistradas.where((s) => s.esAFavor).length;
    final int contra = _situacionesRegistradas.where((s) => !s.esAFavor).length;
    final int total = favor + contra;
    return {
      'favor': favor,
      'contra': contra,
      'total': total,
    };
  }

  // --- Persistencia local ---
  static const String _kKeySituaciones = 'situaciones_guardadas_v1';
  static const String _kKeyPartido = 'partido_actual_v1';

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = _situacionesRegistradas.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_kKeySituaciones, lista);
      await prefs.setString(_kKeyPartido, _partidoActual); // ✅ Guardar partido
    } catch (e) {
      // Si falla el guardado, no queremos bloquear la app. Se podría loguear acá.
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList(_kKeySituaciones) ?? [];
      _situacionesRegistradas.clear();
      _situacionesRegistradas.addAll(lista.map((s) => Situacion.fromJson(jsonDecode(s))).toList());
      _partidoActual = prefs.getString(_kKeyPartido) ?? ''; // ✅ Cargar partido
      notifyListeners();
    } catch (e) {
      // Ignorar errores de carga en inicialización.
    }
  }
}
