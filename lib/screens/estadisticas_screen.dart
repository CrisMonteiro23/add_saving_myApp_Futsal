// lib/screens/estadisticas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_futsal/data/app_data.dart';
import '../data/app_data.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/models/situacion.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  // Estado para controlar si mostrar estadísticas generales o del partido actual
  bool _mostrarTodo = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas'),
          actions: [
            // Botón para alternar entre "Todo" y "Partido Actual"
            IconButton(
              icon: Icon(_mostrarTodo ? Icons.filter_alt_off : Icons.filter_alt),
              tooltip: _mostrarTodo ? 'Mostrar solo Partido Actual' : 'Mostrar Todas las Estadísticas',
              onPressed: () {
                setState(() {
                  _mostrarTodo = !_mostrarTodo;
                });
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Por Jugador'),
              Tab(text: 'Por Situación'),
              Tab(text: 'Gráficos'),
            ],
          ),
        ),
        body: Consumer<AppData>(
          builder: (context, appData, child) {
            // Se obtienen las situaciones en base al filtro seleccionado
            final List<Situacion> situaciones;
            if (_mostrarTodo) {
              situaciones = appData.situacionesRegistradas;
            } else {
              situaciones = appData.partidoActual?.situaciones ?? [];
            }

            // Calculamos las estadísticas dentro del Consumer para que se actualicen con el filtro
            final Map<String, Map<String, int>> playerStats = _getPlayerStats(situaciones);
            final Map<String, Map<String, int>> situacionTypeStats = _getSituacionTypeStats(situaciones);
            final List<Situacion> situacionesAFavor = situaciones.where((s) => s.esAFavor).toList();
            final List<Situacion> situacionesEnContra = situaciones.where((s) => !s.esAFavor).toList();

            return TabBarView(
              children: [
                _buildPlayerStatsTable(context, playerStats, appData.jugadoresDisponibles, situaciones),
                _buildSituationTypeTables(context, situacionesAFavor, situacionesEnContra),
                _buildChartsView(context, playerStats, appData.jugadoresDisponibles, situacionesAFavor, situacionesEnContra),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _exportDataToCsv(context, Provider.of<AppData>(context, listen: false)),
          label: const Text('Exportar a CSV'),
          icon: const Icon(Icons.download),
        ),
      ),
    );
  }

  // --- Funciones para calcular estadísticas localmente ---
  Map<String, Map<String, int>> _getPlayerStats(List<Situacion> situaciones) {
    final Map<String, Map<String, int>> stats = {};
    for (var situacion in situaciones) {
      for (var jugadorId in situacion.jugadoresEnCanchaIds) {
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

  // Función para obtener las estadísticas por tipo de situación
  Map<String, int> _getSituacionTypeStats(List<Situacion> situaciones) {
    final Map<String, int> stats = {};
    for (var situacion in situaciones) {
      stats.update(situacion.tipoLlegada, (value) => value + 1, ifAbsent: () => 1);
    }
    return stats;
  }


  // --- Widgets para Tablas de Estadísticas ---
  Widget _buildPlayerStatsTable(BuildContext context, Map<String, Map<String, int>> stats, List<Jugador> jugadores, List<Situacion> situaciones) {
    if (stats.isEmpty || jugadores.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de jugadores para mostrar estadísticas.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final Map<String, String> idToNombre = {for (var j in jugadores) j.id: j.nombre};
    final List<MapEntry<String, Map<String, int>>> statsConDatos = stats.entries.where((entry) {
      final playerStat = entry.value;
      return playerStat['favor']! > 0 || playerStat['contra']! > 0;
    }).toList();
    statsConDatos.sort((a, b) => idToNombre[a.key]!.toLowerCase().compareTo(idToNombre[b.key]!.toLowerCase()));

    if (statsConDatos.isEmpty) {
      return const Center(
        child: Text(
          'No hay situaciones registradas para los jugadores.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final int totalFavor = situaciones.where((s) => s.esAFavor).length;
    final int totalContra = situaciones.where((s) => !s.esAFavor).length;
    final int totalBalance = totalFavor - totalContra;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DataTable(
          columnSpacing: 16,
          dataRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
          columns: const [
            DataColumn(label: Text('Jugador', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('A Favor', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('En Contra', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          ],
          rows: [
            ...statsConDatos.map((entry) {
              final jugadorNombre = idToNombre[entry.key] ?? 'Desconocido';
              final playerStat = entry.value;
              final favor = playerStat['favor']!;
              final contra = playerStat['contra']!;
              final balance = favor - contra;
              return DataRow(
                cells: [
                  DataCell(Text(jugadorNombre)),
                  DataCell(Text(favor.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(contra.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(balance.toString(), textAlign: TextAlign.center, style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                ],
              );
            }).toList(),
            DataRow(
              color: MaterialStateProperty.all(Colors.blue.shade50),
              cells: [
                const DataCell(Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(Text(totalFavor.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
                DataCell(Text(totalContra.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red))),
                DataCell(Text(totalBalance.toString(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: totalBalance >= 0 ? Colors.green : Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationTypeTables(BuildContext context, List<Situacion> situacionesAFavor, List<Situacion> situacionesEnContra) {
    // Calculamos las estadísticas por tipo de situación para cada categoría
    final Map<String, int> statsAFavor = _getSituacionTypeStats(situacionesAFavor);
    final Map<String, int> statsEnContra = _getSituacionTypeStats(situacionesEnContra);
    

    // Total de situaciones por categoría para el cálculo de porcentajes
    final int totalAFavor = situacionesAFavor.length;
    final int totalEnContra = situacionesEnContra.length;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSingleSituationTable(context, 'Situaciones A Favor', statsAFavor, totalAFavor, Colors.green),
          const SizedBox(height: 20),
          _buildSingleSituationTable(context, 'Situaciones En Contra', statsEnContra, totalEnContra, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSingleSituationTable(BuildContext context, String title, Map<String, int> stats, int total, Color color) {
  Widget _buildSingleSituationTable(BuildContext context, String title, Map<String, int> stats, int total, MaterialColor color) {
    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay datos para "$title".',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final List<MapEntry<String, int>> sortedStats = stats.entries.toList();
    sortedStats.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              dataRowHeight: 50,
              headingRowColor: MaterialStateProperty.all(color.shade100),
              columns: const [
                DataColumn(label: Text('Tipo de Llegada', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                DataColumn(label: Text('% del Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
              rows: [
                ...sortedStats.map((entry) {
                  final porcentaje = total > 0 ? (entry.value / total) * 100 : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text(entry.value.toString(), textAlign: TextAlign.center)),
                      DataCell(Text('${porcentaje.toStringAsFixed(1)}%', textAlign: TextAlign.center)),
                    ],
                  );
                }).toList(),
                DataRow(
                  color: MaterialStateProperty.all(color.shade50),
                  cells: [
                    const DataCell(Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(Text(total.toString(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color))),
                    const DataCell(Text('100.0%', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- Widgets para Gráficos de Estadísticas ---
  Widget _buildChartsView(BuildContext context, Map<String, Map<String, int>> playerStats, List<Jugador> jugadores, List<Situacion> situacionesAFavor, List<Situacion> situacionesEnContra) {
    if (playerStats.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos suficientes para generar gráficos.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }
    final Map<String, String> idToNombre = {for (var j in jugadores) j.id: j.nombre};
    final List<MapEntry<String, Map<String, int>>> playerStatsConDatos = playerStats.entries.where((entry) {
      final playerStat = entry.value;
      return playerStat['favor']! > 0 || playerStat['contra']! > 0;
    }).toList();
    playerStatsConDatos.sort((a, b) => idToNombre[a.key]!.toLowerCase().compareTo(idToNombre[b.key]!.toLowerCase()));
    // Calculamos las estadísticas de tipo de situación para los gráficos
    final Map<String, int> statsAFavor = _getSituacionTypeStats(situacionesAFavor);
    final Map<String, int> statsEnContra = _getSituacionTypeStats(situacionesEnContra);
    final int totalAFavor = situacionesAFavor.length;
    final int totalEnContra = situacionesEnContra.length;
    final List<Color> pieChartColors = Colors.primaries;
    // Funciones para generar las secciones de los gráficos circulares
    List<PieChartSectionData> getPieSections(Map<String, int> stats, int total) {
      if (total == 0) return [];
      final List<MapEntry<String, int>> sortedStats = stats.entries.toList();
      sortedStats.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

      return sortedStats.map((entry) {
        final index = sortedStats.indexOf(entry);
        final color = pieChartColors[index % pieChartColors.length];
        return PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${(entry.value / total * 100).toStringAsFixed(1)}%',
          radius: 50.0,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xffffffff),
          ),
        );
      }).toList();
    }
    Widget _buildPieChartCard(String title, Map<String, int> stats, int total, Color color) {
      if (total == 0) return const SizedBox.shrink();

      final List<MapEntry<String, int>> sortedStats = stats.entries.toList();
      sortedStats.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          sections: getPieSections(stats, total),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedStats.map((entry) {
                        final index = sortedStats.indexOf(entry);
                        final color = pieChartColors[index % pieChartColors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (playerStatsConDatos.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Llegadas por Jugador (A Favor vs. En Contra)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (playerStatsConDatos.map((v) => (v.value['favor'] ?? 0) + (v.value['contra'] ?? 0)).fold<int>(0, (max, current) => current > max ? current : max) + 2).toDouble(),
                          barGroups: playerStatsConDatos.map((entry) {
                            final playerStat = entry.value;
                            final favor = playerStat['favor']!.toDouble();
                            final contra = playerStat['contra']!.toDouble();
                            final index = playerStatsConDatos.indexOf(entry);

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: favor,
                                  color: Colors.green.shade400,
                                  width: 15,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: favor + contra,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      idToNombre[playerStatsConDatos[value.toInt()].key] ?? '?',
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                                interval: 1,
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                },
                                interval: 1,
                                reservedSize: 28,
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.blueGrey,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final jugadorNombre = idToNombre[playerStatsConDatos[group.x.toInt()].key] ?? '?';
                                final playerStat = playerStatsConDatos[group.x.toInt()].value;
                                return BarTooltipItem(
                                  '$jugadorNombre:\nFavor: ${playerStat['favor']}\nContra: ${playerStat['contra']}',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          

          if (situacionesAFavor.isNotEmpty || situacionesEnContra.isNotEmpty)
            const SizedBox(height: 20),

          if (situacionesAFavor.isNotEmpty)
            _buildPieChartCard('Distribución de Situaciones A Favor', statsAFavor, totalAFavor, Colors.green),
          

          if (situacionesEnContra.isNotEmpty)
            _buildPieChartCard('Distribución de Situaciones En Contra', statsEnContra, totalEnContra, Colors.red),
        ],
      ),
    );
  }

  void _exportDataToCsv(BuildContext context, AppData appData) async {
    final List<Situacion> situaciones;
    if (_mostrarTodo) {
      situaciones = appData.situacionesRegistradas;
    } else {
      situaciones = appData.partidoActual?.situaciones ?? [];
    }
    

    final List<List<dynamic>> rawData = [];

    rawData.add([
      'ID Situacion',
      'Fecha y Hora',
      'Es A Favor',
      'Tipo de Llegada',
      'Jugadores en Cancha (Nombres)',
      'Jugadores en Cancha (IDs)',
    ]);

    for (var situacion in situaciones) {
      rawData.add([
        situacion.id,
        situacion.timestamp.toIso8601String(),
        situacion.esAFavor ? 'Sí' : 'No',
        situacion.tipoLlegada,
        situacion.jugadoresEnCanchaNombres.join(', '),
        situacion.jugadoresEnCanchaIds.join(', '),
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rawData);
    await Clipboard.setData(ClipboardData(text: csv));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos crudos copiados al portapapeles. Pégalos en Excel para crear gráficos.'),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
