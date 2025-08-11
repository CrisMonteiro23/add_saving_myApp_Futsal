// lib/screens/partidos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../models/partido.dart';
import 'package:intl/intl.dart';

class PartidosScreen extends StatelessWidget {
  const PartidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Partidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpiar todos los datos',
            onPressed: () => _showLimpiarDatosDialog(context),
          ),
        ],
      ),
      body: Consumer<AppData>(
        builder: (context, appData, child) {
          final partidos = appData.partidos;
          final partidoActual = appData.partidoActual;

          if (partidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay partidos creados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCrearPartidoDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Primer Partido'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Información del partido actual
              if (partidoActual != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Partido Actual:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${partidoActual.equipoLocalNombre} vs ${partidoActual.equipoVisitanteNombre}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Situaciones registradas: ${partidoActual.situaciones.length}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(partidoActual.fecha)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),

              // Lista de partidos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: partidos.length,
                  itemBuilder: (context, index) {
                    final partido = partidos[index];
                    final esActual = partidoActual?.id == partido.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: esActual ? 8 : 2,
                      color: esActual ? Colors.blue.shade100 : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: esActual ? Colors.blue : Colors.grey,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                          style: TextStyle(
                            fontWeight: esActual ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(partido.fecha)} - ${partido.hora}',
                            ),
                            Text('Situaciones: ${partido.situaciones.length}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'seleccionar':
                                appData.seleccionarPartido(partido.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Partido "${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}" seleccionado'),
                                  ),
                                );
                                break;
                              case 'eliminar':
                                _showEliminarPartidoDialog(context, partido, appData);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (!esActual)
                              const PopupMenuItem(
                                value: 'seleccionar',
                                child: ListTile(
                                  leading: Icon(Icons.check_circle),
                                  title: Text('Seleccionar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            PopupMenuItem(
                              value: 'eliminar',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red.shade600),
                                title: Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: esActual ? null : () {
                          appData.seleccionarPartido(partido.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Partido "${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}" seleccionado'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearPartidoDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Partido'),
      ),
    );
  }

  void _showCrearPartidoDialog(BuildContext context) {
    final equipoLocalController = TextEditingController();
    final equipoVisitanteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Partido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: equipoLocalController,
              decoration: const InputDecoration(
                labelText: 'Equipo Local',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: equipoVisitanteController,
              decoration: const InputDecoration(
                labelText: 'Equipo Visitante',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flight),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final equipoLocal = equipoLocalController.text.trim();
              final equipoVisitante = equipoVisitanteController.text.trim();

              if (equipoLocal.isNotEmpty && equipoVisitante.isNotEmpty) {
                final appData = Provider.of<AppData>(context, listen: false);
                appData.crearNuevoPartido(equipoLocal, equipoVisitante);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Partido "$equipoLocal vs $equipoVisitante" creado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEliminarPartidoDialog(BuildContext context, Partido partido, AppData appData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Partido'),
        content: Text(
          '¿Estás seguro que deseas eliminar el partido "${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}"?\n\nEsto eliminará todas las situaciones registradas para este partido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              appData.eliminarPartido(partido.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Partido "${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}" eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showLimpiarDatosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Todos los Datos'),
        content: const Text(
          '¿Estás seguro que deseas eliminar TODOS los partidos y datos?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final appData = Provider.of<AppData>(context, listen: false);
              appData.limpiarTodosLosDatos();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todos los datos han sido eliminados'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }
}
