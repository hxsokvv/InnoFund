import 'package:flutter/material.dart';

class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Red de Contactos')),
      body: const Center(
        child: Text('Lista de usuarios o emprendedores'),
      ),
    );
  }
}
