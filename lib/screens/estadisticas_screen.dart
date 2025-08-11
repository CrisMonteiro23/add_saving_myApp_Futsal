// lib/screens/estadisticas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_futsal/data/app_data.dart';
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

            // Calculamos las estadísticas dentro de este widget
            final Map<String, Map<String, int>> playerStats = _getPlayerStats(situaciones);
            final Map<String, Map<String, int>> situacionTypeStats = _getSituacionTypeStats(situaciones);

            return TabBarView(
              children: [
                _buildPlayerStatsTable(context, playerStats, appData.jugadoresDisponibles),
                _buildSituationTypeStatsTable(context, situacionTypeStats),
                _buildChartsView(context, playerStats, situacionTypeStats, appData.jugadoresDisponibles),
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

  Map<String, Map<String, int>> _getSituacionTypeStats(List<Situacion> situaciones) {
    final Map<String, Map<String, int>> stats = {};
    for (var situacion in situaciones) {
      stats.putIfAbsent(situacion.tipoLlegada, () => {'favor': 0, 'contra': 0});
      if (situacion.esAFavor) {
        stats[situacion.tipoLlegada]!['favor'] = stats[situacion.tipoLlegada]!['favor']! + 1;
      } else {
        stats[situacion.tipoLlegada]!['contra'] = stats[situacion.tipoLlegada]!['contra']! + 1;
      }
    }
    return stats;
  }

  // --- Widgets para Tablas de Estadísticas ---
  Widget _buildPlayerStatsTable(BuildContext context, Map<String, Map<String, int>> stats, List<Jugador> jugadores) {
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

    int totalFavorJugadores = 0;
    int totalContraJugadores = 0;
    for (var entry in statsConDatos) {
      final playerStat = entry.value;
      totalFavorJugadores += playerStat['favor']!;
      totalContraJugadores += playerStat['contra']!;
    }
    final int totalGeneralJugadores = totalFavorJugadores + totalContraJugadores;

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
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          ],
          rows: [
            ...statsConDatos.map((entry) {
              final jugadorNombre = idToNombre[entry.key] ?? 'Desconocido';
              final playerStat = entry.value;
              final favor = playerStat['favor']!;
              final contra = playerStat['contra']!;
              final total = favor + contra;
              return DataRow(
                cells: [
                  DataCell(Text(jugadorNombre)),
                  DataCell(Text(favor.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(contra.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(total.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              );
            }).toList(),
            DataRow(
              color: MaterialStateProperty.all(Colors.blue.shade50),
              cells: [
                const DataCell(Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(Text(totalFavorJugadores.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
                DataCell(Text(totalContraJugadores.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red))),
                DataCell(Text(totalGeneralJugadores.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationTypeStatsTable(BuildContext context, Map<String, Map<String, int>> stats) {
    if (stats.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de tipos de situación para mostrar estadísticas.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<MapEntry<String, Map<String, int>>> sortedStats = stats.entries.toList();
    sortedStats.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    final List<MapEntry<String, Map<String, int>>> statsConDatos = sortedStats.where((entry) {
      final typeStat = entry.value;
      return typeStat['favor']! > 0 || typeStat['contra']! > 0;
    }).toList();

    if (statsConDatos.isEmpty) {
      return const Center(
        child: Text(
          'No hay situaciones registradas por tipo.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    int totalSituaciones = 0;
    for (var entry in statsConDatos) {
      totalSituaciones += (entry.value['favor'] ?? 0) + (entry.value['contra'] ?? 0);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DataTable(
          columnSpacing: 16,
          dataRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
          columns: const [
            DataColumn(label: Text('Tipo de Llegada', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('A Favor', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('En Contra', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('% del Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          ],
          rows: [
            ...statsConDatos.map((entry) {
              final tipo = entry.key;
              final typeStat = entry.value;
              final favor = typeStat['favor']!;
              final contra = typeStat['contra']!;
              final total = favor + contra;
              final porcentaje = totalSituaciones > 0 ? (total / totalSituaciones) * 100 : 0;
              return DataRow(
                cells: [
                  DataCell(Text(tipo)),
                  DataCell(Text(favor.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(contra.toString(), textAlign: TextAlign.center)),
                  DataCell(Text(total.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${porcentaje.toStringAsFixed(1)}%', textAlign: TextAlign.center)),
                ],
              );
            }).toList(),
            DataRow(
              color: MaterialStateProperty.all(Colors.blue.shade50),
              cells: [
                const DataCell(Text('TOTAL GENERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(Text(statsConDatos.fold(0, (sum, entry) => sum + (entry.value['favor'] ?? 0)).toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
                DataCell(Text(statsConDatos.fold(0, (sum, entry) => sum + (entry.value['contra'] ?? 0)).toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red))),
                DataCell(Text(totalSituaciones.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent))),
                const DataCell(Text('100.0%', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets para Gráficos de Estadísticas ---
  Widget _buildChartsView(BuildContext context, Map<String, Map<String, int>> playerStats, Map<String, Map<String, int>> situacionTypeStats, List<Jugador> jugadores) {
    if (playerStats.isEmpty || situacionTypeStats.isEmpty) {
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

    final List<MapEntry<String, Map<String, int>>> situacionStatsConDatos = situacionTypeStats.entries.where((entry) {
      final typeStat = entry.value;
      return typeStat['favor']! > 0 || typeStat['contra']! > 0;
    }).toList();
    situacionStatsConDatos.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    
    final List<Color> pieChartColors = Colors.primaries;
    
    final double totalSituaciones = situacionStatsConDatos.fold(0.0, (sum, e) => sum + (e.value['favor'] ?? 0) + (e.value['contra'] ?? 0));

    final List<PieChartSectionData> pieChartSections = situacionStatsConDatos.map((entry) {
      final stats = entry.value;
      final total = (stats['favor'] ?? 0) + (stats['contra'] ?? 0);
      final index = situacionStatsConDatos.indexOf(entry);

      return PieChartSectionData(
        color: pieChartColors[index % pieChartColors.length],
        value: total.toDouble(),
        title: totalSituaciones > 0 ? '${(total / totalSituaciones * 100).toStringAsFixed(1)}%' : '0%',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();

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
                              // CORRECCIÓN: Se agrega el parámetro rodIndex para que coincida con la firma esperada
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

          if (playerStatsConDatos.isNotEmpty && situacionStatsConDatos.isNotEmpty)
            const SizedBox(height: 20),

          if (situacionStatsConDatos.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Distribución por Tipo de Situación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                sections: pieChartSections,
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                borderData: FlBorderData(show: false),
                                pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  // Lógica para interactividad si es necesaria
                                }),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: situacionStatsConDatos.map((entry) {
                              final index = situacionStatsConDatos.indexOf(entry);
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
            ),
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
