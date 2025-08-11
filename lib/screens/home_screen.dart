// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_futsal/data/app_data.dart';
import 'package:mi_app_futsal/models/jugador.dart';
import 'package:mi_app_futsal/screens/estadisticas_screen.dart'; // Para navegar a estadísticas

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum AppStep {
  selectPlayers, // Paso 1: Seleccionar jugadores en cancha
  selectType, // Paso 2: Seleccionar si es a favor o en contra
  selectSituation, // Paso 3: Seleccionar el tipo de situación
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de jugadores seleccionados para estar en cancha
  final List<Jugador> _selectedPlayers = [];
  AppStep _currentStep = AppStep.selectPlayers; // Paso actual de la aplicación
  bool? _esAFavor; // True si es a favor, false si es en contra, null si no seleccionado
  String? _selectedTipoLlegada; // El tipo de llegada seleccionado

  // Opciones de tipos de llegada
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

  // Controlador para añadir nuevos jugadores
  final TextEditingController _newPlayerController = TextEditingController();

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  // Función para manejar la selección/deselección de jugadores
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

  // Función para reiniciar el estado del formulario
  void _resetForm() {
    setState(() {
      _selectedPlayers.clear();
      _currentStep = AppStep.selectPlayers;
      _esAFavor = null;
      _selectedTipoLlegada = null;
    });
  }

  // Función para añadir una situación y reiniciar
  void _addSituationAndReset() {
    if (_esAFavor == null || _selectedTipoLlegada == null || _selectedPlayers.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los pasos.')),
      );
      return;
    }

    Provider.of<AppData>(context, listen: false).addSituacion(
      _esAFavor!,
      _selectedTipoLlegada!,
      _selectedPlayers,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Situación registrada con éxito.')),
    );

    _resetForm(); // Reinicia el formulario inmediatamente
  }

  @override
  Widget build(BuildContext context) {
    // Consumer para acceder a la lista de jugadores disponibles
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizador de Futsal'),
        actions: [
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
                Expanded(
                  child: _currentStep == AppStep.selectPlayers
                      ? _buildPlayerSelectionGrid(appData.jugadores)
                      : _currentStep == AppStep.selectType
                          ? _buildTypeSelectionButtons()
                          : _buildSituationTypeSelection(),
                ),

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

  // Widget para la selección de jugadores
  Widget _buildPlayerSelectionGrid(List<Jugador> jugadores) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Aumentado a 4 columnas para hacer los iconos más chicos
        crossAxisSpacing: 8, // Espacio reducido
        mainAxisSpacing: 8, // Espacio reducido
        childAspectRatio: 2.0, // Reducido para hacer las tarjetas más compactas
      ),
      itemCount: jugadores.length,
      itemBuilder: (context, index) {
        final jugador = jugadores[index];
        final isSelected = _selectedPlayers.contains(jugador);
        return GestureDetector(
          onTap: () => _togglePlayerSelection(jugador),
          child: Card(
            color: isSelected ? Colors.blueAccent.shade100 : Colors.grey.shade200,
            elevation: isSelected ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordes ligeramente más pequeños
              side: BorderSide(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                jugador.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // Tamaño de fuente reducido
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blueAccent.shade700 : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget para la selección de tipo (favor/contra)
  Widget _buildTypeSelectionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _esAFavor = true;
              _currentStep = AppStep.selectSituation; // Avanza al siguiente paso
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Botón verde para "a favor"
            minimumSize: const Size(200, 50), // Tamaño mínimo del botón ligeramente reducido
            textStyle: const TextStyle(fontSize: 18), // Tamaño de fuente reducido
          ),
          child: const Text('Llegada a favor'),
        ),
        const SizedBox(height: 20), // Espacio reducido
        ElevatedButton(
          onPressed: () {
            setState(() {
              _esAFavor = false;
              _currentStep = AppStep.selectSituation; // Avanza al siguiente paso
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Botón rojo para "en contra"
            minimumSize: const Size(200, 50), // Tamaño mínimo del botón ligeramente reducido
            textStyle: const TextStyle(fontSize: 18), // Tamaño de fuente reducido
          ),
          child: const Text('Llegada en contra'),
        ),
      ],
    );
  }

  // Widget para la selección del tipo de situación
  Widget _buildSituationTypeSelection() {
    return ListView.builder(
      itemCount: _tiposLlegada.length,
      itemBuilder: (context, index) {
        final tipo = _tiposLlegada[index];
        final isSelected = _selectedTipoLlegada == tipo;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0), // Margen vertical reducido
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          elevation: isSelected ? 6 : 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding reducido
            title: Text(
              tipo,
              style: TextStyle(
                fontSize: 16, // Tamaño de fuente reducido
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

  // Widget para los botones de acción (Siguiente / Registrar)
  Widget _buildActionButtons() {
    if (_currentStep == AppStep.selectPlayers) {
      return ElevatedButton(
        onPressed: _selectedPlayers.length == 5
            ? () {
                setState(() {
                  _currentStep = AppStep.selectType;
                });
              }
            : null, // Deshabilitado si no hay 5 jugadores
        child: const Text('Siguiente'),
      );
    } else if (_currentStep == AppStep.selectType) {
      return ElevatedButton(
        onPressed: () {
          // Si el usuario vuelve atrás desde este paso, puede ir al paso anterior
          _resetForm(); // Forzamos un reset completo si se vuelve desde aquí
        },
        child: const Text('Volver a Selección de Jugadores'),
      );
    } else { // AppStep.selectSituation
      return Column(
        children: [
          ElevatedButton(
            onPressed: _selectedTipoLlegada != null
                ? _addSituationAndReset // Llama a la función que guarda y resetea
                : null, // Deshabilitado si no se ha seleccionado tipo
            child: const Text('Registrar Situación'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = AppStep.selectType; // Volver al paso anterior
                _selectedTipoLlegada = null; // Limpiar selección de tipo de llegada
              });
            },
            child: const Text('Volver a Tipo de Llegada'),
          ),
        ],
      );
    }
  }
}
