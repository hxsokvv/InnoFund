import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex =
      0; // Índice del elemento seleccionado en el BottomNavigationBar

  // Lista de widgets para cada pantalla
  final List<Widget> _pages = [
    const Center(child: Text('Página de Inicio')),
    const Center(child: Text('Página de Proyectos')),
    const Center(child: Text('Página de Crear')),
    const Center(child: Text('Página de Notificaciones')),
    const Center(child: Text('Página de Perfil')),
  ];

  // Método para actualizar el índice seleccionado en el BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Aplicación'),
      ),
      body: _pages[
          _selectedIndex], // Cambia el contenido basado en _selectedIndex
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Mantiene los íconos visibles
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.home), // Icono de Font Awesome
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons
                .th), // Cambia 'grid' por 'th' (ícono de cuadrícula)
            label: 'Proyectos',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.plusSquare), // Icono para Crear
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.bell), // Icono de Notificaciones
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user), // Icono de Perfil
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex, // Índice actual
        selectedItemColor: Colors.blue, // Color del ítem seleccionado
        unselectedItemColor: Colors.grey, // Color de los ítems no seleccionados
        onTap:
            _onItemTapped, // Actualiza el índice cuando se selecciona un ítem
      ),
    );
  }
}
