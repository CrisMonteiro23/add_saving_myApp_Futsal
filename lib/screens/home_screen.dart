// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_futsal/data/app_data.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/screens/estadisticas_screen.dart';
import 'package:mi_app_futsal/screens/partidos_screen.dart'; // ✅ NUEVO import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum AppStep {
  selectPlayers,
  selectType,
  selectSituation,
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Jugador> _selectedPlayers = [];
  AppStep _currentStep = AppStep.selectPlayers;
  bool? _esAFavor;
  String? _selectedTipoLlegada;

  final List<String> _tiposLlegada = [
    'Ataque Posicional',
    'INC Portero',
    'Transicion Corta',
    'Transicion Larga',
    'ABP',
    '5x4',
    '4x5',
    'Dobles-Penales',
  ];

  final TextEditingController _newPlayerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppData>(context, listen: false).loadFromStorage();
    });
  }

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  void _togglePlayerSelection(Jugador jugador) {
    setState(() {
      if (_selectedPlayers.contains(jugador)) {
        _selectedPlayers.remove(jugador);
      } else {
        if (_selectedPlayers.length < 5) {
          _selectedPlayers.add(jugador);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya has seleccionado 5 jugadores.')),
          );
        }
      }
    });
  }

  void _resetForm() {
    setState(() {
      _selectedPlayers.clear();
      _currentStep = AppStep.selectPlayers;
      _esAFavor = null;
      _selectedTipoLlegada = null;
    });
  }

  // Modificación: Función para reiniciar solo los pasos de la situación
  void _resetSituationForm() {
    setState(() {
      _currentStep = AppStep.selectPlayers;
      _esAFavor = null;
      _selectedTipoLlegada = null;
    });
  }


  // Modificación: Cambiar la llamada a _resetForm() por _resetSituationForm()
  void _addSituationAndReset() {
    if (_esAFavor == null || _selectedTipoLlegada == null || _selectedPlayers.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los pasos.')),
      );
      return;
    }

    final appData = Provider.of<AppData>(context, listen: false);

    // ✅ NUEVO: Si no hay partido actual, pedir crear uno
    if (appData.partidoActual == null) {
      _showCrearPartidoRapidoDialog();
      return;
    }

    appData.addSituacion(_esAFavor!, _selectedTipoLlegada!, _selectedPlayers);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Situación registrada con éxito.')),
    );

    // ✅ MODIFICACIÓN: Resetear solo el formulario de la situación, manteniendo los jugadores
    _resetSituationForm();
  }

  // ✅ NUEVO: Diálogo para crear partido rápido
  void _showCrearPartidoRapidoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No hay partido activo'),
        content: const Text(
          'Necesitas crear un partido para registrar situaciones.\n¿Quieres crear uno ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Crear partido con nombres por defecto
              final appData = Provider.of<AppData>(context, listen: false);
              appData.crearNuevoPartido('Mi Equipo', 'Rival');

              // Registrar la situación después de crear el partido
              appData.addSituacion(_esAFavor!, _selectedTipoLlegada!, _selectedPlayers);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partido creado y situación registrada'),
                  backgroundColor: Colors.green,
                ),
              );

              // ✅ MODIFICACIÓN: Resetear solo el formulario de la situación, manteniendo los jugadores
              _resetSituationForm();
            },
            child: const Text('Crear Partido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppData>(
          builder: (context, appData, child) {
            final partidoActual = appData.partidoActual;
            if (partidoActual != null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Analizador de Futsal'),
                  Text(
                    '${partidoActual.equipoLocalNombre} vs ${partidoActual.equipoVisitanteNombre}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }
            return const Text('Analizador de Futsal');
          },
        ),
        actions: [
          // ✅ NUEVO: Botón para gestionar partidos
          IconButton(
            icon: const Icon(Icons.sports_soccer),
            tooltip: 'Gestionar Partidos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PartidosScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Ver Estadísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EstadisticasScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppData>(
        builder: (context, appData, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ✅ NUEVO: Información del partido actual
                if (appData.partidoActual != null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Partido Actual: ${appData.partidoActual!.equipoLocalNombre} vs ${appData.partidoActual!.equipoVisitanteNombre}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Situaciones registradas: ${appData.situacionesRegistradas.length}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ✅ NUEVO: Warning si no hay partido
                if (appData.partidoActual == null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No hay partido activo',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text('Se creará automáticamente al registrar la primera situación'),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PartidosScreen()),
                              );
                            },
                            child: const Text('Crear Partido'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Sección para añadir nuevos jugadores
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Añadir Nuevo Jugador:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newPlayerController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Jugador',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    appData.addJugador(value);
                                    _newPlayerController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Jugador "$value" añadido.')),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (_newPlayerController.text.isNotEmpty) {
                                  appData.addJugador(_newPlayerController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Jugador "${_newPlayerController.text}" añadido.')),
                                  );
                                  _newPlayerController.clear();
                                }
                              },
                              child: const Text('Añadir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Título de la sección actual
                Text(
                  _currentStep == AppStep.selectPlayers
                      ? 'Paso 1: Selecciona los 5 jugadores en cancha (${_selectedPlayers.length}/5)'
                      : _currentStep == AppStep.selectType
                          ? 'Paso 2: ¿Llegada a favor o en contra?'
                          : 'Paso 3: Selecciona el tipo de llegada',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Contenido basado en el paso actual
                // ✅ MODIFICACIÓN: Quitar el Expanded para evitar el scroll en la selección de jugadores
                // Usar un SizedBox para controlar el tamaño si es necesario, pero el Wrap widget es mejor.
                // En este caso, simplemente se elimina el Expanded.
                _currentStep == AppStep.selectPlayers
                    ? _buildPlayerSelectionGrid(appData.jugadores)
                    : _currentStep == AppStep.selectType
                        ? _buildTypeSelectionButtons()
                        : Expanded(child: _buildSituationTypeSelection()),

                const SizedBox(height: 20),

                // Botones de navegación/acción
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ MODIFICACIÓN: Usar Wrap en lugar de GridView para evitar el scroll
  Widget _buildPlayerSelectionGrid(List<Jugador> jugadores) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: jugadores.map((jugador) {
        final isSelected = _selectedPlayers.contains(jugador);
        return GestureDetector(
          onTap: () => _togglePlayerSelection(jugador),
          child: Card(
            color: isSelected ? Colors.blueAccent.shade100 : Colors.grey.shade200,
            elevation: isSelected ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                jugador.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blueAccent.shade700 : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelectionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _esAFavor = true;
              _currentStep = AppStep.selectSituation;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(200, 50),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Llegada a favor'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _esAFavor = false;
              _currentStep = AppStep.selectSituation;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(200, 50),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Llegada en contra'),
        ),
      ],
    );
  }

  Widget _buildSituationTypeSelection() {
    return ListView.builder(
      itemCount: _tiposLlegada.length,
      itemBuilder: (context, index) {
        final tipo = _tiposLlegada[index];
        final isSelected = _selectedTipoLlegada == tipo;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          elevation: isSelected ? 6 : 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(
              tipo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade800 : Colors.black,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedTipoLlegada = tipo;
              });
            },
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (_currentStep == AppStep.selectPlayers) {
      return ElevatedButton(
        onPressed: _selectedPlayers.length == 5
            ? () {
                setState(() {
                  _currentStep = AppStep.selectType;
                });
              }
            : null,
        child: const Text('Siguiente'),
      );
    } else if (_currentStep == AppStep.selectType) {
      return ElevatedButton(
        onPressed: () {
          _resetForm();
        },
        child: const Text('Volver a Selección de Jugadores'),
      );
    } else {
      return Column(
        children: [
          ElevatedButton(
            onPressed: _selectedTipoLlegada != null
                ? _addSituationAndReset
                : null,
            child: const Text('Registrar Situación'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = AppStep.selectType;
                _selectedTipoLlegada = null;
              });
            },
            child: const Text('Volver a Tipo de Llegada'),
          ),
        ],
      );
    }
  }
}
