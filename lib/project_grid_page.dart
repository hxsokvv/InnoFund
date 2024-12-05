import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'project_detail_page.dart';

class ProjectGridPage extends StatefulWidget {
  const ProjectGridPage({super.key});

  @override
  _ProjectGridPageState createState() => _ProjectGridPageState();
}

class _ProjectGridPageState extends State<ProjectGridPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            hintText: 'Buscar usuarios o proyectos...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.black),
          onChanged: (query) {
            setState(() {});
          },
        ),
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            _buildUserList(), // Muestra usuarios si hay texto en el buscador
          Expanded(child: _buildProjectGrid()), // Lista de proyectos
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final query = _searchController.text.trim();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(
            child: Text('No se encontraron usuarios.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: users[index].id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProjectGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        var projects = snapshot.data!.docs;

        if (projects.isEmpty) {
          return const Center(
            child: Text('No se encontraron proyectos.'),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            var project = projects[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProjectDetailPage(postId: projects[index].id),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: (project.containsKey('imageUrls') &&
                              project['imageUrls'] != null &&
                              (project['imageUrls'] as List).isNotEmpty)
                          ? Image.network(
                              (project['imageUrls'] as List).first,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  size: 50),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['name'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              project['description'] ?? 'Sin descripción',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
