import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart'; // Importa tu archivo de ProfilePage

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  String searchQuery = ""; // Para almacenar la búsqueda del usuario

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (query) {
            setState(() {
              searchQuery = query.trim();
            });
          },
        ),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (searchQuery.isEmpty)
            ? FirebaseFirestore.instance.collection('users').snapshots()
            : FirebaseFirestore.instance
                .collection('users')
                .where('name', isGreaterThanOrEqualTo: searchQuery)
                .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text('No se encontraron usuarios.'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['profilePicture'] != null
                      ? NetworkImage(user['profilePicture'])
                      : null,
                  child: user['profilePicture'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  user['name'] ?? 'Sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user['email'] ?? 'Correo no disponible'),
                onTap: () {
                  // Navegar al perfil del usuario
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userId: users[index].id),
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
