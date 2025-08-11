import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/models/situacion.dart';
import 'package:fl_chart/fl_chart.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Por Jugador'),
              Tab(text: 'Por Situación'),
              Tab(text: 'Gráficos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabEstadisticasJugadores(),
            TablaTiposSituacionWidget(),
            GraficosEstadisticasWidget(),
          ],
        ),
      ),
    );
  }
}

class TabEstadisticasJugadores extends StatelessWidget {
  const TabEstadisticasJugadores({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final stats = appData.getPlayerStats();
    final jugadores = appData.jugadoresDisponibles;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Estadísticas por jugador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TablaJugadoresWidget(stats: stats, jugadores: jugadores),
        ],
      ),
    );
  }
}

class TablaJugadoresWidget extends StatelessWidget {
  final Map<String, Map<String, int>> stats;
  final List<Jugador> jugadores;

  const TablaJugadoresWidget({super.key, required this.stats, required this.jugadores});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false);

    if (stats.isEmpty || jugadores.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de jugadores para mostrar estadísticas.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final jugadoresConDatos = jugadores.where((jugador) {
      final playerStat = stats[jugador.id];
      return playerStat != null &&
          (playerStat['favor']! > 0 || playerStat['contra']! > 0);
    }).toList();

    if (jugadoresConDatos.isEmpty) {
      return const Center(
        child: Text(
          'No hay situaciones registradas para los jugadores.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    jugadoresConDatos.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    final totales = appData.getTotalesReales();
    final totalFavor = totales['favor']!;
    final totalContra = totales['contra']!;
    final totalGeneral = totales['total']!;

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
            DataColumn(label: Text('A Favor', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('En Contra', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            ...jugadoresConDatos.map((jugador) {
              final playerStat = stats[jugador.id]!;
              final favor = playerStat['favor']!;
              final contra = playerStat['contra']!;
              final total = favor + contra;
              final balance = favor - contra;

              return DataRow(cells: [
                DataCell(Text(jugador.nombre)),
                DataCell(Text(favor.toString())),
                DataCell(Text(contra.toString())),
                DataCell(Text(
                  balance.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0 ? Colors.green : balance < 0 ? Colors.red : Colors.grey,
                  ),
                )),
                DataCell(Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
            DataRow(
              color: MaterialStateProperty.all(Colors.blue.shade50),
              cells: [
                const DataCell(Text('LLEGADAS ÚNICAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(Text(totalFavor.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
                DataCell(Text(totalContra.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red))),
                const DataCell(Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(Text(totalGeneral.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TablaTiposSituacionWidget extends StatelessWidget {
  const TablaTiposSituacionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final tipoStats = appData.getSituacionTypeStats();

    if (tipoStats.isEmpty) {
      return const Center(
        child: Text('No hay estadísticas disponibles.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.orange.shade100),
        columns: const [
          DataColumn(label: Text('Tipo de Situación', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('A Favor', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('En Contra', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: tipoStats.entries.map((entry) {
          final tipo = entry.key;
          final favor = entry.value['favor']!;
          final contra = entry.value['contra']!;

          return DataRow(cells: [
            DataCell(Text(tipo)),
            DataCell(Text(favor.toString())),
            DataCell(Text(contra.toString())),
          ]);
        }).toList(),
      ),
    );
  }
}

class GraficosEstadisticasWidget extends StatelessWidget {
  const GraficosEstadisticasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final tipoStats = appData.getSituacionTypeStats();
    final totalStats = appData.getTotalesReales();

    final pieSections = tipoStats.entries
        .where((e) => (e.value['favor']! + e.value['contra']!) > 0)
        .map((e) => PieChartSectionData(
              title: e.key,
              value: (e.value['favor']! + e.value['contra']!).toDouble(),
              radius: 60,
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Distribución por tipo de situación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Balance general de llegadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (totalStats.values.reduce((a, b) => a > b ? a : b).toDouble() + 5),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: totalStats['favor']!.toDouble(), color: Colors.green)
                ], showingTooltipIndicators: [0]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: totalStats['contra']!.toDouble(), color: Colors.red)
                ], showingTooltipIndicators: [0]),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('A Favor');
                        case 1:
                          return const Text('En Contra');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
            ),
          )
        ],
      ),
    );
  }
}
