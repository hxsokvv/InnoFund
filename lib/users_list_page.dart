import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart'; // Importa la página de chat

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId =
      FirebaseAuth.instance.currentUser!.uid; // Obtén el UID del usuario actual

  // Método para obtener los usuarios registrados
  Future<List<Map<String, dynamic>>> _getUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();

    // Filtrar la lista de usuarios para excluir al usuario actual
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((user) => user['uid'] != currentUserId) // Filtrar por UID
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          // Lista de usuarios
          List<Map<String, dynamic>> users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['name'][0]), // Primera letra del nombre
                ),
                title: Text('${user['name']} ${user['lastName']}'),
                subtitle: Text(user['email']),
                onTap: () {
                  // Lógica para iniciar el chat con este usuario
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                          user: user), // Redirigir a la página del chat
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
