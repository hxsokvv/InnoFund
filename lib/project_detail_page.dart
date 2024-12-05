import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart';

class ProjectDetailPage extends StatelessWidget {
  final String postId;

  const ProjectDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('projects').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text('Ocurrió un error al cargar los datos.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el proyecto.'));
          }

          // Datos del proyecto
          final project = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Galería de imágenes
                  if (project.containsKey('imageUrls') &&
                      project['imageUrls'] != null &&
                      (project['imageUrls'] as List).isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: (project['imageUrls'] as List).length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              (project['imageUrls'] as List)[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Información del proyecto
                  Text(
                    project['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    project['description'] ?? 'Sin descripción',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monto actual y meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '\$${project['goalAmount'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recaudado:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '\$${project['currentAmount'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (project['goalAmount'] != null &&
                              project['goalAmount'] > 0)
                          ? (project['currentAmount'] / project['goalAmount'])
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                      minHeight: 10,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Likes
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red),
                      const SizedBox(width: 5),
                      Text(
                        '${project['likes']?.length ?? 0} Me gusta',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Información del usuario
                  _buildUserInfo(context, project['userId']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No se encontró información del usuario.');
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;

        return GestureDetector(
          onTap: () {
            // Navegar al perfil del usuario
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: userId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user.containsKey('profilePicture')
                    ? NetworkImage(user['profilePicture'])
                    : null,
                radius: 30,
                child: user.containsKey('profilePicture')
                    ? null
                    : const Icon(Icons.person),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Nombre no disponible',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user['email'] ?? 'Correo no disponible',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
