// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Para la gestión de estado
import 'package:mi_app_futsal/data/app_data.dart'; // Tu gestor de datos principal
import 'package:mi_app_futsal/screens/home_screen.dart'; // La pantalla principal para registrar eventos

void main() {
  // runApp es la función principal que inicia tu aplicación Flutter.
  // Usamos ChangeNotifierProvider para que AppData esté disponible
  // en todo el árbol de widgets y notifique los cambios.
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(), // Crea una instancia de tu gestor de datos
      child: const MyApp(), // Tu aplicación principal
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp configura el tema y la navegación de tu aplicación.
    return MaterialApp(
      title: 'Analizador de Futsal', // Nuevo título para reflejar el enfoque
      debugShowCheckedModeBanner: false, // Oculta la etiqueta "DEBUG"
      theme: ThemeData(
        primarySwatch: Colors.blue, // Color principal de la aplicación
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent, // Color de la barra superior
          foregroundColor: Colors.white, // Color del texto en la barra superior
          centerTitle: true, // Centra el título en todas las AppBars
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent, // Color del botón flotante
          foregroundColor: Colors.white, // Color del icono
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Color de fondo de los botones elevados
            foregroundColor: Colors.white, // Color del texto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordes redondeados
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding para botones
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Estilo de texto
          ),
        ),
        // Se eliminó 'const' de CardThemeData porque BorderRadius.circular no es const.
        cardTheme: CardThemeData( // Tema para las tarjetas
          elevation: 4, // Sombra
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
          ),
        ),
        // Colores específicos para botones de "favor" y "contra"
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.green, // Usaremos esto para "favor"
          error: Colors.red, // Usaremos esto para "contra"
        ),
      ),
      home: const HomeScreen(), // La pantalla principal de tu aplicación
    );
  }
}
