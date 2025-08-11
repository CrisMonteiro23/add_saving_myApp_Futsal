import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/partido.dart';

class DataService {
  static const _keyPartidos = 'partidos_guardados';

  static Future<void> guardarPartidos(List<Partido> partidos) async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = partidos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_keyPartidos, listaJson);
  }

  static Future<List<Partido>> cargarPartidos() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = prefs.getStringList(_keyPartidos) ?? [];
    return listaJson.map((e) => Partido.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> limpiarPartidos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPartidos);
  }
}
